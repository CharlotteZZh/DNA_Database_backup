library(shiny)

news_ui <- function() {

  fluidPage(

    div(
      style = "max-width:1400px; margin:auto; padding-top:30px;",

      h1(
        style = "
          font-size:56px;
          font-weight:900;
          margin-bottom:20px;
          background: linear-gradient(90deg, #0F766E, #2563EB);
          -webkit-background-clip: text;
          -webkit-text-fill-color: transparent;
        ",
        "News"
      ),

      p(
        style = "
          font-size:20px;
          color:#64748B;
          margin-bottom:30px;
        ",
        "Latest updates, new datasets, and model releases."
      ),

      div(
        class = "feature-card",

        h2("Latest Updates"),

        tags$ul(
          tags$li("New TCGA UMAP embeddings added."),
          tags$li("ENCODE bulk predicted DNAm updated."),
          tags$li("GTEx pan-tissue PCA labels refined."),
          tags$li("MethylProphetDB public deployment is now live.")
        )
      ),

      br(),

      div(
        class = "feature-card",

        h2("Coming Soon"),

        tags$ul(
          tags$li("Human Cell Atlas integration"),
          tags$li("Spatial transcriptomics methylation reconstruction"),
          tags$li("Expanded ENCODE4 single-cell coverage"),
          tags$li("Recount2 large-scale deployment")
        )
      )
    )
  )
}

news_server <- function(input, output, session) {
}