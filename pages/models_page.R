library(shiny)

models_ui <- function() {
  
  fluidPage(
    
    div(
      style = "max-width:1400px; margin:auto; padding-top:30px;",
      
      h1("Prediction Models"),
      
      br(),
      
      fluidRow(
        
        column(
          4,
          div(
            class = "feature-card",
            h2("Dreamland"),
            p("Cross-attention transformer model for methylation prediction."),
            tags$a(href = "#", class = "btn btn-primary", "Pretrained Weights")
          )
        ),
        
        column(
          4,
          div(
            class = "feature-card",
            h2("Ramp"),
            p("Ridge-regression model for predicted methylation profiling."),
            tags$a(href = "#", class = "btn btn-primary", "Pretrained Weights")
          )
        ),
        
        column(
          4,
          div(
            class = "feature-card",
            h2("MethylProphet"),
            p("Self-attention transformer model for epigenomic prediction."),
            tags$a(href = "#", class = "btn btn-primary", "Pretrained Weights")
          )
        )
      )
    )
  )
}

models_server <- function(input, output, session) {
}
