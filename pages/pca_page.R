library(shiny)
library(plotly)

# =====================================================
# READ TSV / GZ FILE
# =====================================================

read_tsv_auto <- function(path) {

  # Some files have a .gz extension but are actually plain text.
  # Detect whether the file is genuinely gzip-compressed.

  is_gzip <- FALSE

  if (file.exists(path)) {

    con <- file(path, "rb")

    magic <- tryCatch(
      readBin(con, what = "raw", n = 2),
      error = function(e) raw(0)
    )

    close(con)

    if (length(magic) == 2 &&
        identical(magic, as.raw(c(0x1f, 0x8b)))) {
      is_gzip <- TRUE
    }
  }

  if (is_gzip) {

    read.table(
      gzfile(path),
      header = TRUE,
      sep = "\t",
      stringsAsFactors = FALSE,
      check.names = FALSE
    )

  } else {

    read.table(
      path,
      header = TRUE,
      sep = "\t",
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  }
}


# =====================================================
# PARSE ENCODE SINGLE-CELL SAMPLE NAMES
# =====================================================

parse_encode_sc_name <- function(x) {

  x <- basename(as.character(x))

  # Remove .rds
  x <- sub(
    "\\.rds$",
    "",
    x,
    ignore.case = TRUE
  )

  # Remove species prefix
  x <- sub(
    "^level3-Homo_sapiens-",
    "",
    x,
    ignore.case = TRUE
  )

  x <- sub(
    "^level3-Mus_musculus-",
    "",
    x,
    ignore.case = TRUE
  )

  # Tissue = first component after species
  tissue <- sub(
    "-.*$",
    "",
    x
  )

  # Everything after tissue
  remainder <- sub(
    "^[^-]+-",
    "",
    x
  )

  # Remove age suffix
  #
  # Current ENCODE names use suffixes such as:
  # adult_child
  # embryo_postnatal
  #
  celltype <- sub(
    "-(adult_child|embryo_postnatal)$",
    "",
    remainder,
    ignore.case = TRUE
  )

  # Convert underscores to spaces
  tissue <- gsub(
    "_",
    " ",
    tissue
  )

  celltype <- gsub(
    "_",
    " ",
    celltype
  )

  # Make labels readable
  tissue <- tools::toTitleCase(tissue)
  celltype <- tools::toTitleCase(celltype)

  data.frame(
    tissue = tissue,
    celltype = celltype,
    stringsAsFactors = FALSE
  )
}


# =====================================================
# ENCODE BULK TISSUE MAPPING
# =====================================================

get_encode_bulk_tissue <- function(x) {

  x <- tolower(
    trimws(
      as.character(x)
    )
  )

  group <- rep(
    NA_character_,
    length(x)
  )

  # ---------------------------------------------------
  # 19 EXISTING ENCODE BULK TISSUES
  # ---------------------------------------------------

  group[
    grepl(
      "adipose",
      x
    )
  ] <- "Adipose Tissue"

  group[
    grepl(
      "adrenal_gland|adrenal gland",
      x
    )
  ] <- "Adrenal Gland"

  group[
    grepl(
      "aorta",
      x
    )
  ] <- "Aorta"

  group[
    grepl(
      "large_intestine|large intestine|sigmoid_colon|sigmoid colon|transverse_colon|transverse colon|colon",
      x
    )
  ] <- "Colon"

  group[
    grepl(
      "esophagus",
      x
    )
  ] <- "Esophagus"

  group[
    grepl(
      "heart",
      x
    )
  ] <- "Heart"

  group[
    grepl(
      "liver",
      x
    )
  ] <- "Liver"

  group[
    grepl(
      "lung",
      x
    )
  ] <- "Lung"

  group[
    grepl(
      "motor_neuron|motor neuron",
      x
    )
  ] <- "Motor Neuron"

  group[
    grepl(
      "muscle",
      x
    )
  ] <- "Muscle"

  group[
    grepl(
      "ovary",
      x
    )
  ] <- "Ovary"

  group[
    grepl(
      "pancreas",
      x
    )
  ] <- "Pancreas"

  group[
    grepl(
      "skin",
      x
    )
  ] <- "Skin"

  group[
    grepl(
      "small_intestine|small intestine",
      x
    )
  ] <- "Small Intestine"

  group[
    grepl(
      "spleen",
      x
    )
  ] <- "Spleen"

  group[
    grepl(
      "stomach",
      x
    )
  ] <- "Stomach"

  group[
    grepl(
      "testis",
      x
    )
  ] <- "Testis"

  group[
    grepl(
      "thyroid_gland|thyroid gland",
      x
    )
  ] <- "Thyroid Gland"

  group[
    grepl(
      "tibial_nerve|tibial nerve",
      x
    )
  ] <- "Tibial Nerve"

  group
}


# =====================================================
# NORMALIZE PCA DATA
# =====================================================

normalise_pca_df <- function(obj) {

  if (inherits(obj, "prcomp")) {

    df <- as.data.frame(
      obj$x[, 1:2, drop = FALSE]
    )

    colnames(df)[1:2] <- c(
      "PC1",
      "PC2"
    )

    df$group <- "Sample"
    df$name <- rownames(df)
    df$celltype <- NA_character_

    pve <- (
      obj$sdev^2
    ) / sum(obj$sdev^2)

    attr(df, "pve") <- pve[1:2] * 100

    return(df)
  }

  df <- as.data.frame(obj)

  # ---------------------------------------------------
  # PCA columns
  # ---------------------------------------------------

  pc_cols <- grep(
    "^PC",
    colnames(df)
  )

  orig_pc <- colnames(df)[pc_cols][1:2]

  colnames(df)[pc_cols[1:2]] <- c(
    "PC1",
    "PC2"
  )

  pve <- suppressWarnings(
    as.numeric(
      sub(
        "^PC[0-9]+_?",
        "",
        orig_pc
      )
    )
  )

  if (any(is.na(pve))) {

    pve_attr <- attr(
      obj,
      "pve"
    )

    pve <- if (!is.null(pve_attr)) {
      pve_attr[1:2] * 100
    } else {
      NULL
    }
  }

  attr(df, "pve") <- pve

  # ---------------------------------------------------
  # Name
  # ---------------------------------------------------

  name_candidates <- c(
    "name",
    "rownames"
  )

  ncol_name <- intersect(
    name_candidates,
    colnames(df)
  )[1]

  df$name <- if (
    !is.na(ncol_name)
  ) {

    as.character(
      df[[ncol_name]]
    )

  } else {

    rownames(df)
  }

  # ---------------------------------------------------
  # Existing group
  # ---------------------------------------------------

  group_candidates <- c(
    "generaltissue",
    "group",
    "type",
    "ct",
    "celltype",
    "label",
    "database",
    "db"
  )

  gcol <- intersect(
    group_candidates,
    colnames(df)
  )[1]

  df$group <- if (
    !is.na(gcol)
  ) {

    as.character(
      df[[gcol]]
    )

  } else {

    "Sample"
  }

  if (!"celltype" %in% colnames(df)) {
    df$celltype <- NA_character_
  }

  df
}


# =====================================================
# CLEAN NON-SINGLE-CELL LABELS
# =====================================================

clean_labels <- function(
    df,
    path,
    entry_group = NULL
) {

  # ---------------------------------------------------
  # ENCODE SINGLE CELL
  #
  # IMPORTANT:
  # group = CELL TYPE
  # tissue = TISSUE
  # ---------------------------------------------------

  if (
    grepl(
      "encode_sc",
      path,
      ignore.case = TRUE
    )
  ) {

    parsed <- parse_encode_sc_name(
      df$name
    )

    df$tissue <- parsed$tissue
    df$celltype <- parsed$celltype

    # PCA / UMAP legend should be CELL TYPE
    df$group <- df$celltype

    if (!is.null(entry_group)) {

      entry_group <- gsub(
        "_",
        " ",
        entry_group
      )

      entry_group <- tools::toTitleCase(
        entry_group
      )
    }

  # ---------------------------------------------------
  # ENCODE BULK
  #
  # group = TISSUE
  # ---------------------------------------------------

  } else if (
    grepl(
      "encode_bulk",
      path,
      ignore.case = TRUE
    )
  ) {

    df$group <- get_encode_bulk_tissue(
      df$name
    )

    if (!is.null(entry_group)) {

      entry_group <- gsub(
        "_",
        " ",
        entry_group
      )

      entry_group <- tools::toTitleCase(
        entry_group
      )
    }

  # ---------------------------------------------------
  # OTHER DATASETS
  # ---------------------------------------------------

  } else {

    df$group <- gsub(
      "^Homo sapiens ",
      "",
      df$group,
      ignore.case = TRUE
    )

    df$group <- gsub(
      "^Mus musculus ",
      "",
      df$group,
      ignore.case = TRUE
    )

    df$group <- gsub(
      " tissue",
      "",
      df$group,
      ignore.case = TRUE
    )

    df$group <- gsub(
      " male adult \\(.*?\\)",
      "",
      df$group
    )

    df$group <- gsub(
      " female adult \\(.*?\\)",
      "",
      df$group
    )

    df$group <- gsub(
      " male child \\(.*?\\)",
      "",
      df$group
    )

    df$group <- gsub(
      " female child \\(.*?\\)",
      "",
      df$group
    )

    df$group <- gsub(
      " originated from ",
      " ",
      df$group,
      ignore.case = TRUE
    )

    df$group <- gsub(
      "_",
      " ",
      df$group
    )

    df$group <- gsub(
      "^B Cell$",
      "Peripheral Blood",
      df$group,
      ignore.case = TRUE
    )

    df$group <- gsub(
      "^Cd14-Positive Monocyte$",
      "Peripheral Blood",
      df$group,
      ignore.case = TRUE
    )

    df$group <- gsub(
      "^T-Cell$",
      "Peripheral Blood",
      df$group,
      ignore.case = TRUE
    )

    df$group <- gsub(
      "^Natural Killer Cell$",
      "Peripheral Blood",
      df$group,
      ignore.case = TRUE
    )

    df$group <- trimws(
      df$group
    )

    df$group <- tools::toTitleCase(
      df$group
    )

    if (!is.null(entry_group)) {

      entry_group <- gsub(
        "_",
        " ",
        entry_group
      )

      entry_group <- tools::toTitleCase(
        entry_group
      )
    }
  }

  list(
    df = df,
    entry_group = entry_group
  )
}


# =====================================================
# MATCH SELECTED TISSUE
# =====================================================

match_entry <- function(
    df_tissue,
    entry_tissue
) {

  if (
    is.null(entry_tissue) ||
    is.na(entry_tissue) ||
    entry_tissue == ""
  ) {
    return(
      rep(FALSE, length(df_tissue))
    )
  }

  clean_df <- gsub(
    "[^a-z]",
    "",
    tolower(df_tissue)
  )

  clean_entry <- gsub(
    "[^a-z]",
    "",
    tolower(entry_tissue)
  )

  clean_df == clean_entry |
    startsWith(
      clean_df,
      clean_entry
    )
}


# =====================================================
# RESOLVE ENCODE SC PREDICTED PCA
# =====================================================

resolve_pca_path <- function(path) {

  # The labeled predicted PCA contains only:
  # PC1, PC2, group
  #
  # The companion predicted PCA contains:
  # name, PC1, PC2
  #
  # We need the name so that cell type and tissue
  # can be parsed.

  if (
    grepl(
      "encode_sc_predicted_labeled\\.tsv\\.gz$",
      path,
      ignore.case = TRUE
    )
  ) {

    candidate <- sub(
      "encode_sc_predicted_labeled\\.tsv\\.gz$",
      "encode_sc_predicted_pca.tsv.gz",
      path,
      ignore.case = TRUE
    )

    if (file.exists(candidate)) {
      return(candidate)
    }
  }

  path
}


# =====================================================
# BUILD PCA
# =====================================================

build_type_pca <- function(
    path,
    entry_group = NULL,
    title = "PCA"
) {

  req(path)

  # Use coordinate file for ENCODE SC predicted PCA
  actual_path <- resolve_pca_path(
    path
  )

  df <- read_tsv_auto(
    actual_path
  )

  df <- normalise_pca_df(
    df
  )

  # ---------------------------------------------------
  # Clean labels
  # ---------------------------------------------------

  cleaned <- clean_labels(
    df,
    actual_path,
    entry_group
  )

  df <- cleaned$df
  entry_group <- cleaned$entry_group

  pve <- attr(
    df,
    "pve"
  )

  # ---------------------------------------------------
  # Hover text
  # ---------------------------------------------------

  if (
    grepl(
      "encode_sc",
      actual_path,
      ignore.case = TRUE
    )
  ) {

    df$hover_text <- paste0(
      "<b>",
      df$name,
      "</b>",
      "<br>Tissue: ",
      df$tissue,
      "<br>Cell type: ",
      df$celltype
    )

  } else {

    df$hover_text <- paste0(
      "<b>",
      df$name,
      "</b>",
      "<br>Group: ",
      df$group
    )
  }

  # ---------------------------------------------------
  # Axis labels
  # ---------------------------------------------------

  x_lab <- if (!is.null(pve)) {

    paste0(
      "PC1 (",
      round(pve[1], 1),
      "%)"
    )

  } else {

    "PC1"
  }

  y_lab <- if (!is.null(pve)) {

    paste0(
      "PC2 (",
      round(pve[2], 1),
      "%)"
    )

  } else {

    "PC2"
  }

  # ---------------------------------------------------
  # Main plot
  # ---------------------------------------------------

  p <- plot_ly(
    data = df,
    x = ~PC1,
    y = ~PC2,
    type = "scatter",
    mode = "markers",
    color = ~group,
    text = ~hover_text,
    hoverinfo = "text",
    marker = list(
      size = 7,
      opacity = 0.55
    )
  )

  # ---------------------------------------------------
  # Highlight selected tissue
  # ---------------------------------------------------

  if (
    !is.null(entry_group) &&
    grepl(
      "encode_sc",
      actual_path,
      ignore.case = TRUE
    )
  ) {

    hl <- df[
      match_entry(
        df$tissue,
        entry_group
      ),
      ,
      drop = FALSE
    ]

  } else {

    hl <- df[
      match_entry(
        df$group,
        entry_group
      ),
      ,
      drop = FALSE
    ]
  }

  if (nrow(hl) > 0) {

    p <- p %>%

      add_trace(
        data = hl,

        x = ~PC1,
        y = ~PC2,

        type = "scatter",
        mode = "markers",

        marker = list(
          symbol = "diamond",
          size = 11,
          color = "#F59E0B",
          line = list(
            color = "black",
            width = 2
          )
        ),

        name = paste0(
          entry_group,
          " (selected)"
        ),

        inherit = FALSE,

        hoverinfo = "text",
        text = ~hover_text
      )
  }

  # ---------------------------------------------------
  # Layout
  # ---------------------------------------------------

  p %>%

    layout(
      title = title,

      legend = list(
        title = list(
          text = if (
            grepl(
              "encode_sc",
              actual_path,
              ignore.case = TRUE
            )
          ) {
            "Cell Type"
          } else if (
            grepl(
              "encode_bulk",
              actual_path,
              ignore.case = TRUE
            )
          ) {
            "Tissue"
          } else {
            "Group"
          }
        )
      ),

      xaxis = list(
        title = x_lab
      ),

      yaxis = list(
        title = y_lab
      )
    )
}


# =====================================================
# BUILD UMAP
# =====================================================

build_type_umap <- function(
    path,
    entry_group = NULL,
    title = "UMAP"
) {

  req(path)

  df <- read_tsv_auto(
    path
  )

  # ---------------------------------------------------
  # Make sure name exists
  # ---------------------------------------------------

  if (!"name" %in% colnames(df)) {

    df$name <- rownames(df)
  }

  # ---------------------------------------------------
  # ENCODE SINGLE CELL
  #
  # Derive:
  #   tissue
  #   celltype
  #
  # from sample name.
  # ---------------------------------------------------

  if (
    grepl(
      "encode_sc",
      path,
      ignore.case = TRUE
    )
  ) {

    parsed <- parse_encode_sc_name(
      df$name
    )

    df$tissue <- parsed$tissue
    df$celltype <- parsed$celltype

    # Color by CELL TYPE
    df$group <- df$celltype

  # ---------------------------------------------------
  # ENCODE BULK
  #
  # Color by TISSUE using sample name.
  # ---------------------------------------------------

  } else if (
    grepl(
      "encode_bulk",
      path,
      ignore.case = TRUE
    )
  ) {

    df$group <- get_encode_bulk_tissue(
      df$name
    )

  # ---------------------------------------------------
  # OTHER DATASETS
  # ---------------------------------------------------

  } else {

    if (
      "generaltissue" %in%
      colnames(df)
    ) {

      df$group <- df$generaltissue

    } else if (
      "celltype" %in%
      colnames(df)
    ) {

      df$group <- df$celltype

    } else if (
      "label" %in%
      colnames(df)
    ) {

      df$group <- df$label

    } else if (
      "group" %in%
      colnames(df)
    ) {

      df$group <- df$group

    } else {

      df$group <- df$name
    }
  }

  # ---------------------------------------------------
  # Clean labels
  # ---------------------------------------------------

  cleaned <- clean_labels(
    df,
    path,
    entry_group
  )

  df <- cleaned$df
  entry_group <- cleaned$entry_group

  # ---------------------------------------------------
  # Hover text
  # ---------------------------------------------------

  if (
    grepl(
      "encode_sc",
      path,
      ignore.case = TRUE
    )
  ) {

    df$hover_text <- paste0(
      "<b>",
      df$name,
      "</b>",
      "<br>Tissue: ",
      df$tissue,
      "<br>Cell type: ",
      df$celltype
    )

  } else {

    df$hover_text <- paste0(
      "<b>",
      df$name,
      "</b>",
      "<br>Group: ",
      df$group
    )
  }

  # ---------------------------------------------------
  # Main plot
  # ---------------------------------------------------

  p <- plot_ly(
    data = df,
    x = ~UMAP1,
    y = ~UMAP2,
    type = "scatter",
    mode = "markers",
    color = ~group,
    text = ~hover_text,
    hoverinfo = "text",
    marker = list(
      size = 7,
      opacity = 0.55
    )
  )

  # ---------------------------------------------------
  # Highlight selected tissue
  # ---------------------------------------------------

  if (
    !is.null(entry_group) &&
    grepl(
      "encode_sc",
      path,
      ignore.case = TRUE
    )
  ) {

    hl <- df[
      match_entry(
        df$tissue,
        entry_group
      ),
      ,
      drop = FALSE
    ]

  } else {

    hl <- df[
      match_entry(
        df$group,
        entry_group
      ),
      ,
      drop = FALSE
    ]
  }

  if (nrow(hl) > 0) {

    p <- p %>%

      add_trace(
        data = hl,

        x = ~UMAP1,
        y = ~UMAP2,

        type = "scatter",
        mode = "markers",

        marker = list(
          symbol = "diamond",
          size = 11,
          color = "#F59E0B",
          line = list(
            color = "black",
            width = 2
          )
        ),

        name = paste0(
          entry_group,
          " (selected)"
        ),

        inherit = FALSE,

        hoverinfo = "text",
        text = ~hover_text
      )
  }

  # ---------------------------------------------------
  # Layout
  # ---------------------------------------------------

  p %>%

    layout(
      title = title,

      legend = list(
        title = list(
          text = if (
            grepl(
              "encode_sc",
              path,
              ignore.case = TRUE
            )
          ) {
            "Cell Type"
          } else if (
            grepl(
              "encode_bulk",
              path,
              ignore.case = TRUE
            )
          ) {
            "Tissue"
          } else {
            "Group"
          }
        )
      ),

      xaxis = list(
        title = "UMAP1"
      ),

      yaxis = list(
        title = "UMAP2"
      )
    )
}


# =====================================================
# BUILD VARIANCE
# =====================================================

build_variance <- function(
    path,
    title = "Variance Explained"
) {

  df <- read_tsv_auto(
    path
  )

  df <- normalise_pca_df(
    df
  )

  pve <- attr(
    df,
    "pve"
  )

  if (is.null(pve)) {
    return(NULL)
  }

  plot_df <- data.frame(
    PC = seq_along(pve),
    Variance = pve
  )

  plot_ly(
    data = plot_df,

    x = ~PC,
    y = ~Variance,

    type = "scatter",
    mode = "lines+markers"
  ) %>%

    layout(
      title = title,

      xaxis = list(
        title = "Principal Component"
      ),

      yaxis = list(
        title = "Variance Explained (%)"
      )
    )
}