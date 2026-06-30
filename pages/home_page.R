library(shiny)

home_ui <- function() {

  fluidPage(

    div(
      style = "max-width:1650px; margin:auto; padding:0;" ,

      # HERO
      div(
        class = "hero-section",
        style = "
    padding-top:8px;
    padding-bottom:8px;
  ",

        h1(class = "hero-title", "MethylProphet DB"),

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
          "Start Exploring",
          class = "main-button"
        )
      )
    ),

    br(),

    # FEATURE CARDS
    fluidRow(

      column(
        4,
        div(
          class = "feature-card",

          img(
            src = "images/pca.png",
            style = "width:100%; border-radius:18px;"
          ),

          br(), br(),

          h3("Interactive PCA"),

          p("Visualize tissue and cell-type methylation landscapes interactively.")
        )
      ),

      column(
        4,
        div(
          class = "feature-card",

          img(
            src = "images/umap.png",
            style = "width:100%; border-radius:18px;"
          ),

          br(), br(),

          h3("UMAP Embeddings"),

          p("Explore nonlinear methylation structure across single-cell and spatial datasets.")
        )
      ),

      column(
        4,
        div(
          class = "feature-card",

          img(
            src = "images/workflow.png",
            style = "width:100%; border-radius:18px;"
          ),

          br(), br(),

          h3("Prediction Workflow"),

          p("Reconstruct genome-wide methylation landscapes from transcriptomic measurements.")
        )
      )
    ),

    br(),
    br(),

    # PUBLICATIONS
    div(
      class = "feature-card",

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
    ),

    br(),
    br(),

    # ===== ABOUT CONTENT (APPENDED) =====

    div(
      class = "feature-card",
      style = "border-left:8px solid #14B8A6;",
      h2("Overview"),
      p("MethylProphetDB is a public database of predicted DNA methylation landscapes reconstructed from transcriptomic data."),
      p("The current release integrates ENCODE, GTEx, TCGA, and ENCODE4 single-cell datasets together with matched gold-standard methylation profiles.")
    ),

    br(),

    div(
      class = "feature-card",
      style = "border-left:8px solid #3B82F6;",
      h2("Data Sources"),
      tags$ul(
        tags$li(strong("ENCODE bulk: "), "paired bulk RNA-seq and WGBS"),
        tags$li(strong("GTEx: "), "bulk RNA-seq across normal tissues"),
        tags$li(strong("TCGA: "), "pan-cancer RNA-seq with matched methylation"),
        tags$li(strong("ENCODE4 single-cell: "), "pseudobulk single-cell RNA-seq")
      )
    ),

    br(),

    div(
      class = "feature-card",
      style = "border-left:8px solid #8B5CF6;",
      h2("Current Database Content"),
      tags$ul(
        tags$li("ENCODE bulk: 95 matched samples"),
        tags$li("GTEx: 9 tissues"),
        tags$li("TCGA 450K: 9,194 tumor samples"),
        tags$li("TCGA WGBS: 33 tumor samples"),
        tags$li("ENCODE4 single-cell atlases")
      )
    ),

    br(),

    div(
      class = "feature-card",
      style = "border-left:8px solid #F59E0B;",
      h2("Available Data Types"),
      tags$ul(
        tags$li("Input RNA matrices"),
        tags$li("Predicted DNA methylation matrices"),
        tags$li("Gold-standard methylation"),
        tags$li("Genome browser tracks"),
        tags$li("PCA and UMAP embeddings")
      )
    ),

    br(),

    div(
      class = "feature-card",
      style = "border-left:8px solid #EF4444;",
      h2("Interactive PCA Visualization"),
      p("PCA is performed on highly variable CpG loci to preserve methylation structure."),
      tags$ul(
        tags$li("Input RNA"),
        tags$li("Predicted DNAm"),
        tags$li("Gold-standard DNAm")
      )
    ),

    br(),

    div(
      class = "feature-card",
      style = "border-left:8px solid #06B6D4;",
      h2("Applications"),
      tags$ul(
        tags$li("Cross-tissue methylation analysis"),
        tags$li("Pan-cancer epigenomics"),
        tags$li("Single-cell methylation profiling"),
        tags$li("Biomarker hypothesis generation")
      )
    ),

    br(),

    div(
      class = "feature-card",
      style = "border-left:8px solid #10B981;",
      h2("Future Expansion"),
      p("Future releases will expand to Human Cell Atlas, Recount2, and spatial transcriptomics.")
    ),

    br(),

    div(
      class = "feature-card",
      style = "background: linear-gradient(135deg,#F8FAFC,#EFF6FF); border:none;",
      h2("Acknowledgements"),
      p("We acknowledge ENCODE, GTEx, TCGA, and the broader scientific community for generating the foundational datasets used in this resource.")
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
        selected = "Explore"
      )
    }
  )
}