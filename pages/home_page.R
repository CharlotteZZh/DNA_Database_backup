library(shiny)

home_ui <- function() {
  fluidPage(
    class = "about-page",

    div(
      class = "hero-section",
      div(
        class = "about-hero-copy",
        h1(
          class = "hero-title",
          "MethylProphetDB"
        ),

        h3(
          class = "hero-subtitle",
          "A public atlas of inferred DNA methylation across bulk, single-cell, and spatial transcriptomes"
        ),

        p(
          class = "hero-text",
          paste(
            "Browse reconstructed methylomes from ENCODE, TCGA, GTEx,",
            "and other public resources to study epigenomic regulation",
            "across tissues, cell types, disease states, and spatial contexts."
          )
        ),

        actionButton(
          "start_exploring",
          "Explore Datasets",
          class = "main-button"
        )
      ),
      div(
        class = "about-hero-art",
        `aria-hidden` = "true",
        tags$canvas(id = "about-dna-canvas"),
        div(class = "about-orbit about-orbit-one"),
        div(class = "about-orbit about-orbit-two"),
        div(class = "about-art-glow")
      )
    ),

    div(
      class = "about-body",
      div(
        class = "about-section about-overview",

        h2("Overview"),

        p(
          "MethylProphetDB is a public database of predicted DNA methylation landscapes reconstructed from transcriptomic data."
        ),

        p(
          "The current release integrates ENCODE, GTEx, TCGA, and ENCODE4 single-cell datasets together with matched gold-standard methylation profiles."
        )
      ),

      div(
        class = "about-features",

        column(
          4,
          div(
            class = "feature-card about-feature",

            h3("Interactive PCA"),

            p(
              "Visualize tissue and cell-type methylation landscapes interactively."
            )
          )
        ),

        column(
          4,
          div(
            class = "feature-card about-feature",

            h3("UMAP Embeddings"),

            p(
              "Explore nonlinear methylation structure across single-cell and spatial datasets."
            )
          )
        ),

        column(
          4,
          div(
            class = "feature-card about-feature",

            h3("Prediction Workflow"),

            p(
              "Reconstruct genome-wide methylation landscapes from transcriptomic measurements."
            )
          )
        )
      ),

      div(
        class = "about-section about-contents",

        h2("Database Contents"),

        p(
          "MethylProphetDB integrates transcriptomic and methylation resources across bulk, cancer, and single-cell datasets."
        ),

        tags$ul(
          class = "about-resource-grid",
          tags$li(strong("ENCODE bulk: "), span(class = "resource-value", "95"), " matched RNA-seq and WGBS samples"),
          tags$li(strong("GTEx: "), span(class = "resource-value", "9"), " normal human tissues"),
          tags$li(strong("TCGA 450K: "), span(class = "resource-value", "9,194"), " tumor samples"),
          tags$li(strong("TCGA WGBS: "), span(class = "resource-value", "33"), " tumor samples"),
          tags$li(strong("ENCODE4 single-cell: "), "human and mouse pseudobulk atlases")
        ),

        br(),

        h4("Available Data Types"),

        tags$ul(
          class = "about-data-types",
          tags$li("Input RNA matrices"),
          tags$li("Predicted DNA methylation matrices"),
          tags$li("Gold-standard methylation profiles"),
          tags$li("Genome browser tracks (bedGraph)"),
          tags$li("Interactive PCA and UMAP embeddings")
        )
      ),

      div(
        class = "about-insights",
        div(
          class = "about-section about-pca",

          h2("Interactive PCA Visualization"),

          p(
            "PCA is performed on highly variable CpG loci to preserve methylation structure and global epigenomic organization across tissues, cancer types, and pseudobulk single-cell populations."
          ),

          tags$ul(
            tags$li("Input RNA"),
            tags$li("Predicted DNAm"),
            tags$li("Gold-standard DNAm")
          )
        ),
        div(
          class = "about-section about-applications",

          h2("Potential Applications for Users"),

          tags$ul(
            tags$li("Cross-tissue methylation analysis"),
            tags$li("Pan-cancer epigenomic analysis"),
            tags$li("Single-cell methylation profiling"),
            tags$li("Transcriptome-guided epigenomic inference"),
            tags$li("Biomarker hypothesis generation")
          )
        )
      ),

      div(
        class = "about-section about-publications",

        h2("Publications"),

        br(),

        tags$ol(
          style = "font-size:18px; line-height:1.9;",

          tags$li(

            HTML("
              Huang, X.&#8224;,
              Liu, Q.&#8224;,
              Zhao, Y.,
              Tang, X.,
              Zhou, Y.* and
              Hou, W.*.
              2025.
            "),

            tags$a(
              href = "https://www.biorxiv.org/content/biorxiv/early/2025/02/08/2025.02.05.636730.full.pdf",
              target = "_blank",
              style = "
                font-style:italic;
                color:#0F172A;
                font-weight:500;
                text-decoration:none;
              ",
              "MethylProphet: A Generalized Gene-Contextual Model for Inferring Whole-Genome DNA Methylation Landscape."
            ),

            HTML(" Model: MethylProphet. Accepted by "),

            tags$a(
              href = "https://iclr.cc/",
              target = "_blank",
              "ICLR 2026"
            ),

            HTML(". "),

            tags$a(
              href = "https://openreview.net/forum?id=8wQ7Oc08vo",
              target = "_blank",
              "OpenReview"
            ),

            HTML(".")
          )
        )
      )
    )
  )
}

home_server <- function(input, output, session) {

  observeEvent(
    input$start_exploring,
    {
      updateNavbarPage(
        session,
        "main_navbar",
        selected = "Datasets"
      )
    }
  )
}
