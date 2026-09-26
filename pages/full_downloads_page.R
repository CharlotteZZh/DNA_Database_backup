library(shiny)

downloads_ui <- function() {
  
  fluidPage(
    
    h1("Downloads"),
    
    br(),
    
    fluidRow(
      
      column(
        4,
        div(
          class = "download-card",
          h3("ENCODE Single-Cell"),
          p("Predicted DNAm profiles for ENCODE4 pseudobulks."),
          tags$a(
            href = "#",
            "Download Dataset"
          )
        )
      ),
      
      column(
        4,
        div(
          class = "download-card",
          h3("GTEx Bulk"),
          p("Predicted DNAm profiles for GTEx tissues."),
          tags$a(
            href = "#",
            "Download Dataset"
          )
        )
      ),
      
      column(
        4,
        div(
          class = "download-card",
          h3("TCGA Bulk"),
          p("Predicted DNAm profiles for TCGA cancer samples."),
          tags$a(
            href = "#",
            "Download Dataset"
          )
        )
      )
    )
  )
}

downloads_server <- function(input, output, session) {
}