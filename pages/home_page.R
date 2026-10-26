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
          "DreamlandDB"
        ),

        h3(
          class = "hero-subtitle",
          "A deep learning model to predict genome-wide DNA methylation landscape"
        ),

        p(
          class = "hero-text",
          "The database to access Dreamland-predicted data and more"
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
        class = "about-insights",
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
