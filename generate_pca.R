# =====================================================
# GENERATE PER-DATASET, SINGLE-TYPE PCA COORDINATE FILES
# =====================================================
#
# For each dataset we build up to three INDEPENDENT PCAs, one per data type:
#
#   predicted  -> model-predicted DNA methylation
#   gold       -> measured (gold-standard) DNA methylation
#   input      -> RNA-seq expression fed to the model
#
# Each PCA is computed dataset-wide (across all that dataset's tissues /
# pseudobulk samples) on its OWN matrix. The Shiny app (pages/entry_page.R)
# shows one tab per type and highlights the current entry's tissue/group.
#
# This script reads the large source matrices from the HPC `predDNAmDB`
# tree and writes SMALL coordinate data frames into pca_gen/out/. Run it
# where BASE_DIR is reachable (i.e. on the HPC), then point the Shiny app
# metadata to these output files or copy them into the app repo.
#
# Output per job: pca_gen/out/<dataset>/<type>_pca.rds
#   a data.frame with columns PC1..PCn, group, name (+ celltype where known)
#   and attr(df, "pve") = proportion of variance explained per PC.
#
# Modeled on split_gtex.R.
# =====================================================

# =====================================================
# CONFIG  (edit these)
# =====================================================

BASE_DIR <- "/insomnia001/depts/msph/users/jz4027/predDNAmDB"  # HPC source root
OUT_DIR  <- "pca_gen/out"                                       # HPC PCA output root
N_TOP    <- 5000   # keep the top-N most variable features before PCA
N_PCS    <- 10     # number of principal components to retain

# =====================================================
# GENERIC HELPERS
# =====================================================

# Choose the first available source path for a job.
resolve_source <- function(paths) {

  full_paths <- file.path(BASE_DIR, paths)
  found <- full_paths[file.exists(full_paths)]

  if (length(found) == 0) {
    return(NULL)
  }

  found[1]
}

# Fast delimited reader: prefer data.table::fread, fall back to base R.
# Supports .csv, .csv.gz, .tsv, and .tsv.gz.
read_table_matrix <- function(path) {

  if (requireNamespace("data.table", quietly = TRUE)) {

    dt <- data.table::fread(
      path,
      header     = TRUE,
      check.names = FALSE,
      data.table  = TRUE
    )

    rn  <- dt[[1]]
    dt  <- dt[, -1, with = FALSE]

    mat <- as.matrix(dt)
    rownames(mat) <- rn

    return(mat)
  }

  is_tsv <- grepl("\\.tsv(\\.gz)?$", path, ignore.case = TRUE)
  con <- if (grepl("\\.gz$", path, ignore.case = TRUE)) gzfile(path) else path

  df <- read.table(
    con,
    header      = TRUE,
    sep         = if (is_tsv) "\t" else ",",
    row.names   = 1,
    check.names = FALSE,
    quote       = "",
    comment.char = ""
  )

  as.matrix(df)
}

# RDS matrix / data.frame reader -> numeric matrix (features x samples)
read_rds_matrix <- function(path) {

  obj <- readRDS(path)

  if (is.data.frame(obj)) {
    obj <- as.matrix(obj)
  }

  obj
}

# Indices of the top-k highest-variance rows (features), computed in a
# memory-friendly way without matrixStats:  var = (Sx2 - Sx^2/n) / (n-1)
top_var_rows <- function(mat, k) {

  n   <- ncol(mat)

  if (n < 2) {
    # variance undefined across <2 samples: keep all rows
    return(seq_len(nrow(mat)))
  }

  sx  <- rowSums(mat, na.rm = TRUE)
  sx2 <- rowSums(mat * mat, na.rm = TRUE)

  v   <- (sx2 - (sx * sx) / n) / (n - 1)
  v[!is.finite(v)] <- 0

  k <- min(k, nrow(mat))

  order(v, decreasing = TRUE)[seq_len(k)]
}

# Core PCA: mat is features x samples; returns coordinate data.frame.
run_pca <- function(mat, group, names, n_pcs = N_PCS) {

  storage.mode(mat) <- "double"

  # drop zero-variance / all-NA features defensively
  keep_rows <- top_var_rows(mat, N_TOP)
  sub       <- mat[keep_rows, , drop = FALSE]

  # PCA over samples -> transpose so samples are rows
  pc <- prcomp(
    t(sub),
    center = TRUE,
    scale. = FALSE
  )

  n_keep <- min(n_pcs, ncol(pc$x))

  scores <- as.data.frame(
    pc$x[, seq_len(n_keep), drop = FALSE]
  )

  colnames(scores) <- paste0("PC", seq_len(n_keep))

  scores$group <- group
  scores$name  <- names

  # proportion of variance explained
  pve <- (pc$sdev^2) / sum(pc$sdev^2)
  attr(scores, "pve") <- pve

  scores
}

safe_name <- function(x) {
  x <- tolower(x)
  x <- gsub(" ", "_", x)
  x <- gsub("-", "_", x)
  x
}

save_pca <- function(df, dataset, type) {

  out_dir <- file.path(OUT_DIR, dataset)

  dir.create(
    out_dir,
    recursive    = TRUE,
    showWarnings = FALSE
  )

  out_file <- file.path(
    out_dir,
    paste0(type, "_pca.rds")
  )

  saveRDS(df, out_file)

  cat(
    "  saved:", out_file,
    "| samples:", nrow(df),
    "| PCs:", sum(grepl("^PC", colnames(df))),
    "| PC1 var:", round(attr(df, "pve")[1] * 100, 1), "%\n"
  )
}

# =====================================================
# GROUP EXTRACTORS  (map sample/column names -> a biological group label)
# =====================================================

# GTEx predicted: columns are tissue names (e.g. "Lung", "Brain")
group_gtex <- function(samples) {
  list(group = samples, extra = NULL)
}

# ENCODE bulk: join full sample names against the sample->tissue map
group_encode_bulk <- function(samples) {

  map_path <- file.path(
    BASE_DIR,
    "metadata/encode_bulk_sample_tissue_map.csv"
  )

  map <- read.csv(map_path, stringsAsFactors = FALSE, check.names = FALSE)

  tissue <- map$tissue[match(samples, map$sample)]
  tissue[is.na(tissue)] <- "unknown"

  list(group = tissue, extra = NULL)
}

# ENCODE sc predicted: column names look like
#   level3-Homo_sapiens-<tissue>-<celltype>-<age>
# tissue = field 3, celltype = field 4 (underscores -> spaces).
group_encode_sc <- function(samples) {

  parts <- strsplit(samples, "-", fixed = TRUE)

  field <- function(p, i) {
    if (length(p) >= i) gsub("_", " ", p[[i]]) else NA_character_
  }

  generaltissue <- vapply(parts, field, character(1), i = 3)
  celltype      <- vapply(parts, field, character(1), i = 4)

  list(
    group = generaltissue,
    extra = data.frame(celltype = celltype, stringsAsFactors = FALSE)
  )
}

# TCGA/TARGET: use project.csv when available to map sample IDs to cohorts.
group_tcga <- function(samples) {

  project_path <- file.path(
    BASE_DIR,
    "input/tcga_2024/full/project.csv"
  )

  if (file.exists(project_path)) {
    project <- read.csv(project_path, stringsAsFactors = FALSE, check.names = FALSE)
    names(project) <- tolower(names(project))

    sample_col <- intersect(
      c("sample", "sample_id", "sampleid", "barcode", "case", "case_id"),
      names(project)
    )[1]
    project_col <- intersect(
      c("project", "project_id", "cohort", "cancer", "cancer_type"),
      names(project)
    )[1]

    if (!is.na(sample_col) && !is.na(project_col)) {
      cohort <- project[[project_col]][match(samples, project[[sample_col]])]
      cohort[is.na(cohort) | cohort == ""] <- "unknown"
      return(list(group = cohort, extra = NULL))
    }

    if (ncol(project) >= 2) {
      cohort <- project[[2]][match(samples, project[[1]])]
      cohort[is.na(cohort) | cohort == ""] <- "unknown"
      return(list(group = cohort, extra = NULL))
    }
  }

  cohort <- ifelse(
    grepl("^TCGA-", samples),
    sub("^((TCGA-[^-]+)).*", "\\1", samples),
    ifelse(
      grepl("^TARGET-", samples),
      sub("^((TARGET-[^-]+)).*", "\\1", samples),
      "unknown"
    )
  )

  list(group = cohort, extra = NULL)
}

# =====================================================
# JOB DEFINITIONS
# =====================================================
# Each job: dataset, type, source path (relative to BASE_DIR),
# a reader function, and a group extractor.

jobs <- list(

  list(
    dataset = "gtex",
    type    = "predicted",
    source  = c(
      "predicted/gtex/full/gtex_ramp.tsv.gz",
      "predicted/gtex/full/gtex_ramp.rds"
    ),
    reader  = NULL,
    grouper = group_gtex
  ),

  list(
    dataset = "encode_sc",
    type    = "predicted",
    source  = c(
      "predicted/encode_sc/full/level3_human.tsv.gz",
      "predicted/encode_sc/full/level3_human.rds"
    ),
    reader  = NULL,
    grouper = group_encode_sc
  ),

  list(
    dataset = "tcga",
    type    = "predicted",
    source  = c(
      "predicted/tcga_2024/full/predicted_450k.tsv.gz"
    ),
    reader  = read_table_matrix,
    grouper = group_tcga
  ),

  list(
    dataset = "tcga",
    type    = "gold",
    source  = c(
      "goldstandard/tcga_2024/full/450k.tsv.gz",
      "goldstandard/tcga_2024/full/450k.csv"
    ),
    reader  = read_table_matrix,
    grouper = group_tcga
  ),

  list(
    dataset = "tcga",
    type    = "input",
    source  = c(
      "input/tcga_2024/full/ge_for_450k.tsv.gz",
      "input/tcga_2024/full/ge_for_450k.csv"
    ),
    reader  = read_table_matrix,
    grouper = group_tcga
  ),

  list(
    dataset = "encode_bulk",
    type    = "gold",
    source  = c(
      "goldstandard/encode_bulk/full/me_rownamesloc.tsv.gz",
      "goldstandard/encode_bulk/full/me_rownamesloc.csv.gz",
      "goldstandard/encode_bulk/full/me_rownamesloc.csv"
    ),
    reader  = read_table_matrix,
    grouper = group_encode_bulk
  ),

  list(
    dataset = "encode_bulk",
    type    = "input",
    source  = c(
      "input/encode_bulk/full/ge.tsv.gz",
      "input/encode_bulk/full/ge.csv"
    ),
    reader  = read_table_matrix,
    grouper = group_encode_bulk
  )

  # No full source was listed for these combinations in the new HPC map:
  #   encode_bulk / predicted
  #   encode_sc   / input, gold
  #   gtex        / input, gold
)

for (i in seq_along(jobs)) {
  src <- resolve_source(jobs[[i]]$source)
  jobs[[i]]$resolved_source <- src

  if (!is.null(src) && is.null(jobs[[i]]$reader)) {
    jobs[[i]]$reader <- if (grepl("\\.rds$", src, ignore.case = TRUE)) {
      read_rds_matrix
    } else {
      read_table_matrix
    }
  }
}

# =====================================================
# RUN JOBS
# =====================================================

for (job in jobs) {

  cat("\n=====================================\n")
  cat("JOB:", job$dataset, "/", job$type, "\n")
  cat("=====================================\n")

  src <- job$resolved_source

  if (is.null(src) || !file.exists(src)) {
    cat(
      "  SKIP (source not found):",
      paste(file.path(BASE_DIR, job$source), collapse = " | "),
      "\n"
    )
    next
  }

  cat("  reading:", src, "\n")
  mat <- job$reader(src)

  cat("  matrix:", nrow(mat), "features x", ncol(mat), "samples\n")

  samples <- colnames(mat)

  g <- job$grouper(samples)

  df <- run_pca(
    mat,
    group = g$group,
    names = samples
  )

  # attach any extra metadata columns (e.g. celltype) preserving pve attr
  if (!is.null(g$extra)) {
    pve <- attr(df, "pve")
    df  <- cbind(df, g$extra)
    attr(df, "pve") <- pve
  }

  save_pca(df, job$dataset, job$type)

  rm(mat)
  gc()
}

cat("\n=====================================\n")
cat("PCA GENERATION COMPLETE\n")
cat("=====================================\n")
