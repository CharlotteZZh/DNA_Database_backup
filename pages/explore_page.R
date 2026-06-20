library(shiny)
library(DT)

explore_ui <- function() {
  
  fluidPage(
    
    div(
      style = "
        max-width:1700px;
        margin:auto;
        padding:25px;
      ",
      
      fluidRow(
        
        # =====================================
        # LEFT FILTER PANEL
        # =====================================
        
        column(
          width = 3,
          
          div(
            class = "feature-card",
            
            h1(
              style = "
                font-size:32px;
                font-weight:700;
                margin-bottom:35px;
                line-height:1.1;
              ",
              
              "Search Database"
            ),
            
            selectInput(
              "dataset_filter",
              "Dataset",
              choices = NULL
            ),
            
            br(),
            
            selectInput(
              "species_filter",
              "Species",
              choices = NULL
            ),
            
            br(),
            
            selectInput(
              "tissue_filter",
              "Tissue",
              choices = NULL
            ),
            
            br(),
            
            selectInput(
              "gene_filter",
              "Input Technology",
              choices = NULL
            ),
            
            br(),
            
            selectInput(
              "assay_filter",
              "Output Technology",
              choices = NULL
            ),
            
            br(),
            br(),
            
            actionButton(
              
              "run_search",
              
              label = tagList(
                
                icon("magnifying-glass"),
                
                " Search Database"
              ),
              
              class = "search-btn"
            )
          )
        ),
        
        # =====================================
        # RIGHT RESULTS TABLE
        # =====================================
        
        column(
          width = 9,
          
          div(
            class = "feature-card",
            
            h2(
              style = "
                font-size:50px;
                font-weight:700;
                margin-bottom:25px;
              ",
              
              "Search Results"
            ),
            
            DTOutput("results_table")
          )
        )
      )
    )
  )
}

explore_server <- function(
    input,
    output,
    session,
    selected_entry
) {
  
  # =====================================
  # LOAD METADATA
  # =====================================
  
  metadata <- reactive({
    
    read.csv(
      "data/metadata.csv",
      stringsAsFactors = FALSE
    )
  })
  
  # =====================================
  # POPULATE FILTERS
  # =====================================
  
  observe({
    
    df <- metadata()
    
    updateSelectInput(
      session,
      "dataset_filter",
      choices = c(
        "All",
        sort(unique(df$dataset))
      ),
      selected = "All"
    )
    
    updateSelectInput(
      session,
      "species_filter",
      choices = c(
        "All",
        sort(unique(df$species))
      ),
      selected = "All"
    )
    
    updateSelectInput(
      session,
      "tissue_filter",
      choices = c(
        "All",
        sort(
          unique(
            trimws(
              tools::toTitleCase(
                tolower(df$tissue)
              )
            )
          )
        )
      ),
      selected = "All"
    )
    
    updateSelectInput(
      session,
      "gene_filter",
      choices = c(
        "All",
        sort(unique(df$gene_expression))
      ),
      selected = "All"
    )
    
    updateSelectInput(
      session,
      "assay_filter",
      choices = c(
        "All",
        sort(unique(df$dna_methylation_assay))
      ),
      selected = "All"
    )
  })
  
  # =====================================
  # FILTER DATA
  # =====================================
  
  filtered_data <- eventReactive(
    
    input$run_search,
    
    {
      
      df <- metadata()
      
      if (input$dataset_filter != "All") {
        
        df <- df[
          df$dataset ==
            input$dataset_filter,
        ]
      }
      
      if (input$species_filter != "All") {
        
        df <- df[
          df$species ==
            input$species_filter,
        ]
      }
      
      if (input$tissue_filter != "All") {
        
        df <- df[
          
          tolower(trimws(df$tissue)) ==
            tolower(trimws(input$tissue_filter)),
          
        ]
      }
      
      if (input$gene_filter != "All") {
        
        df <- df[
          df$gene_expression ==
            input$gene_filter,
        ]
      }
      
      if (input$assay_filter != "All") {
        
        df <- df[
          df$dna_methylation_assay ==
            input$assay_filter,
        ]
      }
      
      df
    },
    
    ignoreNULL = FALSE
  )
  
  # =====================================
  # RESULTS TABLE
  # =====================================
  
  output$results_table <- renderDT({
    
    df <- filtered_data()
    
    # ---------------------------------
    # CREATE CLICKABLE UNIQUE LINKS
    # ---------------------------------
    
    df$link_id <- df$entry_id
    
    df$entry_name <- paste0(
      
      '<a href="#" class="entry-link" data-id="',
      
      df$link_id,
      
      '">',
      
      df$entry_name,
      
      '</a>'
    )
    
    # ---------------------------------
    # DISPLAY TABLE
    # ---------------------------------
    
    display_df <- df[
      ,
      c(
        "entry_name",
        "dataset",
        "species",
        "disease_status",
        "tissue",
        "gene_expression",
        "dna_methylation_assay"
      )
    ]
    
    datatable(
      
      display_df,
      
      escape = FALSE,
      
      rownames = FALSE,
      
      selection = "none",
      
      options = list(
        pageLength = 10,
        scrollX = TRUE
      ),
      
      callback = JS(
        "
        table.on('click', 'a.entry-link', function() {
          
          var clicked_id = $(this).data('id');
          
          Shiny.setInputValue(
            'selected_entry',
            clicked_id,
            {priority: 'event'}
          );
        });
        "
      )
    )
  })
  
  # =====================================
  # OPEN ENTRY PAGE
  # =====================================
  
  observeEvent(
    
    input$selected_entry,
    
    {
      
      clicked_row <- metadata()[
        
        metadata()$entry_id ==
          input$selected_entry,
        
      ][1, ]
      
      selected_entry(clicked_row)
      
      updateNavbarPage(
        session,
        "main_navbar",
        selected = "entry_hidden"
      )
    }
  )
}