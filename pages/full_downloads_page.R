library(shiny)


# ============================================================
# FULL-DATASET DOWNLOAD SETTINGS
# ============================================================

FULL_DOWNLOAD_COLUMNS <- c(
  "Predicted DNAm" = "predicted_download_full",
  "Input RNA" = "input_download_full",
  "Gold-standard DNAm" = "goldstandard_download_full"
)


# ============================================================
# HELPER: VALID LINK
# ============================================================

is_valid_download_link <- function(href) {

  !is.null(href) &&
    length(href) > 0 &&
    !is.na(href) &&
    trimws(href) != "" &&
    tolower(trimws(href)) != "n/a"
}


# ============================================================
# HELPER: GROUP METADATA INTO FULL DATASETS
# ============================================================

# Entries that share the same three full-dataset links belong
# to the same full dataset. Returns one row per full dataset,
# in metadata order, with a readable label.

get_full_datasets <- function(
  metadata = read.csv(
    "data/metadata.csv",
    stringsAsFactors = FALSE
  )
) {

  links <- metadata[FULL_DOWNLOAD_COLUMNS]
  links[is.na(links)] <- ""

  group_key <- do.call(
    paste,
    c(links, sep = "|")
  )

  keep <- group_key != "||"

  metadata <- metadata[keep, , drop = FALSE]
  group_key <- group_key[keep]

  metadata$assay <- trimws(
    metadata$dna_methylation_assay
  )

  metadata$species_label <- ifelse(
    tolower(trimws(metadata$species)) == "homo sapiens",
    "Human",
    ifelse(
      tolower(trimws(metadata$species)) == "mus musculus",
      "Mouse",
      metadata$species
    )
  )

  metadata$expression_label <- ifelse(
    grepl("single-cell", metadata$gene_expression),
    "single-cell",
    ifelse(
      grepl("spatial", metadata$gene_expression),
      "spatial",
      "bulk"
    )
  )

  groups <- unique(group_key)
  group_size <- table(group_key)[groups]

  rows <- lapply(groups, function(key) {

    members <- metadata[group_key == key, , drop = FALSE]
    first <- members[1, ]

    label <- first$dataset

    if (nrow(members) == 1) {

      # Single-entry datasets are named by their tissue,
      # cancer, or cohort (e.g. TARGET cohorts, spatial).
      tissue <- gsub("_", " ", trimws(first$tissue))
      tissue <- sub("\\b(i+)$", "\\U\\1", tissue, perl = TRUE)
      tissue <- paste0(toupper(substr(tissue, 1, 1)), substring(tissue, 2))

      if (tolower(tissue) != tolower(first$dataset)) {
        label <- paste0(label, ": ", tissue)
      }

    } else {

      # Multi-entry datasets from the same source are told
      # apart by whatever differs between them.
      siblings <- metadata[
        metadata$dataset == first$dataset &
          group_key %in% names(group_size)[group_size > 1],
        ,
        drop = FALSE
      ]

      if (length(unique(siblings$expression_label)) > 1) {
        label <- paste(label, first$expression_label)
      }

      if (length(unique(siblings$assay)) > 1) {
        label <- paste(label, first$assay)
      }

      if (length(unique(siblings$species_label)) > 1) {
        label <- paste0(label, " (", first$species_label, ")")
      }
    }

    data.frame(
      key = key,
      label = label,
      gene_expression = first$gene_expression,
      assay = first$assay,
      species = first$species_label,
      n_entries = nrow(members),
      predicted = first$predicted_download_full,
      input = first$input_download_full,
      gold = first$goldstandard_download_full,
      stringsAsFactors = FALSE
    )
  })

  do.call(rbind, rows)
}


# ============================================================
# HELPER: FULL-DATASET LINK CELL
# ============================================================

full_download_cell <- function(href, label) {

  if (!is_valid_download_link(href)) {

    return(
      tags$span(
        class = "full-download-missing",
        title = paste(label, "not available"),
        "—"
      )
    )
  }

  tags$a(
    href = href,
    target = "_blank",
    class = "btn btn-outline-primary btn-sm",
    `aria-label` = label,
    "Download"
  )
}


# ============================================================
# UI
# ============================================================

full_downloads_ui <- function() {

  datasets <- get_full_datasets()

  fluidPage(
    class = "site-page full-downloads-page",


    div(
      style = "max-width:1400px; margin:auto; padding-top:30px;",

      div(
        class = "page-heading",
        h1(
          style = "
            font-size:56px;
            font-weight:900;
            margin-bottom:20px;
          ",
          "Full Dataset Downloads"
        ),

        p(
          style = "
            font-size:20px;
            color:#64748B;
            margin-bottom:30px;
          ",
          "Download complete datasets. For a single tissue, cancer type, or cell type, use the download links on its entry page."
        )
      ),

      div(
        class = "feature-card",

        h2("Datasets"),

        div(
          class = "table-responsive",

          tags$table(
            class = "table align-middle",

            tags$thead(
              tags$tr(
                tags$th("Dataset"),
                tags$th("Gene expression"),
                tags$th("Methylation"),
                tags$th("Species"),
                tags$th("Entries"),
                tags$th("Predicted DNAm"),
                tags$th("Input RNA"),
                tags$th("Gold-standard DNAm")
              )
            ),

            tags$tbody(
              lapply(seq_len(nrow(datasets)), function(i) {

                d <- datasets[i, ]

                tags$tr(
                  tags$td(strong(d$label)),
                  tags$td(d$gene_expression),
                  tags$td(d$assay),
                  tags$td(d$species),
                  tags$td(d$n_entries),
                  tags$td(full_download_cell(d$predicted, "Predicted DNAm")),
                  tags$td(full_download_cell(d$input, "Input RNA")),
                  tags$td(full_download_cell(d$gold, "Gold-standard DNAm"))
                )
              })
            )
          )
        )
      )
    )
  )
}

full_downloads_server <- function(input, output, session) {
}
