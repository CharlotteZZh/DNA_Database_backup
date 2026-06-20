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
          
          # ===== METADATA =====
          
          div(
            class = "feature-card",
            
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
  # METADATA
  # =========================================
  
  output$metadata_table <- renderUI({
    
    div(
      
      # MAIN TITLE
      h2(
        style="
          font-size:42px;
          font-weight:800;
          margin-bottom:6px;
          color:#0F172A;
        ",
        tools::toTitleCase(
          gsub("_", " ", current_entry()$tissue[1])
        )
      ),
      
      # SUBTITLE
      p(
        style="
          font-size:18px;
          color:#64748B;
          margin-bottom:6px;
        ",
        gsub("_", " ", current_entry()$entry_name[1])
      ),
      
      p(
        style="
          font-size:16px;
          color:#94A3B8;
          margin-bottom:14px;
        ",
        paste(
          current_entry()$species[1],
          "·",
          current_entry()$disease_status[1]
        )
      ),
      
      # MODALITY BADGE
      div(
        style="
          display:inline-block;
          padding:10px 18px;
          border-radius:999px;
          background:#F3E8FF;
          color:#6D28D9;
          font-size:15px;
          font-weight:700;
          margin-bottom:18px;
        ",
        paste(
          current_entry()$gene_expression[1],
          "→",
          current_entry()$dna_methylation_assay[1]
        )
      ),
      
      # ENTRY BLOCK
      div(
        class = "mini-meta-card",
        
        h4("Entry"),
        
        div(
          class = "meta-row",
          span("Biological context"),
          span(
            tools::toTitleCase(
              gsub("_", " ", current_entry()$tissue[1])
            )
          )
        ),
        
        div(
          class = "meta-row",
          span("Samples"),
          span(current_entry()$n_samples[1])
        )
      ),
      
      div(style="height:8px;"),
      
      # DATASET BLOCK
      div(
        class = "mini-meta-card",
        
        h4("Dataset"),
        
        div(
          class = "meta-row",
          span("Parent cohort"),
          span(current_entry()$dataset[1])
        ),
        
        div(
          class = "meta-row",
          span("PCA scope"),
          span("Pan-dataset")
        ),
        
        div(
          class = "meta-row",
          span("Methylation"),
          span(current_entry()$dna_methylation_assay[1])
        ),
        
        div(
          class = "meta-row",
          span("Coverage"),
          span("Genome-wide")
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
      "transcriptomic samples using the MethylProphet framework."
    )
  })
  
  # =========================================
  # PCA TABS
  # =========================================
  
  output$pca_tabs <- renderUI({
    
    tabsetPanel(
      
      tabPanel(
        "Input RNA",
        plotlyOutput("entry_pca_input", height = "500px")
      ),
      
      tabPanel(
        "Predicted DNAm",
        plotlyOutput("entry_pca_pred", height = "500px")
      ),
      
      tabPanel(
        "Gold-standard DNAm",
        plotlyOutput("entry_pca_gold", height = "500px")
      ),
      
      tabPanel(
        "Static Plot",
        
        br(),
        
        if (
          !is.na(current_entry()$plot_path[1]) &&
          current_entry()$plot_path[1] != ""
        ) {
          
          tags$iframe(
            src = current_entry()$plot_path[1],
            width = "100%",
            height = "900px",
            style = "border:none;"
          )
          
        } else {
          
          div(
            class = "coming-soon-box",
            "Static plot unavailable."
          )
        }
      )
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
  
  # =========================================
  # DOWNLOADS
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