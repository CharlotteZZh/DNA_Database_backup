library(shiny)
library(plotly)

entry_ui <- function() {

  fluidPage(

    div(
      style = "
        max-width:1600px;
        margin:auto;
        padding-top:25px;
      ",

      fluidRow(

        # =========================================
        # LEFT COLUMN
        # =========================================

        column(
          4,

          div(
            class = "feature-card",
            uiOutput("metadata_table")
          ),

          br(),

          div(
            class = "feature-card",

            h2("Dataset Description"),

            p(
              style = "
                font-size:16px;
                line-height:1.7;
                color:#475569;
                margin-bottom:0;
              ",
              textOutput("dataset_notes")
            )
          ),

          br(),

          div(
            class = "feature-card",

            h2("Downloads"),

            br(),

            uiOutput("prediction_download"),
            br(), br(),

            uiOutput("source_download"),
            br(), br(),

            uiOutput("rna_download"),
            br(), br(),

            uiOutput("plot_download")
          )
        ),

        # =========================================
        # RIGHT COLUMN
        # =========================================

        column(
          8,

          div(
            class = "feature-card",

            h2("Principal Component Analysis"),

            uiOutput("pca_tabs")
          ),

          br(),

          div(
            class = "feature-card",

            h2("UMAP Embeddings"),

            uiOutput("umap_tabs")
          )
        )
      )
    )
  )
}

entry_server <- function(
    input,
    output,
    session,
    selected_entry
) {

  current_entry <- reactive({
    req(selected_entry())
    selected_entry()
  })

  # =========================================
  # METADATA
  # =========================================

  output$metadata_table <- renderUI({

    div(

      # HEADER
      h2(
        style="
          font-size:38px;
          font-weight:800;
          margin-bottom:4px;
          color:#0F172A;
          line-height:1.1;
        ",
        tools::toTitleCase(
          gsub("_", " ", current_entry()$tissue[1])
        )
      ),

      p(
        style="
          font-size:16px;
          color:#64748B;
          margin-bottom:4px;
        ",
        gsub("_", " ", current_entry()$dataset[1])
      ),

      p(
        style="
          font-size:14px;
          color:#94A3B8;
          margin-bottom:14px;
        ",
        paste(
          current_entry()$species[1],
          "·",
          current_entry()$disease_status[1]
        )
      ),

      # BADGE
      div(
        style="
          display:inline-block;
          padding:8px 16px;
          border-radius:999px;
          background:#F3E8FF;
          color:#6D28D9;
          font-size:14px;
          font-weight:700;
          margin-bottom:18px;
        ",
        paste(
          current_entry()$gene_expression[1],
          "→",
          current_entry()$dna_methylation_assay[1]
        )
      ),

      # =========================================
      # ENTRY STATS
      # =========================================

      div(
        class = "mini-meta-card",

        h4("Entry"),

        div(
          class = "meta-grid",

          div(
            class = "meta-stat",
            h5("Tissue"),
            p(
              tools::toTitleCase(
                gsub("_", " ", current_entry()$tissue[1])
              )
            )
          ),

          div(
            class = "meta-stat",
            h5("n"),
            p(current_entry()$n_samples_per_tissue[1])
          ),

          div(
            class = "meta-stat",
            h5("CpGs"),
            p(
              format(
                current_entry()$n_cpgs_total[1],
                big.mark = ","
              )
            )
          ),

          div(
            class = "meta-stat",
            h5("β"),
            p(
              if (
                !is.na(current_entry()$beta_mean_total[1]) &&
                current_entry()$beta_mean_total[1] != ""
              )
                round(
                  as.numeric(current_entry()$beta_mean_total[1]),
                  3
                )
              else
                "N/A"
            )
          ),

          div(
            class = "meta-stat",
            h5("Expr"),
            p(
              if (
                !is.na(current_entry()$Expr_mean_total[1]) &&
                current_entry()$Expr_mean_total[1] != ""
              )
                round(
                  as.numeric(current_entry()$Expr_mean_total[1]),
                  3
                )
              else
                "N/A"
            )
          )
        )
      ),

      div(style="height:6px;"),

      # =========================================
      # DATASET STATS
      # =========================================

      div(
        class = "mini-meta-card",

        h4("Dataset"),

        div(
          class = "meta-grid",

          div(
            class = "meta-stat",
            h5("Total n"),
            p(current_entry()$n_samples_total[1])
          ),

          div(
            class = "meta-stat",
            h5("CpGs"),
            p(
              format(
                current_entry()$n_cpgs_total[1],
                big.mark = ","
              )
            )
          ),

          div(
            class = "meta-stat",
            h5("PCA"),
            p("Pan-dataset")
          ),

          div(
            class = "meta-stat",
            h5("Input"),
            p(current_entry()$gene_expression[1])
          ),

          div(
            class = "meta-stat",
            h5("Output"),
            p(current_entry()$dna_methylation_assay[1])
          )
        )
      )
    )
  })

  # =========================================
  # DESCRIPTION
  # =========================================

  output$dataset_notes <- renderText({
    paste(
      "This entry represents a tissue- or cohort-specific subset of the",
      current_entry()$dataset[1],
      "dataset. Interactive PCA embeddings are computed at the full dataset level to preserve global biological structure and enable cross-tissue or cross-cohort comparisons."
    )
  })

  # =========================================
  # PCA TABS
  # =========================================

  output$pca_tabs <- renderUI({

    tabsetPanel(

      tabPanel(
        "Input RNA",
        plotlyOutput("entry_pca_input", height = "500px")
      ),

      tabPanel(
        "Predicted DNAm",
        plotlyOutput("entry_pca_pred", height = "500px")
      ),

      tabPanel(
        "Gold-standard DNAm",
        plotlyOutput("entry_pca_gold", height = "500px")
      ),

      tabPanel(
        "Static Plot",

        br(),

        if (
          !is.na(current_entry()$plot_path[1]) &&
          current_entry()$plot_path[1] != ""
        ) {

          tags$iframe(
            src = current_entry()$plot_path[1],
            width = "100%",
            height = "900px",
            style = "border:none;"
          )

        } else {

          div(
            class = "coming-soon-box",
            "Static plot unavailable."
          )
        }
      )
    )
  })

  # =========================================
  # UMAP TABS
  # =========================================

  output$umap_tabs <- renderUI({

    tabsetPanel(

      tabPanel(
  "Input RNA",
  plotlyOutput("entry_umap_input", height = "500px")
),

tabPanel(
  "Predicted DNAm",
  plotlyOutput("entry_umap_pred", height = "500px")
),

tabPanel(
  "Gold-standard DNAm",
  plotlyOutput("entry_umap_gold", height = "500px")
)
    )
  })

  # PCA plots

  output$entry_pca_input <- renderPlotly({
    build_type_pca(
      current_entry()$input_pca[1],
      current_entry()$pca_group[1],
      "Input RNA — PCA"
    )
  })

  output$entry_pca_pred <- renderPlotly({
    build_type_pca(
      current_entry()$predicted_pca[1],
      current_entry()$pca_group[1],
      "Predicted DNAm — PCA"
    )
  })

  output$entry_pca_gold <- renderPlotly({
    build_type_pca(
      current_entry()$output_pca[1],
      current_entry()$pca_group[1],
      "Gold-standard DNAm — PCA"
    )
  })

  output$entry_umap_input <- renderPlotly({
  build_type_umap(
    current_entry()$input_umap[1],
    current_entry()$pca_group[1],
    "Input RNA — UMAP"
  )
})

output$entry_umap_pred <- renderPlotly({
  build_type_umap(
    current_entry()$predicted_umap[1],
    current_entry()$pca_group[1],
    "Predicted DNAm — UMAP"
  )
})

output$entry_umap_gold <- renderPlotly({
  build_type_umap(
    current_entry()$output_umap[1],
    current_entry()$pca_group[1],
    "Gold-standard DNAm — UMAP"
  )
})

  # DOWNLOADS

  output$prediction_download <- renderUI({
    tags$a(
      href = current_entry()$predicted_path[1],
      target = "_blank",
      class = "btn btn-primary",
      style = "width:100%;",
      "Download Predicted DNAm"
    )
  })

  output$source_download <- renderUI({
    tags$a(
      href = current_entry()$gold_path[1],
      target = "_blank",
      class = "btn btn-secondary",
      style = "width:100%;",
      "Download Gold-standard DNAm"
    )
  })

  output$rna_download <- renderUI({
    tags$a(
      href = current_entry()$input_path[1],
      target = "_blank",
      class = "btn btn-secondary",
      style = "width:100%;",
      "Download Input RNA"
    )
  })

  output$plot_download <- renderUI({
    tags$a(
      href = current_entry()$plot_path[1],
      target = "_blank",
      class = "btn btn-secondary",
      style = "width:100%;",
      "Download Static Plot"
    )
  })
}