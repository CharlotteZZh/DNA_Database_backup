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
            "Browse DNA methylation predicted from ENCODE, GTEx, TCGA, TARGET,",
            "CPTAC-3, and other public transcriptomic resources to study epigenomic",
            "regulation across tissues, cell types, cancers, and spatial contexts."
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
          "MethylProphetDB is a public database of DNA methylation landscapes predicted from bulk, single-cell, and spatial transcriptomic data."
        ),

        p(
          "The current release contains 99 entries from ENCODE, GTEx, TCGA, TARGET, CGCI-HTMCP-CC, CPTAC-3, HCMIC-CMDC, ENCODE4 single-cell, and spatial transcriptomics datasets. Where measured methylation is available (WGBS, 450K, or EPIC), it is provided as a gold-standard reference alongside the predictions."
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
              "Compare input RNA, predicted DNAm, and gold-standard DNAm across tissues, cancer types, and cell types."
            )
          )
        ),

        column(
          4,
          div(
            class = "feature-card about-feature",

            h3("UMAP Embeddings"),

            p(
              "Explore nonlinear structure in bulk, cancer, and single-cell datasets."
            )
          )
        ),

        column(
          4,
          div(
            class = "feature-card about-feature",

            h3("Spatial Methylation Maps"),

            p(
              "View predicted methylation across tissue sections, starting with four mouse embryo slides."
            )
          )
        )
      ),

      div(
        class = "about-section about-contents",

        h2("Database Contents"),

        p(
          "MethylProphetDB brings together transcriptomic and methylation resources from normal tissues, cancers, single-cell atlases, and spatial transcriptomics."
        ),

        tags$ul(
          class = "about-resource-grid",
          tags$li(strong("ENCODE bulk: "), span(class = "resource-value", "95"), " matched RNA-seq and WGBS samples across 19 tissues"),
          tags$li(strong("GTEx: "), span(class = "resource-value", "9"), " normal human tissues"),
          tags$li(strong("TCGA 450K: "), span(class = "resource-value", "9,194"), " tumor samples across 32 cancer types"),
          tags$li(strong("TCGA WGBS: "), span(class = "resource-value", "33"), " tumor samples across 8 cancer types"),
          tags$li(strong("TARGET: "), span(class = "resource-value", "605"), " pediatric tumor samples across 8 cohorts (450K and EPIC)"),
          tags$li(strong("CGCI-HTMCP-CC, CPTAC-3, HCMIC-CMDC: "), span(class = "resource-value", "1,360"), " tumor samples (EPIC)"),
          tags$li(strong("ENCODE4 single-cell: "), "pseudobulk profiles from 13 human and 4 mouse tissues, plus human PBMC"),
          tags$li(strong("Spatial transcriptomics: "), "mouse embryo (4 slides); mouse pancreas coming soon")
        ),

        br(),

        h4("Available Data Types"),

        tags$ul(
          class = "about-data-types",
          tags$li("Input RNA matrices"),
          tags$li("Predicted DNA methylation matrices"),
          tags$li("Gold-standard methylation profiles"),
          tags$li("Genome browser DNAm tracks (bedGraph)"),
          tags$li("Interactive PCA and UMAP embeddings"),
          tags$li("Spatial methylation maps")
        )
      ),

      div(
        class = "about-insights",
        div(
          class = "about-section about-pca",

          h2("Interactive PCA Visualization"),

          p(
            "Each dataset includes precomputed PCA embeddings, so you can compare how samples group by tissue, cancer type, or pseudobulk cell population. Views are shown where the data exist:"
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
            tags$li("Cell-type-level methylation inference from single-cell RNA-seq"),
            tags$li("Spatial methylation mapping"),
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
