library(shiny)

about_ui <- function() {
  
  fluidPage(
    
    h1("About predDNAmDB"),
    
    br(),
    
    p(
      "predDNAmDB is a database of predicted DNA methylation landscapes reconstructed from transcriptomic data."
    ),
    
    br(),
    
    h3("Datasets"),
    
    tags$ul(
      tags$li("ENCODE"),
      tags$li("GTEx"),
      tags$li("TCGA")
    ),
    
    br(),
    
    h3("Models"),
    
    tags$ul(
      tags$li("Dreamland"),
      tags$li("Ramp")
    )
  )
}

about_server <- function(input, output, session) {
}