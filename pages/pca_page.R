library(shiny)
library(plotly)

# =====================================================
# PCA RENDER HELPERS
# =====================================================

normalise_pca_df <- function(obj) {

  if (inherits(obj, "prcomp")) {

    df <- as.data.frame(obj$x[, 1:2, drop = FALSE])
    colnames(df)[1:2] <- c("PC1", "PC2")

    df$group <- "Sample"
    df$name <- rownames(df)
    df$celltype <- NA_character_

    pve <- (obj$sdev^2) / sum(obj$sdev^2)
    attr(df, "pve") <- pve[1:2] * 100

    return(df)
  }

  df <- as.data.frame(obj)

  pc_cols <- grep("^PC", colnames(df))
  orig_pc <- colnames(df)[pc_cols][1:2]

  colnames(df)[pc_cols[1:2]] <- c("PC1", "PC2")

  pve <- suppressWarnings(
    as.numeric(sub("^PC[0-9]+_?", "", orig_pc))
  )

  if (any(is.na(pve))) {
    pve_attr <- attr(obj, "pve")
    pve <- if (!is.null(pve_attr)) pve_attr[1:2] * 100 else NULL
  }

  attr(df, "pve") <- pve

  group_candidates <- c(
    "group", "type", "ct", "generaltissue",
    "celltype", "label", "database", "db"
  )

  gcol <- intersect(group_candidates, colnames(df))[1]

  df$group <- if (!is.na(gcol)) {
    as.character(df[[gcol]])
  } else {
    "Sample"
  }

  name_candidates <- c("name", "label", "rownames")
  ncol_name <- intersect(name_candidates, colnames(df))[1]

  df$name <- if (!is.na(ncol_name)) {
    as.character(df[[ncol_name]])
  } else {
    rownames(df)
  }

  if (!"celltype" %in% colnames(df)) {
    df$celltype <- NA_character_
  }

  df
}

# =====================================================
# BUILD PCA
# =====================================================

build_type_pca <- function(
  path,
  entry_group = NULL,
  title = "PCA"
) {

  df <- read.table(
    gzfile(path),
    header = TRUE,
    sep = "\t",
    stringsAsFactors = FALSE
  )

  df <- normalise_pca_df(df)

  pve <- attr(df, "pve")

  if (grepl("encode", path, ignore.case = TRUE)) {

    df$group <- gsub("^Homo sapiens ", "", df$group, ignore.case = TRUE)
    df$group <- gsub(" tissue", "", df$group, ignore.case = TRUE)
    df$group <- gsub(" male adult \\(.*?\\)", "", df$group)
    df$group <- gsub(" female adult \\(.*?\\)", "", df$group)
    df$group <- gsub(" male child \\(.*?\\)", "", df$group)
    df$group <- gsub(" female child \\(.*?\\)", "", df$group)

    df$group <- gsub("_", " ", df$group)
    df$group <- trimws(df$group)
    df$group <- tools::toTitleCase(df$group)

    if (!is.null(entry_group)) {
      entry_group <- gsub("^Homo sapiens ", "", entry_group, ignore.case = TRUE)
      entry_group <- gsub(" tissue", "", entry_group, ignore.case = TRUE)
      entry_group <- gsub("_", " ", entry_group)
      entry_group <- trimws(entry_group)
      entry_group <- tools::toTitleCase(entry_group)
    }
  }

  df$hover_text <- paste0(
    "<b>", df$name, "</b>",
    "<br>Group: ", df$group,
    ifelse(
      is.na(df$celltype),
      "",
      paste0("<br>Cell type: ", df$celltype)
    )
  )

  x_lab <- if (!is.null(pve)) {
    paste0("PC1 (", round(pve[1], 1), "%)")
  } else {
    "PC1"
  }

  y_lab <- if (!is.null(pve)) {
    paste0("PC2 (", round(pve[2], 1), "%)")
  } else {
    "PC2"
  }

  p <- plot_ly(
    data = df,
    x = ~PC1,
    y = ~PC2,
    type = "scatter",
    mode = "markers",
    color = ~group,
    text = ~hover_text,
    hoverinfo = "text",
    marker = list(size = 7, opacity = 0.55)
  )

  p %>%
    layout(
      title = title,
      legend = list(title = list(text = "Group")),
      xaxis = list(title = x_lab),
      yaxis = list(title = y_lab)
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

  df <- read.table(
    gzfile(path),
    header = TRUE,
    sep = "\t",
    stringsAsFactors = FALSE
  )

  if (!"group" %in% colnames(df)) df$group <- "Sample"
  if (!"name" %in% colnames(df)) df$name <- rownames(df)
  if (!"celltype" %in% colnames(df)) df$celltype <- NA_character_

  df$hover_text <- paste0(
    "<b>", df$name, "</b>",
    "<br>Group: ", df$group,
    ifelse(
      is.na(df$celltype),
      "",
      paste0("<br>Cell type: ", df$celltype)
    )
  )

  plot_ly(
    data = df,
    x = ~UMAP1,
    y = ~UMAP2,
    type = "scatter",
    mode = "markers",
    color = ~group,
    text = ~hover_text,
    hoverinfo = "text",
    marker = list(size = 7, opacity = 0.55)
  ) %>%
    layout(
      title = title,
      legend = list(title = list(text = "Group")),
      xaxis = list(title = "UMAP1"),
      yaxis = list(title = "UMAP2")
    )
}

# =====================================================
# BUILD VARIANCE CURVE
# =====================================================

build_variance <- function(
  path,
  title = "Variance Explained"
) {

  df <- read.table(
    gzfile(path),
    header = TRUE,
    sep = "\t",
    stringsAsFactors = FALSE
  )

  df <- normalise_pca_df(df)

  pve <- attr(df, "pve")

  if (is.null(pve)) return(NULL)

  cumvar <- cumsum(pve)
  n90 <- which(cumvar >= 90)[1]

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
      title = paste0(
        title,
        if (!is.na(n90)) {
          paste0("<br>", n90, " PCs explain 90% variance")
        } else {
          ""
        }
      ),
      xaxis = list(title = "Principal Component"),
      yaxis = list(title = "Variance Explained (%)")
    )
}