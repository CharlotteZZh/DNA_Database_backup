library(shiny)

about_ui <- function() {
  
  fluidPage(
    
    div(
      style = "max-width:1400px; margin:auto; padding-top:30px;",
      
      h1(
        style = "
          font-size:56px;
          font-weight:900;
          margin-bottom:20px;
          background: linear-gradient(90deg, #0F766E, #2563EB);
          -webkit-background-clip: text;
          -webkit-text-fill-color: transparent;
        ",
        "About MethylProphetDB"
      ),
      
      p(
        style = "
          font-size:20px;
          color:#64748B;
          margin-bottom:40px;
          max-width:900px;
        ",
        "A large-scale resource for transcriptome-guided DNA methylation reconstruction and epigenomic exploration."
      ),
      
      # =========================================
      # OVERVIEW
      # =========================================
      
      div(
        class = "feature-card",
        style = "border-left:8px solid #14B8A6;",
        
        h2("Overview"),
        
        p(
          "MethylProphetDB is a public database of predicted DNA methylation landscapes reconstructed from transcriptomic data. By applying transcriptome-to-methylome prediction models across public RNA-seq resources, the database enables large-scale exploration of inferred epigenomic states across tissues, cell types, and disease conditions."
        ),
        
        p(
          "The current release integrates predicted methylomes generated from ENCODE, GTEx, TCGA, and ENCODE4 single-cell datasets, together with matched gold-standard methylation profiles when available."
        )
      ),
      
      br(),
      
      # DATA SOURCES
      
      div(
        class = "feature-card",
        style = "border-left:8px solid #3B82F6;",
        
        h2("Data Sources"),
        
        tags$ul(
          tags$li(strong("ENCODE bulk: "), "paired bulk RNA-seq and WGBS across pan-tissue normal samples"),
          tags$li(strong("GTEx: "), "bulk RNA-seq across normal human tissues"),
          tags$li(strong("TCGA: "), "pan-cancer RNA-seq with matched 450K and WGBS cohorts"),
          tags$li(strong("ENCODE4 single-cell: "), "pseudobulked single-cell RNA-seq across tissues and species")
        )
      ),
      
      br(),
      
      # CONTENT
      
      div(
        class = "feature-card",
        style = "border-left:8px solid #8B5CF6;",
        
        h2("Current Database Content"),
        
        tags$ul(
          tags$li("ENCODE bulk: 95 matched samples"),
          tags$li("GTEx: 9 normal tissues"),
          tags$li("TCGA 450K: 9,194 tumor samples"),
          tags$li("TCGA WGBS: 33 tumor samples"),
          tags$li("ENCODE4 single-cell: human and mouse pseudobulk atlases")
        ),
        
        br(),
        
        div(
          style = "
            background:#F8FAFC;
            border-radius:18px;
            padding:18px;
          ",
          
          tags$b("Coverage: "),
          "~27 million CpGs for WGBS datasets and ~408k CpGs for array-based TCGA cohorts."
        )
      ),
      
      br(),
      
      # DATA TYPES
      
      div(
        class = "feature-card",
        style = "border-left:8px solid #F59E0B;",
        
        h2("Available Data Types"),
        
        tags$ul(
          tags$li("Input transcriptomic matrices"),
          tags$li("Predicted DNA methylation matrices"),
          tags$li("Gold-standard experimentally measured methylation"),
          tags$li("Genome browser tracks (bedGraph)"),
          tags$li("Labeled PCA embeddings")
        )
      ),
      
      br(),
      
      # PCA
      
      div(
        class = "feature-card",
        style = "border-left:8px solid #EF4444;",
        
        h2("Interactive PCA Visualization"),
        
        p(
          "Principal component analysis (PCA) is performed on highly variable CpG loci to preserve major methylation structure across samples. Interactive PCA embeddings allow users to compare global epigenomic organization across tissues, cancer types, and pseudobulk single-cell populations."
        ),
        
        div(
          style = "
            margin-top:20px;
            padding:18px;
            border-radius:18px;
            background:linear-gradient(135deg,#FEF2F2,#FFF7ED);
          ",
          
          tags$b("Visualization Layers"),
          tags$ul(
            tags$li("Input RNA"),
            tags$li("Predicted DNAm"),
            tags$li("Gold-standard DNAm")
          )
        )
      ),
      
      br(),
      
      # APPLICATIONS
      
      div(
        class = "feature-card",
        style = "border-left:8px solid #06B6D4;",
        
        h2("Applications"),
        
        tags$ul(
          tags$li("Cross-tissue methylation landscape comparison"),
          tags$li("Pan-cancer epigenomic analysis"),
          tags$li("Single-cell cell-type methylation profiling"),
          tags$li("Transcriptome-guided epigenomic inference"),
          tags$li("Biomarker hypothesis generation")
        )
      ),
      
      br(),
      
      # FUTURE
      
      div(
        class = "feature-card",
        style = "border-left:8px solid #10B981;",
        
        h2("Future Expansion"),
        
        p(
          "Future releases will expand to Human Cell Atlas, Recount2, and spatial transcriptomics datasets, enabling broader coverage of developmental states, tissue organization, and spatial epigenomic architecture."
        )
      ),
      
      br(),
      
      # ACKNOWLEDGEMENTS
      
      div(
        class = "feature-card",
        style = "
          background: linear-gradient(135deg,#F8FAFC,#EFF6FF);
          border: none;
        ",
        
        h2("Acknowledgements"),
        
        p(
          "We acknowledge the....."
        )
      )
    )
  )
}

about_server <- function(input, output, session) {
}