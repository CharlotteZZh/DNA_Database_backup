library(shiny)
library(plotly)

# =====================================================
# PCA RENDER HELPERS
# =====================================================
# Shared by the Entry Details page (pages/entry_page.R). Each entry shows
# up to three interactive PCA tabs -- Input RNA, Predicted (output) DNAm,
# and Gold-standard DNAm -- plus a static plot. The coordinate files are
# shared per dataset (all GTEx entries point at the same GTEx file, etc.).
#
# These helpers read whatever coordinate file a metadata column points at
# and render it. They cope with several historical file schemas:
#
#   * generate_pca.R output : PC1..PCn, group, name (+ celltype), attr "pve"
#   * gtex   pc_pd.rds       : PC1_26.69, PC2_21.92, type, database, name
#   * encode cv10_pd.rds     : PC1, PC2, ct, db, label
#   * encode Level3*.rds     : PC1, PC2, PC3, generaltissue, celltype, rownames
#   * legacy prcomp object   : pbmc pr.rds
#
# normalise_pca_df() folds all of these into PC1 / PC2 / group / name
# (+ celltype) so the plotting code below stays simple.
# =====================================================

# Read a coordinate file and return a tidy data.frame with PC1, PC2, group,
# name (+ celltype when available). attr(df, "pve") holds PC1/PC2 percent
# variance when it can be recovered, else NULL.
normalise_pca_df <- function(obj) {

  # ---- legacy prcomp object ----
  if (inherits(obj, "prcomp")) {

    df <- as.data.frame(obj$x[, 1:2, drop = FALSE])
    colnames(df)[1:2] <- c("PC1", "PC2")

    df$group    <- "Sample"
    df$name     <- rownames(df)
    df$celltype <- NA_character_

    pve <- (obj$sdev^2) / sum(obj$sdev^2)
    attr(df, "pve") <- pve[1:2] * 100

    return(df)
  }

  # ---- coordinate data.frame ----
  df <- as.data.frame(obj)

  pc_cols <- grep("^PC", colnames(df))
  orig_pc <- colnames(df)[pc_cols][1:2]

  colnames(df)[pc_cols[1:2]] <- c("PC1", "PC2")

  # some files embed variance in the column name, e.g. "PC1_26.69"
  pve <- suppressWarnings(as.numeric(sub("^PC[0-9]+_?", "", orig_pc)))
  if (any(is.na(pve))) {
    pve_attr <- attr(obj, "pve")
    pve <- if (!is.null(pve_attr)) pve_attr[1:2] * 100 else NULL
  }
  attr(df, "pve") <- pve

  # grouping column (prefer tissue / cell-type style labels)
  group_candidates <- c(
    "group", "type", "ct", "generaltissue",
    "celltype", "label", "database", "db"
  )
  gcol <- intersect(group_candidates, colnames(df))[1]
  df$group <- if (!is.na(gcol)) as.character(df[[gcol]]) else "Sample"

  # human-readable point name
  name_candidates <- c("name", "label", "rownames")
  ncol_name <- intersect(name_candidates, colnames(df))[1]
  df$name <- if (!is.na(ncol_name)) {
    as.character(df[[ncol_name]])
  } else {
    rownames(df)
  }

  if (!"celltype" %in% colnames(df)) df$celltype <- NA_character_

  df
}

# Build an interactive PCA scatter for ONE data type.
# `path` points to a coordinate file. `entry_group` is the group label for
# the current entry; matching points are highlighted with an outlined overlay.
build_type_pca <- function(path, entry_group = NULL, title = "PCA") {

  df  <- normalise_pca_df(readRDS(path))
  pve <- attr(df, "pve")

  df$hover_text <- paste0(
    "<b>", df$name, "</b>",
    "<br>Group: ", df$group,
    ifelse(
      is.na(df$celltype),
      "",
      paste0("<br>Cell type: ", df$celltype)
    )
  )

  x_lab <- if (!is.null(pve)) paste0("PC1 (", round(pve[1], 1), "%)") else "PC1"
  y_lab <- if (!is.null(pve)) paste0("PC2 (", round(pve[2], 1), "%)") else "PC2"

  p <- plot_ly(
    data = df,
    x = ~PC1, y = ~PC2,
    type = "scatter", mode = "markers",
    color = ~group,
    text = ~hover_text,
    hoverinfo = "text",
    marker = list(size = 7, opacity = 0.55)
  )

  # highlight the current entry's group (outlined overlay)
  if (
    !is.null(entry_group) &&
    length(entry_group) == 1 &&
    !is.na(entry_group) &&
    nzchar(entry_group)
  ) {

    hl <- df[df$group == entry_group, , drop = FALSE]

    if (nrow(hl) > 0) {
      p <- p %>%
        add_trace(
          data = hl,
          x = ~PC1, y = ~PC2,
          type = "scatter", mode = "markers",
          text = ~hover_text,
          hoverinfo = "text",
          marker = list(
            size = 12,
            color = "rgba(0,0,0,0)",
            line = list(color = "black", width = 2)
          ),
          name = paste0(entry_group, " (this entry)"),
          inherit = FALSE,
          showlegend = TRUE
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

# Variance-explained curve for one data type. Returns NULL when the file
# carries no variance information.
build_variance <- function(path, title = "Variance Explained") {

  obj <- readRDS(path)

  pve <- attr(obj, "pve")

  if (is.null(pve) && inherits(obj, "prcomp")) {
    pve <- (obj$sdev^2) / sum(obj$sdev^2)
  }

  if (is.null(pve)) return(NULL)

  cumvar <- cumsum(pve)
  n90    <- which(cumvar >= 0.90)[1]

  df <- data.frame(
    PC = seq_along(pve),
    Variance = pve
  )

  plot_ly(
    data = df,
    x = ~PC, y = ~Variance,
    type = "scatter", mode = "lines+markers"
  ) %>%
    layout(
      title = paste0(
        title,
        if (!is.na(n90)) paste0("<br>", n90, " PCs explain 90% variance") else ""
      ),
      xaxis = list(title = "Principal Component"),
      yaxis = list(title = "Proportion of Variance")
    )
}
