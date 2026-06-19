library(shiny)
library(plotly)

# PCA render helpers (build_type_pca / build_variance) live in
# pages/pca_page.R and are sourced by app.R.

entry_ui <- function() {
  
  fluidPage(
    
    div(
      style = "
        max-width:1600px;
        margin:auto;
        padding-top:25px;
      ",
      
      div(
        class = "entry-header",
        
        h1(
          class = "entry-title",
          textOutput("entry_title")
        ),
        
        p(
          style = "font-size:22px;",
          textOutput("entry_subtitle")
        )
      ),
      
      fluidRow(
        
        # ===== LEFT PANEL =====
        
        column(
          4,
          
          div(
            class = "feature-card",
            
            h3("Dataset Information"),
            
            uiOutput("metadata_table")
          ),
          
          br(),
          
          div(
            class = "feature-card",
            
            h3("Dataset Description"),
            
            textOutput("dataset_notes")
          ),
          
          br(),
          
          div(
            class = "feature-card",
            
            h3("Downloads"),
            
            br(),
            
            uiOutput("prediction_download"),
            
            br(),
            br(),
            
            uiOutput("source_download"),
            
            br(),
            br(),
            
            uiOutput("rna_download"),
            
            br(),
            br(),
            
            uiOutput("plot_download")
          )
        ),
        
        # ===== RIGHT PANEL =====
        
        column(
          8,
          
          uiOutput("dynamic_tabs")
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
  
  # ===== HEADER =====
  
  output$entry_title <- renderText({
    
    current_entry()$entry_name[1]
    
  })
  
  output$entry_subtitle <- renderText({
    
    paste(
      current_entry()$dataset[1],
      "|",
      current_entry()$tissue[1],
      "|",
      current_entry()$species[1]
    )
  })
  
  # ===== METADATA =====
  
  output$metadata_table <- renderUI({
    
    tagList(
      
      div(
        style = "
          display:flex;
          flex-wrap:wrap;
          gap:10px;
          margin-bottom:20px;
        ",
        
        span(
          style = "
            background:#CCFBF1;
            color:#0F766E;
            padding:8px 14px;
            border-radius:999px;
            font-weight:700;
          ",
          
          current_entry()$dataset[1]
        ),
        
        span(
          style = "
            background:#DBEAFE;
            color:#1D4ED8;
            padding:8px 14px;
            border-radius:999px;
            font-weight:700;
          ",
          
          current_entry()$species[1]
        ),
        
        span(
          style = "
            background:#F3E8FF;
            color:#7E22CE;
            padding:8px 14px;
            border-radius:999px;
            font-weight:700;
          ",
          
          current_entry()$gene_expression[1]
        ),
        
        span(
          style = "
            background:#FEF3C7;
            color:#B45309;
            padding:8px 14px;
            border-radius:999px;
            font-weight:700;
          ",
          
          current_entry()$dna_methylation_assay[1]
        )
      ),
      
      tags$table(
        style = "
          width:100%;
          font-size:17px;
        ",
        
        tags$tr(
          tags$td(strong("Tissue")),
          tags$td(current_entry()$tissue[1])
        ),
        
        tags$tr(
          tags$td(strong("Disease")),
          tags$td(current_entry()$disease_status[1])
        ),
        
        tags$tr(
          tags$td(strong("Samples")),
          tags$td(current_entry()$n_samples[1])
        ),
        
        tags$tr(
          tags$td(strong("Cells")),
          tags$td(current_entry()$n_cells[1])
        ),
        
        tags$tr(
          tags$td(strong("CpGs")),
          tags$td(current_entry()$n_cpgs[1])
        )
      )
    )
  })
  
  output$dataset_notes <- renderText({
    
    current_entry()$notes[1]
    
  })
  
  # ===== DETECT AVAILABLE FILES =====

  path_ok <- function(path) {
  !is.null(path) &&
    length(path) == 1 &&
    !is.na(path) &&
    nzchar(trimws(path)) &&
    file.exists(path)
}

  has_pred  <- reactive(path_ok(current_entry()$predicted_pca[1]))
  has_gold  <- reactive(path_ok(current_entry()$output_pca[1]))
  has_input <- reactive(path_ok(current_entry()$input_pca[1]))

  has_umap  <- reactive(path_ok(current_entry()$umap_path[1]))

  entry_group <- reactive(current_entry()$pca_group[1])
  
  # ===== DYNAMIC TABS =====

  output$dynamic_tabs <- renderUI({

    # Placeholder shown inside a subtab when its data file is missing.
    empty_panel <- function(label) {
      div(
        style = "
          padding:60px 20px;
          text-align:center;
          color:#64748B;
          font-size:18px;
        ",
        paste0("No ", label, " data available for this dataset yet.")
      )
    }

    # A PCA subtab: interactive plot + variance curve when the file exists,
    # otherwise the named-but-empty placeholder.
    pca_tab <- function(label, available, plot_id, var_id) {
      tabPanel(
        label,
        br(),
        if (available) {
          tagList(
            plotlyOutput(plot_id, height = "500px"),
            br(),
            plotlyOutput(var_id, height = "280px")
          )
        } else {
          empty_panel(label)
        }
      )
    }

    # PCA TABS -- always present (Input, Output/Predicted, Gold)

    tabs <- list(
      pca_tab("Input RNA",          has_input(), "entry_pca_input", "var_input"),
      pca_tab("Predicted DNAm",     has_pred(),  "entry_pca_pred",  "var_pred"),
      pca_tab("Gold-standard DNAm", has_gold(),  "entry_pca_gold",  "var_gold")
    )

    # UMAP TAB (only when present)

    if (has_umap()) {
      tabs <- append(
        tabs,
        list(
          tabPanel(
            "UMAP",
            br(),
            plotlyOutput(
              "entry_umap",
              height = "500px"
            )
          )
        )
      )
    }

    # STATIC PLOT TAB -- always present

    plot_path <- current_entry()$plot_path[1]
    has_static <- !is.null(plot_path) &&
      !is.na(plot_path) &&
      plot_path != ""

    tabs <- append(
      tabs,
      list(
        tabPanel(
          "Static Plot",
          br(),
          if (has_static) {
            tags$iframe(
              src = plot_path,
              width = "100%",
              height = "900px",
              style = "border:none;"
            )
          } else {
            empty_panel("Static plot")
          }
        )
      )
    )

    do.call(
      tabsetPanel,
      tabs
    )
  })
  
  # ===== PCA (one renderer per available data type) =====

  output$entry_pca_pred <- renderPlotly({
    req(has_pred())
    build_type_pca(
      current_entry()$predicted_pca[1],
      entry_group(),
      "Predicted DNAm \u2014 PCA"
    )
  })

  output$var_pred <- renderPlotly({
    req(has_pred())
    build_variance(current_entry()$predicted_pca[1])
  })

  output$entry_pca_gold <- renderPlotly({
    req(has_gold())
    build_type_pca(
      current_entry()$output_pca[1],
      entry_group(),
      "Gold-standard DNAm \u2014 PCA"
    )
  })

  output$var_gold <- renderPlotly({
    req(has_gold())
    build_variance(current_entry()$output_pca[1])
  })

  output$entry_pca_input <- renderPlotly({
    req(has_input())
    build_type_pca(
      current_entry()$input_pca[1],
      entry_group(),
      "Input RNA \u2014 PCA"
    )
  })

  output$var_input <- renderPlotly({
    req(has_input())
    build_variance(current_entry()$input_pca[1])
  })

  # ===== UMAP =====
  
  output$entry_umap <- renderPlotly({
    
    req(has_umap())
    
    umap_obj <- readRDS(
      current_entry()$umap_path[1]
    )
    
    umap_df <- as.data.frame(
      umap_obj
    )
    
    colnames(umap_df)[1:2] <- c(
      "UMAP1",
      "UMAP2"
    )
    
    plot_ly(
      data = umap_df,
      
      x = ~UMAP1,
      y = ~UMAP2,
      
      type = "scatter",
      mode = "markers"
      
    ) %>%
      
      layout(
        title = "UMAP Visualization"
      )
  })
  
  # ===== DOWNLOAD BUTTONS =====
  
  # ---------------------------------
  # FULL DATASET
  # ---------------------------------
  
  output$prediction_download <- renderUI({
    
    tags$a(
      href =
        current_entry()$full_dataset_download[1],
      
      target = "_blank",
      
      class = "btn btn-primary",
      
      style = "
      background:#0F766E;
      border:none;
      border-radius:18px;
      padding:18px 30px;
      font-size:20px;
      font-weight:600;
      width:100%;
      margin-bottom:20px;
    ",
      
      "Download Full Dataset"
    )
  })
  
  # ---------------------------------
  # INDIVIDUAL TISSUE DATASET
  # ---------------------------------
  
  output$source_download <- renderUI({
    
    tags$a(
      href =
        current_entry()$individual_download[1],
      
      target = "_blank",
      
      class = "btn btn-secondary",
      
      style = "
      background:#164E63;
      border:none;
      border-radius:18px;
      padding:18px 30px;
      font-size:20px;
      font-weight:600;
      width:100%;
      margin-bottom:20px;
    ",
      
      "Download Individual Tissue Dataset"
    )
  })
  
  # ---------------------------------
  # SOURCE RNA DATA
  # ---------------------------------
  
  output$rna_download <- renderUI({
    
    tags$a(
      href =
        current_entry()$source_download[1],
      
      target = "_blank",
      
      class = "btn btn-secondary",
      
      style = "
      background:#1E3A8A;
      border:none;
      border-radius:18px;
      padding:18px 30px;
      font-size:20px;
      font-weight:600;
      width:100%;
      margin-bottom:20px;
    ",
      
      "Download Source RNA Data"
    )
  })
  
  # ---------------------------------
  # PCA / PLOT DATA
  # ---------------------------------
  
  output$plot_download <- renderUI({
    
    tags$a(
      href =
        current_entry()$plot_download[1],
      
      target = "_blank",
      
      class = "btn btn-secondary",
      
      style = "
      background:#334155;
      border:none;
      border-radius:18px;
      padding:18px 30px;
      font-size:20px;
      font-weight:600;
      width:100%;
    ",
      
      "Download PCA / Plot Data"
    )
  })
}
