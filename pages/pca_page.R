library(shiny)
library(plotly)

gtex_pca <- readRDS(
  "data/pca/gtex/pc_pd.rds"
)

colnames(gtex_pca)[1:2] <- c("PC1", "PC2")

pca_ui <- function() {
  
  fluidPage(
    
    h1("PCA Explorer"),
    
    br(),
    
    plotlyOutput(
      "pca_plot",
      height = "700px"
    )
    
  )
  
}

pca_server <- function(input, output, session) {
  
  output$pca_plot <- renderPlotly({
    
    plot_ly(
      data = gtex_pca,
      x = ~PC1,
      y = ~PC2,
      type = "scatter",
      mode = "markers",
      color = ~database,
      text = ~paste(
        "Sample:", name,
        "<br>Type:", type,
        "<br>Database:", database
      ),
      hoverinfo = "text"
    )
    
  })
  
}