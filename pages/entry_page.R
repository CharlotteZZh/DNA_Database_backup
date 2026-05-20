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
  
  has_pca <- reactive({
    
    path <- current_entry()$pca_path[1]
    
    !is.na(path) &&
      path != "" &&
      file.exists(path)
    
  })
  
  has_umap <- reactive({
    
    path <- current_entry()$umap_path[1]
    
    !is.na(path) &&
      path != "" &&
      file.exists(path)
    
  })
  
  # ===== DYNAMIC TABS =====
  
  output$dynamic_tabs <- renderUI({
    
    tabs <- list()
    
    # PCA TAB
    
    if (has_pca()) {
      
      tabs <- append(
        tabs,
        
        list(
          
          tabPanel(
            "PCA",
            
            br(),
            
            plotlyOutput(
              "entry_pca",
              height = "500px"
            ),
            
            br(),
            
            plotlyOutput(
              "variance_plot",
              height = "300px"
            )
          )
        )
      )
    }
    
    # UMAP TAB
    
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
    
    # STATIC PDF
    
    plot_path <- current_entry()$plot_path[1]
    
    if (
      !is.na(plot_path) &&
      plot_path != ""
    ) {
      
      tabs <- append(
        tabs,
        
        list(
          
          tabPanel(
            "Static Plot",
            
            br(),
            
            tags$iframe(
              src = plot_path,
              width = "100%",
              height = "900px",
              style = "border:none;"
            )
          )
        )
      )
    }
    
    do.call(
      tabsetPanel,
      tabs
    )
  })
  
  # ===== PCA =====
  
  output$entry_pca <- renderPlotly({
    
    req(has_pca())
    
    pca_obj <- readRDS(
      current_entry()$pca_path[1]
    )
    
    # =========================
    # CASE 1: DATA FRAME PCA
    # =========================
    
    if (is.data.frame(pca_obj)) {
      
      colnames(pca_obj)[1:2] <- c(
        "PC1",
        "PC2"
      )
      
      # ---------- SAFE METADATA ----------
      
      if (!"name" %in% colnames(pca_obj)) {
        
        if ("rownames" %in% colnames(pca_obj)) {
          
          pca_obj$name <- pca_obj$rownames
          
        } else {
          
          pca_obj$name <- rownames(pca_obj)
        }
      }
      
      if (!"database" %in% colnames(pca_obj)) {
        pca_obj$database <- "Dataset"
      }
      
      # ---------- BIOLOGICAL COLOR GROUP ----------
      
      pca_obj$group <- if (
        "celltype" %in% colnames(pca_obj)
      ) {
        pca_obj$celltype
        
      } else if (
        "generaltissue" %in% colnames(pca_obj)
      ) {
        pca_obj$generaltissue
        
      } else if (
        "type" %in% colnames(pca_obj)
      ) {
        pca_obj$type
        
      } else if (
        "ct" %in% colnames(pca_obj)
      ) {
        pca_obj$ct
        
      } else {
        pca_obj$database
      }
      
      # ---------- HOVER ----------
      
      pca_obj$hover_text <- paste0(
        
        "<b>",
        pca_obj$name,
        "</b>",
        
        if (
          "generaltissue" %in% colnames(pca_obj)
        ) {
          paste0(
            "<br>Tissue: ",
            pca_obj$generaltissue
          )
        } else {
          ""
        },
        
        if (
          "celltype" %in% colnames(pca_obj)
        ) {
          paste0(
            "<br>Cell Type: ",
            pca_obj$celltype
          )
        } else {
          ""
        },
        
        if (
          "type" %in% colnames(pca_obj)
        ) {
          paste0(
            "<br>Type: ",
            pca_obj$type
          )
        } else {
          ""
        },
        
        if (
          "ct" %in% colnames(pca_obj)
        ) {
          paste0(
            "<br>CT: ",
            pca_obj$ct
          )
        } else {
          ""
        }
      )
      
      # ---------- PLOT ----------
      
      plot_ly(
        
        data = pca_obj,
        
        x = ~PC1,
        y = ~PC2,
        
        type = "scatter",
        mode = "markers",
        
        color = ~group,
        
        text = ~hover_text,
        
        hoverinfo = "text",
        
        marker = list(
          size = 7,
          opacity = 0.8
        )
        
      ) %>%
        
        layout(
          
          title = "Principal Component Analysis",
          
          legend = list(
            title = list(
              text = "Biological Group"
            )
          ),
          
          xaxis = list(
            title = "PC1"
          ),
          
          yaxis = list(
            title = "PC2"
          )
        )
      
    } else {
      
      # =========================
      # CASE 2: PRCOMP OBJECT
      # =========================
      
      pc_df <- as.data.frame(
        pca_obj$x
      )
      
      plot_ly(
        
        data = pc_df,
        
        x = ~PC1,
        y = ~PC2,
        
        type = "scatter",
        mode = "markers",
        
        marker = list(
          size = 7,
          opacity = 0.8
        )
        
      ) %>%
        
        layout(
          
          title = "Principal Component Analysis",
          
          xaxis = list(
            title = "PC1"
          ),
          
          yaxis = list(
            title = "PC2"
          )
        )
    }
  })
  
  # ===== VARIANCE PLOT =====
  
  output$variance_plot <- renderPlotly({
    
    req(has_pca())
    
    pca_obj <- readRDS(
      current_entry()$pca_path[1]
    )
    
    if (!is.null(pca_obj$sdev)) {
      
      variance <- pca_obj$sdev^2
      
      pve <- variance / sum(variance)
      
      cumvar <- cumsum(pve)
      
      df <- data.frame(
        PC = seq_along(pve),
        Variance = pve,
        Cumulative = cumvar
      )
      
      plot_ly(
        data = df,
        
        x = ~PC,
        y = ~Variance,
        
        type = "scatter",
        mode = "lines+markers"
        
      ) %>%
        
        layout(
          
          title =
            paste(
              "Variance Explained",
              "<br>",
              which(cumvar >= 0.90)[1],
              " PCs explain 90% variance"
            ),
          
          xaxis = list(
            title = "Principal Component"
          ),
          
          yaxis = list(
            title = "Variance Explained"
          )
        )
    }
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