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
          
          # ===== DATASET INFORMATION =====
          
          div(
            class = "feature-card",
            
            h1(
              style = "
                font-size:24px;
                font-weight:800;
                margin-bottom:4px;
                line-height:1.25;
                word-break:break-word;
              ",
              textOutput("entry_title")
            ),
            
            p(
              style = "
                font-size:16px;
                color:#64748B;
                margin-bottom:24px;
              ",
              textOutput("entry_subtitle")
            ),
            
            h2("Dataset Information"),
            
            uiOutput("metadata_table")
          ),
          
          br(),
          
          # ===== DATASET DESCRIPTION =====
          
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
          
          # ===== DOWNLOADS =====
          
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
          
          # ===== PCA =====
          
          div(
            class = "feature-card",
            
            h2("Principal Component Analysis"),
            
            uiOutput("pca_tabs")
          ),
          
          br(),
          
          # ===== UMAP =====
          
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
  # HEADER
  # =========================================
  
  output$entry_title <- renderText({
    current_entry()$tissue[1]
  })
  
  output$entry_subtitle <- renderText({
  paste(
    current_entry()$dataset[1],
    "•",
    current_entry()$species[1],
    "•",
    current_entry()$gene_expression[1],
    "→",
    current_entry()$dna_methylation_assay[1]
  )
})
  
  # =========================================
  # METADATA TABLE
  # =========================================
  
  output$metadata_table <- renderUI({
  
  div(
    style = "
      display:flex;
      flex-direction:column;
      gap:18px;
      font-size:18px;
      margin-top:10px;
    ",
    
    div(
      style="display:flex;justify-content:space-between;",
      strong("Dataset"),
      span(current_entry()$dataset[1])
    ),
    
    div(
      style="display:flex;justify-content:space-between;",
      strong("Species"),
      span(current_entry()$species[1])
    ),
    
    div(
      style="display:flex;justify-content:space-between;",
      strong("Samples"),
      span(current_entry()$n_samples[1])
    ),
    
    div(
      style="display:flex;justify-content:space-between;",
      strong("Condition"),
      span(current_entry()$disease_status[1])
    ),
    
    div(
      style="display:flex;justify-content:space-between;",
      strong("Input"),
      span(current_entry()$gene_expression[1])
    ),
    
    div(
      style="display:flex;justify-content:space-between;",
      strong("Output"),
      span(current_entry()$dna_methylation_assay[1])
    ),
    
    div(
      style="display:flex;justify-content:space-between;",
      strong("CpGs"),
      span(
        ifelse(
          is.na(current_entry()$n_cpgs[1]),
          "Genome-wide",
          current_entry()$n_cpgs[1]
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
      "This dataset contains predicted and experimentally measured DNA methylation profiles reconstructed from",
      current_entry()$dataset[1],
      "transcriptomic samples. The methylation profiles were generated using the MethylProphet framework and paired with gold-standard measurements when available."
    )
  })
  
  # =========================================
  # PCA TABS
  # =========================================
  
  output$pca_tabs <- renderUI({
    
    tabsetPanel(
      
      tabPanel("Input RNA",
               plotlyOutput("entry_pca_input", height = "500px")),
      
      tabPanel("Predicted DNAm",
               plotlyOutput("entry_pca_pred", height = "500px")),
      
      tabPanel("Gold-standard DNAm",
               plotlyOutput("entry_pca_gold", height = "500px")),
      
      tabPanel("Static Plot",
               plotlyOutput("entry_static", height = "500px"))
    )
  })
  
  # =========================================
  # UMAP TABS
  # =========================================
  
  output$umap_tabs <- renderUI({
    
    tabsetPanel(
      
      tabPanel(
        "Input RNA",
        div(
          class = "coming-soon-box",
          "Input RNA UMAP coming soon."
        )
      ),
      
      tabPanel(
        "Predicted DNAm",
        div(
          class = "coming-soon-box",
          "Predicted DNAm UMAP coming soon."
        )
      ),
      
      tabPanel(
        "Gold-standard DNAm",
        div(
          class = "coming-soon-box",
          "Gold-standard DNAm UMAP coming soon."
        )
      )
    )
  })
  

  # =========================================
# PCA PLOTS
# =========================================

output$entry_pca_input <- renderPlotly({
  
  req(current_entry())
  
  build_type_pca(
    current_entry()$input_pca[1],
    current_entry()$pca_group[1],
    "Input RNA — PCA"
  )
})

output$entry_pca_pred <- renderPlotly({
  
  req(current_entry())
  
  build_type_pca(
    current_entry()$predicted_pca[1],
    current_entry()$pca_group[1],
    "Predicted DNAm — PCA"
  )
})

output$entry_pca_gold <- renderPlotly({
  
  req(current_entry())
  
  build_type_pca(
    current_entry()$output_pca[1],
    current_entry()$pca_group[1],
    "Gold-standard DNAm — PCA"
  )
})

output$entry_static <- renderPlotly({
  
  req(current_entry())
  
  build_type_pca(
    current_entry()$predicted_pca[1],
    current_entry()$pca_group[1],
    "Static PCA View"
  )
})
  
  # =========================================
  # DOWNLOAD BUTTONS
  # =========================================
  
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