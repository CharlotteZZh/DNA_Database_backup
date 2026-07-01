library(shiny)

models_ui <- function() {
  
  fluidPage(
    
    div(
      style = "max-width:1400px; margin:auto; padding-top:30px;",
      
      h1(
        style = "
          font-size:56px;
          font-weight:900;
          margin-bottom:20px;
          background: linear-gradient(90deg, #7C3AED, #2563EB);
          -webkit-background-clip: text;
          -webkit-text-fill-color: transparent;
        ",
        "Prediction Models"
      ),
      
      p(
        style = "
          font-size:20px;
          color:#64748B;
          margin-bottom:40px;
          max-width:950px;
        ",
        "MethylProphetDB integrates multiple transcriptome-to-methylome prediction frameworks for large-scale epigenomic reconstruction across tissues, cancers, and single-cell systems."
      ),
      
      # =========================================
      # MODEL CARDS
      # =========================================
      
      fluidRow(
        
        # DREAMLAND
        column(
          4,
          
          div(
            class = "feature-card",
            style = "
              border-top: 8px solid #8B5CF6;
              min-height:650px;
            ",
            
            h2("Dreamland"),
            
            div(
              style="
                display:inline-block;
                background:#F3E8FF;
                color:#6D28D9;
                padding:6px 14px;
                border-radius:999px;
                font-size:13px;
                font-weight:700;
                margin-bottom:18px;
              ",
              "Cross-attention Transformer"
            ),
            
            p(
              "Dreamland is a cross-attention transformer framework for transcriptome-to-methylome prediction. It integrates gene expression profiles with local genomic context to infer CpG-specific methylation states."
            ),
            
            br(),
            
            div(
              style="
                background:#FAF5FF;
                padding:18px;
                border-radius:18px;
              ",
              
              h4("Input"),
              p("RNA-seq + CpG sequence context"),
              
              h4("Output"),
              p("Genome-wide DNA methylation")
            ),
            
            br(),
            
            tags$a(
              href = "#",
              class = "btn btn-primary",
              "Download Model"
            ),
            
            br(), br(),
            
            tags$a(
              href = "#",
              class = "btn btn-outline-primary",
              "Pretrained Weights"
            )
          )
        ),
        
        # METHYLPROPHET
        column(
          4,
          
          div(
            class = "feature-card",
            style = "
              border-top: 8px solid #2563EB;
              min-height:650px;
            ",
            
            h2("MethylProphet"),
            
            div(
              style="
                display:inline-block;
                background:#DBEAFE;
                color:#1D4ED8;
                padding:6px 14px;
                border-radius:999px;
                font-size:13px;
                font-weight:700;
                margin-bottom:18px;
              ",
              "Self-attention Transformer"
            ),
            
            p(
              "MethylProphet is a gene-guided, context-aware transformer model for genome-wide DNA methylation prediction. It infers methylation without requiring partially observed methylation input and integrates transcriptomic signals with CpG sequence context."
            ),
            
            br(),
            
            div(
              style="
                background:#EFF6FF;
                padding:18px;
                border-radius:18px;
              ",
              
              h4("Input"),
              p("RNA-seq + DNA tokenizer"),
              
              h4("Output"),
              p("Whole-genome DNA methylation")
            ),
            
            br(),
            
            tags$a(
              href = "#",
              class = "btn btn-primary",
              "Download Model"
            ),
            
            br(), br(),
            
            tags$a(
              href = "https://github.com/xk-huang/MethylProphet",
              target = "_blank",
              class = "btn btn-outline-primary",
              "GitHub Repository"
            ),
            
            br(), br(),
            
            tags$a(
              href = "#",
              class = "btn btn-outline-primary",
              "Pretrained Weights"
            )
          )
        ),
        
        # RAMP
        column(
          4,
          
          div(
            class = "feature-card",
            style = "
              border-top: 8px solid #F59E0B;
              min-height:650px;
            ",
            
            h2("Ramp"),
            
            div(
              style="
                display:inline-block;
                background:#FEF3C7;
                color:#B45309;
                padding:6px 14px;
                border-radius:999px;
                font-size:13px;
                font-weight:700;
                margin-bottom:18px;
              ",
              "Ridge Regression"
            ),
            
            p(
              "Ramp is a ridge-regression-based baseline model for DNA methylation prediction. It learns linear associations between gene expression and CpG methylation and provides fast, interpretable methylome reconstruction."
            ),
            
            br(),
            
            div(
              style="
                background:#FFFBEB;
                padding:18px;
                border-radius:18px;
              ",
              
              h4("Input"),
              p("RNA-seq, scRNA-seq, spatial transcriptomics"),
              
              h4("Output"),
              p("Predicted methylation beta values")
            ),
            
            br(),
            
            tags$a(
              href = "#",
              class = "btn btn-primary",
              "Download Model"
            )
          )
        )
      ),
      
      br(),
      br(),
      
      # =========================================
      # COMPARISON
      # =========================================
      
      div(
        class = "feature-card",
        style = "
          border-left:8px solid #06B6D4;
        ",
        
        h2("Model Comparison"),
        
        br(),
        
        tags$table(
          class = "table",
          
          tags$thead(
            tags$tr(
              tags$th("Model"),
              tags$th("Architecture"),
              tags$th("Input"),
              tags$th("Output"),
              tags$th("Strength")
            )
          ),
          
          tags$tbody(
            
            tags$tr(
              tags$td("Dreamland"),
              tags$td("Cross-attention Transformer"),
              tags$td("RNA + CpG context"),
              tags$td("DNA methylation"),
              tags$td("Strong nonlinear modeling")
            ),
            
            tags$tr(
              tags$td("Ramp"),
              tags$td("Ridge Regression"),
              tags$td("RNA / scRNA / Spatial"),
              tags$td("DNA methylation"),
              tags$td("Fast and interpretable")
            ),
            
            tags$tr(
              tags$td("MethylProphet"),
              tags$td("Self-attention Transformer"),
              tags$td("RNA + DNA tokenizer"),
              tags$td("Whole-genome DNAm"),
              tags$td("No methylation input required")
            )
          )
        )
      ),
      
      br(),
      
      # =========================================
      # RESOURCES
      # =========================================
      
      div(
        class = "feature-card",
        style = "
          background: linear-gradient(135deg,#F8FAFC,#EFF6FF);
        ",
        
        h2("Resources"),
        
        tags$ul(
          tags$li(
            tags$a(
              "OpenReview Paper",
              href = "https://openreview.net/forum?id=8wQ7Oc08vo",
              target = "_blank"
            )
          ),
          tags$li("Model download links"),
          tags$li("User manuals (coming soon)")
        )
      )
    )
  )
}

models_server <- function(input, output, session) {
}