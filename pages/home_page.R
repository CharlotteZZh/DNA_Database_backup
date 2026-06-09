library(shiny)

format_count <- function(x) {
  
  if (is.na(x)) {
    
    return("NA")
  }
  
  if (x >= 1e6) {
    
    return(
      paste0(
        round(
          x / 1e6,
          1
        ),
        "M"
      )
    )
  }
  
  format(
    x,
    big.mark = ",",
    scientific = FALSE
  )
}

normalize_home_tissue <- function(x) {
  
  x <- trimws(
    tolower(
      gsub(
        "_",
        " ",
        x
      )
    )
  )
  
  x[x != ""]
}

home_stats <- function(metadata_path = "data/metadata.csv") {
  
  df <- read.csv(
    metadata_path,
    stringsAsFactors = FALSE
  )
  
  numeric_column <- function(column_name) {
    
    suppressWarnings(
      as.numeric(
        df[[column_name]]
      )
    )
  }
  
  list(
    list(
      value = format_count(
        length(
          unique(
            df$dataset[df$dataset != ""]
          )
        )
      ),
      label = "Datasets"
    ),
    list(
      value = format_count(
        nrow(df)
      ),
      label = "Entries"
    ),
    list(
      value = format_count(
        length(
          unique(
            normalize_home_tissue(df$tissue)
          )
        )
      ),
      label = "Tissues"
    ),
    list(
      value = format_count(
        sum(
          numeric_column("n_level3"),
          na.rm = TRUE
        )
      ),
      label = "Level-3 Cell Types"
    ),
    list(
      value = format_count(
        max(
          numeric_column("n_cpgs"),
          na.rm = TRUE
        )
      ),
      label = "Max CpGs"
    ),
    list(
      value = format_count(
        sum(
          numeric_column("n_samples"),
          na.rm = TRUE
        )
      ),
      label = "Known Samples"
    )
  )
}

stat_card <- function(stat) {
  
  column(
    2,
    
    div(
      class = "stat-card",
      
      h1(stat$value),
      
      h3(stat$label)
    )
  )
}

home_ui <- function() {
  
  fluidPage(
    
    # ===== HERO WRAPPER =====
    
    div(
      
      style = "
        max-width:1200px;
        margin:auto;
      ",
      
      div(
        class = "hero-section",
        
        h1(
          class = "hero-title",
          "predDNAmDB"
        ),
        
        h3(
          class = "hero-subtitle",
          "A database of predicted DNA methylation landscapes"
        ),
        
        br(),
        
        p(
          class = "hero-text",
          
          paste(
            "Explore predicted DNA methylation profiles",
            "across tissues, cell types, cancers,",
            "and transcriptomic technologies."
          )
        ),
        
        br(),
        
        actionButton(
          "start_exploring",
          "Start Exploring",
          class = "main-button"
        )
      )
    ),
    
    br(),
    
    # ===== STATS =====
    
    fluidRow(
      lapply(
        home_stats(),
        stat_card
      )
    ),
    
    br(),
    
    # ===== FEATURE CARDS =====
    
    fluidRow(
      
      column(
        4,
        
        div(
          class = "feature-card",
          
          img(
            src = "images/pca.png",
            
            style = "
              width:100%;
              border-radius:18px;
            "
          ),
          
          br(),
          br(),
          
          h3("Interactive PCA"),
          
          p(
            "Visualize tissue and cell-type methylation landscapes interactively."
          )
        )
      ),
      
      column(
        4,
        
        div(
          class = "feature-card",
          
          img(
            src = "images/umap.png",
            
            style = "
              width:100%;
              border-radius:18px;
            "
          ),
          
          br(),
          br(),
          
          h3("UMAP Embeddings"),
          
          p(
            paste(
              "Explore nonlinear methylation structure",
              "across single-cell and spatial datasets."
            )
          )
        )
      ),
      
      column(
        4,
        
        div(
          class = "feature-card",
          
          img(
            src = "images/workflow.png",
            
            style = "
              width:100%;
              border-radius:18px;
            "
          ),
          
          br(),
          br(),
          
          h3("Prediction Workflow"),
          
          p(
            paste(
              "Reconstruct genome-wide methylation landscapes",
              "from transcriptomic measurements."
            )
          )
        )
      )
    ),
    
    br(),
    br(),
    
    # ===== PUBLICATIONS =====
    
    div(
      class = "feature-card",
      
      h2("Publications"),
      
      br(),
      
      tags$ol(
        
        style = "
      font-size:18px;
      line-height:1.9;
    ",
        
        tags$li(
          
          HTML(
            "
        Huang, X.&#8224;,
        Liu, Q.&#8224;,
        Zhao, Y.,
        Tang, X.,
        Zhou, Y.* and
        Hou, W.*.
        2025.
        "
          ),
          
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
          
          HTML(
            "
        Model: MethylProphet.
        Accepted by
        "
          ),
          
          tags$a(
            
            href = "https://iclr.cc/",
            
            target = "_blank",
            
            "ICLR 2026"
          ),
          
          HTML(
            "
        .
        "
          ),
          
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
}

home_server <- function(
    input,
    output,
    session
) {
  
  observeEvent(
    input$start_exploring,
    {
      
      updateNavbarPage(
        session,
        "main_navbar",
        selected = "Explore"
      )
    }
  )
}
