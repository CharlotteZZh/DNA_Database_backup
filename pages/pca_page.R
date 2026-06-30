library(shiny)
library(plotly)

# =====================================================
# NORMALIZE PCA DATA
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
# CLEAN LABELS
# =====================================================

clean_labels <- function(df, path, entry_group = NULL) {

  if (grepl("encode", path, ignore.case = TRUE)) {

    df$group <- gsub("^Homo sapiens ", "", df$group, ignore.case = TRUE)
    df$group <- gsub("^Mus musculus ", "", df$group, ignore.case = TRUE)
    df$group <- gsub(" tissue", "", df$group, ignore.case = TRUE)

    df$group <- gsub(" male adult \\(.*?\\)", "", df$group)
    df$group <- gsub(" female adult \\(.*?\\)", "", df$group)
    df$group <- gsub(" male child \\(.*?\\)", "", df$group)
    df$group <- gsub(" female child \\(.*?\\)", "", df$group)

    df$group <- gsub(
      " originated from ",
      " ",
      df$group,
      ignore.case = TRUE
    )

    df$group <- gsub("_", " ", df$group)

    # PBMC relabeling
    df$group <- gsub("^B Cell$", "Peripheral Blood", df$group, ignore.case = TRUE)
    df$group <- gsub("^Cd14-Positive Monocyte$", "Peripheral Blood", df$group, ignore.case = TRUE)
    df$group <- gsub("^T-Cell$", "Peripheral Blood", df$group, ignore.case = TRUE)
    df$group <- gsub("^Natural Killer Cell$", "Peripheral Blood", df$group, ignore.case = TRUE)

    df$group <- trimws(df$group)
    df$group <- tools::toTitleCase(df$group)

    df$group <- substr(df$group, 1, 35)

    if (!is.null(entry_group)) {
      entry_group <- gsub("^Homo sapiens ", "", entry_group, ignore.case = TRUE)
      entry_group <- gsub("^Mus musculus ", "", entry_group, ignore.case = TRUE)
      entry_group <- gsub(" tissue", "", entry_group, ignore.case = TRUE)
      entry_group <- gsub("_", " ", entry_group)

      entry_group <- gsub("^B Cell$", "Peripheral Blood", entry_group, ignore.case = TRUE)
      entry_group <- gsub("^Cd14-Positive Monocyte$", "Peripheral Blood", entry_group, ignore.case = TRUE)
      entry_group <- gsub("^T-Cell$", "Peripheral Blood", entry_group, ignore.case = TRUE)
      entry_group <- gsub("^Natural Killer Cell$", "Peripheral Blood", entry_group, ignore.case = TRUE)

      entry_group <- trimws(entry_group)
      entry_group <- tools::toTitleCase(entry_group)
      entry_group <- substr(entry_group, 1, 35)
    }
  }

  list(df = df, entry_group = entry_group)
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

  cleaned <- clean_labels(df, path, entry_group)
  df <- cleaned$df
  entry_group <- cleaned$entry_group

  pve <- attr(df, "pve")

  df$hover_text <- paste0(
    "<b>", df$name, "</b>",
    "<br>Group: ", df$group
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
    marker = list(
      size = 7,
      opacity = 0.55
    )
  )

  if (!is.null(entry_group)) {

    hl <- df[
      grepl(
        tolower(entry_group),
        tolower(df$group),
        fixed = TRUE
      ),
      ,
      drop = FALSE
    ]

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
            size = 10,
            color = "#F59E0B",
            line = list(
              color = "black",
              width = 2
            )
          ),
          name = paste0(entry_group, " (selected)"),
          inherit = FALSE
        )
    }
  }

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

  if (!"group" %in% colnames(df)) df$group <- df[[3]]
  if (!"name" %in% colnames(df)) df$name <- rownames(df)

  cleaned <- clean_labels(df, path, entry_group)
  df <- cleaned$df
  entry_group <- cleaned$entry_group

  df$hover_text <- paste0(
    "<b>", df$name, "</b>",
    "<br>Group: ", df$group
  )

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

  if (!is.null(entry_group)) {

    hl <- df[
      grepl(
        tolower(entry_group),
        tolower(df$group),
        fixed = TRUE
      ),
      ,
      drop = FALSE
    ]

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
            size = 10,
            color = "#F59E0B",
            line = list(
              color = "black",
              width = 2
            )
          ),
          name = paste0(entry_group, " (selected)"),
          inherit = FALSE
        )
    }
  }

  p %>%
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
      xaxis = list(title = "Principal Component"),
      yaxis = list(title = "Variance Explained (%)")
    )
}