library(shiny)
library(plotly)


# ============================================================
# SPATIAL DATA SETTINGS
# ============================================================

SPATIAL_HF_BASE <-
  "https://huggingface.co/datasets/dreamland4dnam/spatial/resolve/main"

SPATIAL_EMBRYO_SAMPLES <- c(
  "E11",
  "E13",
  "E11_facial",
  "P21"
)


# ============================================================
# SPATIAL DATA CACHE
# ============================================================

spatial_cache <- new.env(parent = emptyenv())


# ============================================================
# HELPER: SAFE METADATA VALUE
# ============================================================

safe_metadata_value <- function(
    entry,
    column,
    default = NA_character_
) {

  if (!column %in% names(entry)) {
    return(default)
  }

  value <- entry[[column]][1]

  if (
    length(value) == 0 ||
    is.null(value) ||
    is.na(value)
  ) {
    return(default)
  }

  value
}


# ============================================================
# HELPER: SAFE DOWNLOAD BUTTON
# ============================================================

make_download_button <- function(
    href,
    label,
    primary = FALSE
) {

  valid <- !is.null(href) &&
    length(href) > 0 &&
    !is.na(href) &&
    href != ""

  if (!valid) {

    return(
      div(
        class = "coming-soon-box",
        style = "
          width:100%;
          text-align:center;
        ",
        paste(
          label,
          "unavailable."
        )
      )
    )
  }

  tags$a(
    href = href,
    target = "_blank",

    class = if (primary) {
      "btn btn-primary"
    } else {
      "btn btn-secondary"
    },

    style = "width:100%;",

    label
  )
}


# ============================================================
# DETERMINE WHETHER ENTRY IS SPATIAL
# ============================================================

is_spatial_entry_data <- function(entry) {

  if (is.null(entry)) {
    return(FALSE)
  }

  dataset <- tolower(
    trimws(
      as.character(
        safe_metadata_value(
          entry,
          "dataset",
          ""
        )
      )
    )
  )

  tissue <- tolower(
    trimws(
      as.character(
        safe_metadata_value(
          entry,
          "tissue",
          ""
        )
      )
    )
  )

  entry_name <- tolower(
    trimws(
      as.character(
        safe_metadata_value(
          entry,
          "entry_name",
          ""
        )
      )
    )
  )

  grepl("spatial", dataset) ||
    grepl("spatial", tissue) ||
    grepl("spatial", entry_name)
}


# ============================================================
# SPATIAL SAMPLE NAMES
# ============================================================

get_spatial_samples <- function(entry) {

  if (is.null(entry)) {
    return(character(0))
  }

  tissue <- tolower(
    trimws(
      as.character(
        safe_metadata_value(
          entry,
          "tissue",
          ""
        )
      )
    )
  )

  entry_name <- tolower(
    trimws(
      as.character(
        safe_metadata_value(
          entry,
          "entry_name",
          ""
        )
      )
    )
  )

  # Mouse embryo = one database entry
  # containing four spatial samples/slides.

  if (
    grepl("embryo", tissue) ||
    grepl("embryo", entry_name)
  ) {

    return(
      SPATIAL_EMBRYO_SAMPLES
    )
  }

  # Mouse pancreas will be added here once
  # its processed data are connected to the
  # same Hugging Face structure.

  character(0)
}


# ============================================================
# READ SPATIAL VMR INDEX
# ============================================================

read_spatial_index <- function(sample) {

  cache_name <- paste0(
    "index_",
    sample
  )

  if (
    exists(
      cache_name,
      envir = spatial_cache
    )
  ) {

    return(
      get(
        cache_name,
        envir = spatial_cache
      )
    )
  }

  hf_url <- paste0(
    SPATIAL_HF_BASE,
    "/",
    sample,
    "/vmr_index.tsv.gz"
  )

  tmp <- tempfile(
    fileext = ".tsv.gz"
  )

  tryCatch(

    {

      download.file(
        hf_url,
        tmp,
        mode = "wb",
        method = "libcurl",
        quiet = TRUE
      )

      index <- read.delim(
        gzfile(tmp),
        stringsAsFactors = FALSE
      )

    },

    error = function(e) {

      unlink(tmp)

      stop(
        paste(
          "Could not load spatial VMR index for",
          sample,
          ":",
          conditionMessage(e)
        )
      )
    }
  )

  unlink(tmp)

  assign(
    cache_name,
    index,
    envir = spatial_cache
  )

  index
}


# ============================================================
# READ SPATIAL METADATA
# ============================================================

read_spatial_metadata <- function(sample) {

  cache_name <- paste0(
    "metadata_",
    sample
  )

  if (
    exists(
      cache_name,
      envir = spatial_cache
    )
  ) {

    return(
      get(
        cache_name,
        envir = spatial_cache
      )
    )
  }

  hf_url <- paste0(
    SPATIAL_HF_BASE,
    "/",
    sample,
    "/metadata.tsv.gz"
  )

  tmp <- tempfile(
    fileext = ".tsv.gz"
  )

  tryCatch(

    {

      download.file(
        hf_url,
        tmp,
        mode = "wb",
        method = "libcurl",
        quiet = TRUE
      )

      metadata <- read.delim(
        gzfile(tmp),
        stringsAsFactors = FALSE
      )

    },

    error = function(e) {

      unlink(tmp)

      stop(
        paste(
          "Could not load spatial metadata for",
          sample,
          ":",
          conditionMessage(e)
        )
      )
    }
  )

  unlink(tmp)

  assign(
    cache_name,
    metadata,
    envir = spatial_cache
  )

  metadata
}


# ============================================================
# READ ONE SPATIAL CHUNK
# ============================================================

read_spatial_chunk <- function(
    sample,
    chunk_number
) {

  cache_name <- paste0(
    "chunk_",
    sample,
    "_",
    chunk_number
  )

  if (
    exists(
      cache_name,
      envir = spatial_cache
    )
  ) {

    return(
      get(
        cache_name,
        envir = spatial_cache
      )
    )
  }

  chunk_file <- sprintf(
    "chunk_%04d.rds",
    as.integer(chunk_number)
  )

  hf_url <- paste0(
    SPATIAL_HF_BASE,
    "/",
    sample,
    "/",
    chunk_file
  )

  tmp <- tempfile(
    fileext = ".rds"
  )

  tryCatch(

    {

      download.file(
        hf_url,
        tmp,
        mode = "wb",
        method = "libcurl",
        quiet = TRUE
      )

      chunk <- readRDS(tmp)

    },

    error = function(e) {

      unlink(tmp)

      stop(
        paste(
          "Could not load spatial chunk for",
          sample,
          ":",
          conditionMessage(e)
        )
      )
    }
  )

  unlink(tmp)

  assign(
    cache_name,
    chunk,
    envir = spatial_cache
  )

  chunk
}


# ============================================================
# GET ONE VMR FOR ONE SAMPLE
# ============================================================

get_spatial_feature <- function(
    sample,
    feature,
    source = "predicted"
) {

  index <- read_spatial_index(
    sample
  )

  hit <- index[
    index$vmr == feature,
    ,
    drop = FALSE
  ]

  if (
    nrow(hit) == 0
  ) {

    return(NULL)
  }

  chunk <- read_spatial_chunk(
    sample = sample,
    chunk_number = hit$chunk[1]
  )

  feature_index <-
    as.integer(
      hit$index_in_chunk[1]
    )

  values <- chunk[[source]][
    feature_index,
    ,
    drop = TRUE
  ]

  values <- as.numeric(
    values
  )

  metadata <- read_spatial_metadata(
    sample
  )

  if (
    length(values) != nrow(metadata)
  ) {

    stop(
      paste(
        "Number of DNAm values does not match",
        "the number of spatial spots for",
        sample
      )
    )
  }

  metadata$value <- values

  metadata
}

# ============================================================
# GET SHARED COLOR SCALE FOR ONE VMR
# ============================================================

get_spatial_color_range <- function(
    feature,
    source
) {

  all_values <- lapply(

    SPATIAL_EMBRYO_SAMPLES,

    function(sample) {

      dat <- get_spatial_feature(
        sample = sample,
        feature = feature,
        source = source
      )

      if (is.null(dat)) {
        return(numeric(0))
      }

      dat$value[
        is.finite(dat$value)
      ]
    }
  )

  all_values <- unlist(
    all_values,
    use.names = FALSE
  )

  if (
    length(all_values) == 0
  ) {

    return(
      c(0, 1)
    )
  }

  # Use the 2nd and 98th percentiles so that
  # a few extreme spots do not flatten the
  # rest of the spatial variation.

  color_range <- quantile(
    all_values,
    probs = c(
      0.02,
      0.98
    ),
    na.rm = TRUE,
    names = FALSE
  )

  # Make sure the range is valid.

  if (
    !is.finite(color_range[1]) ||
    !is.finite(color_range[2]) ||
    color_range[1] >= color_range[2]
  ) {

    color_range <- range(
      all_values,
      na.rm = TRUE
    )
  }

  # Keep methylation within its natural
  # beta-value range.

  color_range[1] <- max(
    0,
    color_range[1]
  )

  color_range[2] <- min(
    1,
    color_range[2]
  )

  # If there is essentially no variation,
  # fall back to 0–1.

  if (
    color_range[1] >= color_range[2]
  ) {

    color_range <- c(
      0,
      1
    )
  }

  color_range
}



# ============================================================
# BUILD SPATIAL PLOT
# ============================================================

build_spatial_plot <- function(
    sample,
    feature,
    source,
    color_range = NULL
) {

  dat <- get_spatial_feature(
    sample = sample,
    feature = feature,
    source = source
  )

  if (
    is.null(dat)
  ) {

    return(

      plot_ly() %>%

        layout(

          xaxis = list(
            visible = FALSE
          ),

          yaxis = list(
            visible = FALSE
          ),

          annotations = list(

            list(

              text = paste(
                "This VMR is not available in",
                sample
              ),

              x = 0.5,
              y = 0.5,

              xref = "paper",
              yref = "paper",

              showarrow = FALSE,

              font = list(
                size = 16
              )
            )
          )
        )
    )
  }


  # ----------------------------------------------------------
  # Calculate color range if one was not supplied
  # ----------------------------------------------------------

  if (
    is.null(color_range)
  ) {

    color_range <-
      get_spatial_color_range(
        feature = feature,
        source = source
      )
  }


  source_label <- if (
    source == "predicted"
  ) {

    "Predicted DNAm"

  } else {

    "Measured DNAm"
  }


  # ----------------------------------------------------------
  # Hover text
  # ----------------------------------------------------------

  hover_text <- paste0(

    "Spot: ",

    dat$spot,

    "<br>",

    source_label,

    ": ",

    round(
      dat$value,
      3
    )
  )


  # ----------------------------------------------------------
  # Plot
  # ----------------------------------------------------------

  plot_ly(

    x = dat$imagecol,

    y = dat$imagerow,

    type = "scatter",

    mode = "markers",

    marker = list(

      size = 7,

      color = dat$value,

      colorscale = "Viridis",

      # IMPORTANT:
      # Every slide gets the SAME feature-specific
      # color scale.

      cmin = color_range[1],

      cmax = color_range[2],

      colorbar = list(

        title = "DNAm",

        thickness = 18
      ),

      showscale = TRUE
    ),

    text = hover_text,

    hoverinfo = "text"

  ) %>%

    layout(

      title = list(
        text = sample,
        x = 0
      ),

      xaxis = list(

        title = "",

        showgrid = FALSE,

        zeroline = FALSE,

        visible = FALSE
      ),

      yaxis = list(

        title = "",

        showgrid = FALSE,

        zeroline = FALSE,

        visible = FALSE,

        autorange = "reversed",

        scaleanchor = "x",

        scaleratio = 1
      ),

      plot_bgcolor = "white",

      paper_bgcolor = "white",

      margin = list(

        l = 10,

        r = 10,

        b = 10,

        t = 45
      )
    )
}


# ============================================================
# UI
# ============================================================

entry_ui <- function() {

  fluidPage(
    class = "site-page entry-page",


    # Hidden reactive output used to switch
    # between spatial and standard entries.

    tags$span(
      style = "display:none;",

      textOutput(
        "spatial_mode"
      )
    ),


    div(
      style = "
        max-width:1600px;
        margin:auto;
        padding-top:25px;
      ",

      fluidRow(

        # ======================================================
        # LEFT COLUMN
        # ======================================================

        column(
          4,

          div(
            class = "feature-card",

            uiOutput(
              "metadata_table"
            )
          ),

          br(),

          div(
            class = "feature-card",

            h2(
              "Dataset Description"
            ),

            p(
              style = "
                font-size:16px;
                line-height:1.7;
                color:#475569;
                margin-bottom:0;
              ",

              textOutput(
                "dataset_notes"
              )
            )
          ),

          br(),

          div(
            class = "feature-card",

            h2(
              style = "
                font-size:24px;
                font-weight:600;
              ",

              "Downloads (cancer/cell/tissue-specific)"
            ),

            br(),

            uiOutput(
              "prediction_download"
            ),

            br(),
            br(),

            uiOutput(
              "source_download"
            ),

            br(),
            br(),

            uiOutput(
              "rna_download"
            ),

            br(),
            br(),

            uiOutput(
              "track_download"
            )
          )
        ),


        # ======================================================
        # RIGHT COLUMN
        # ======================================================

        column(
          8,


          # ====================================================
          # SPATIAL ENTRY
          # ====================================================

          conditionalPanel(

            condition =
              "output.spatial_mode === 'true'",


            div(
              class = "feature-card",

              h2(
                "Spatial DNA Methylation",

                style = "
                  font-size:32px;
                  font-weight:700;
                  margin-bottom:12px;
                "
              ),

              p(
                style = "
                  font-size:16px;
                  line-height:1.6;
                  color:#64748B;
                ",

                "Select a methylation feature to visualize its spatial distribution across samples."
              ),

              br(),


              # IMPORTANT:
              #
              # This input is STATIC.
              #
              # It is not created inside renderUI().
              # This makes server-side selectize reliable.

              selectizeInput(

                "spatial_feature",

                "Select VMR",

                choices = NULL,

                selected = NULL,

                options = list(

                  placeholder =
                    "Search for a VMR...",

                  maxOptions = 50,

                  preload = FALSE
                )
              ),


              radioButtons(

                "spatial_source",

                "Methylation",

                choices = c(

                  "Predicted DNAm" =
                    "predicted",

                  "Measured DNAm" =
                    "observed"
                ),

                selected =
                  "predicted",

                inline = TRUE
              )
            ),


            br(),


            div(
              class = "feature-card",

              h3(
                "Spatial distribution",

                style = "
                  font-size:24px;
                  font-weight:700;
                  margin-bottom:20px;
                "
              ),

              uiOutput(
                "spatial_plots"
              )
            )
          ),


          # ====================================================
          # STANDARD ENTRY
          # ====================================================

          conditionalPanel(

            condition =
              "output.spatial_mode !== 'true'",


            div(
              class = "feature-card",

              h2(
                "Principal Component Analysis"
              ),

              uiOutput(
                "pca_tabs"
              )
            ),

            br(),


            div(
              class = "feature-card",

              h2(
                "UMAP Embeddings"
              ),

              uiOutput(
                "umap_tabs"
              )
            )
          )
        )
      )
    )
  )
}


# ============================================================
# SERVER
# ============================================================

entry_server <- function(
    input,
    output,
    session,
    selected_entry
) {


  # ==========================================================
  # CURRENT ENTRY
  # ==========================================================

  current_entry <- reactive({

    req(
      selected_entry()
    )

    selected_entry()
  })


  # ==========================================================
  # SPATIAL MODE
  # ==========================================================

  is_spatial_entry <- reactive({

    req(
      current_entry()
    )

    is_spatial_entry_data(
      current_entry()
    )
  })


  output$spatial_mode <- renderText({

    if (
      is_spatial_entry()
    ) {

      "true"

    } else {

      "false"
    }
  })


  outputOptions(
    output,
    "spatial_mode",
    suspendWhenHidden = FALSE
  )


  # ==========================================================
  # METADATA
  # ==========================================================

  output$metadata_table <- renderUI({

    entry <- current_entry()

    spatial <- is_spatial_entry()


    tissue <- safe_metadata_value(
      entry,
      "tissue",
      "Unknown"
    )

    dataset <- safe_metadata_value(
      entry,
      "dataset",
      "Unknown"
    )

    species <- safe_metadata_value(
      entry,
      "species",
      ""
    )

    disease_status <- safe_metadata_value(
      entry,
      "disease_status",
      ""
    )

    gene_expression <- safe_metadata_value(
      entry,
      "gene_expression",
      ""
    )

    methylation_assay <- safe_metadata_value(
      entry,
      "dna_methylation_assay",
      ""
    )

    n_samples <- safe_metadata_value(
      entry,
      "n_samples_per_tissue",
      NA
    )

    n_total <- safe_metadata_value(
      entry,
      "n_samples_total",
      NA
    )

    n_cpgs <- safe_metadata_value(
      entry,
      "n_cpgs_total",
      NA
    )


    div(

      # ======================================================
      # TITLE
      # ======================================================

      h2(
        style = "
          font-size:38px;
          font-weight:800;
          margin-bottom:4px;
          color:#0F172A;
          line-height:1.1;
        ",

        tools::toTitleCase(
          gsub(
            "_",
            " ",
            tissue
          )
        )
      ),


      p(
        style = "
          font-size:16px;
          color:#64748B;
          margin-bottom:4px;
        ",

        gsub(
          "_",
          " ",
          dataset
        )
      ),


      p(
        style = "
          font-size:14px;
          color:#94A3B8;
          margin-bottom:14px;
        ",

        paste(
          species,
          "·",
          disease_status
        )
      ),


      # ======================================================
      # TECHNOLOGY BADGE
      # ======================================================

      div(
        style = "
          display:inline-block;
          padding:8px 16px;
          border-radius:999px;
          background:#F3E8FF;
          color:#6D28D9;
          font-size:14px;
          font-weight:700;
          margin-bottom:18px;
        ",

        paste(
          gene_expression,
          "→",
          methylation_assay
        )
      ),


      # ======================================================
      # ENTRY STATS
      # ======================================================

      div(
        class = "mini-meta-card",

        h4(
          "Entry"
        ),

        div(
          class = "meta-grid",


          # Tissue

          div(
            class = "meta-stat",

            h5(
              "Tissue"
            ),

            p(
              tools::toTitleCase(
                gsub(
                  "_",
                  " ",
                  tissue
                )
              )
            )
          ),


          # Samples

          div(
            class = "meta-stat",

            h5(
              "Samples"
            ),

            p(
              if (
                is.na(n_samples)
              ) {
                "N/A"
              } else {
                format(
                  n_samples,
                  big.mark = ","
                )
              }
            )
          ),


          # Spatial feature type

          div(
            class = "meta-stat",

            h5(
              if (spatial) {
                "Feature Type"
              } else {
                "Number of CpGs"
              }
            ),

            p(

              if (spatial) {

                methylation_assay

              } else if (
                is.na(n_cpgs)
              ) {

                "N/A"

              } else {

                format(
                  n_cpgs,
                  big.mark = ","
                )
              }
            )
          ),


          # Analysis

          div(
            class = "meta-stat",

            h5(
              if (spatial) {
                "Analysis"
              } else {
                "Number of Genes"
              }
            ),

            p(

              if (spatial) {

                "Spatial DNAm"

              } else {

                n_genes <- safe_metadata_value(
                  entry,
                  "n_genes_total",
                  NA
                )

                if (
                  is.na(n_genes) ||
                  n_genes == ""
                ) {

                  "N/A"

                } else {

                  format(
                    n_genes,
                    big.mark = ","
                  )
                }
              }
            )
          )
        )
      ),


      div(
        style = "height:6px;"
      ),


      # ======================================================
      # DATASET STATS
      # ======================================================

      div(
        class = "mini-meta-card",

        h4(
          "Dataset"
        ),

        div(
          class = "meta-grid",


          div(
            class = "meta-stat",

            h5(
              "Total Samples"
            ),

            p(

              if (
                is.na(n_total)
              ) {

                "N/A"

              } else {

                format(
                  n_total,
                  big.mark = ","
                )
              }
            )
          ),


          div(
            class = "meta-stat",

            h5(
              if (spatial) {
                "Feature Type"
              } else {
                "PCA"
              }
            ),

            p(

              if (spatial) {

                methylation_assay

              } else {

                "Pan-dataset"
              }
            )
          ),


          div(
            class = "meta-stat",

            h5(
              "Input"
            ),

            p(
              gene_expression
            )
          ),


          div(
            class = "meta-stat",

            h5(
              "Output"
            ),

            p(
              methylation_assay
            )
          )
        )
      )
    )
  })


  # ==========================================================
  # DATASET DESCRIPTION
  # ==========================================================

  output$dataset_notes <- renderText({

    if (
      is_spatial_entry()
    ) {

      paste(

        "This spatial entry contains spatially resolved DNA methylation measurements and Ramp-predicted DNA methylation.",

        "Select a methylation feature to visualize its spatial distribution across the available spatial samples.",

        "Spatial RNA expression is not displayed in this visualization."
      )

    } else {

      paste(

        "This entry represents a tissue- or cohort-specific subset of the",

        current_entry()$dataset[1],

        "dataset. Interactive PCA and UMAP embeddings are computed at the full dataset level to preserve global biological structure and enable cross-tissue or cross-cohort comparisons."
      )
    }
  })


  # ==========================================================
  # LOAD SHARED SPATIAL VMRs
  # ==========================================================

  observeEvent(

    current_entry(),

    {

      # Clear the old spatial selection whenever
      # the user switches entries.

      updateSelectizeInput(

        session,

        "spatial_feature",

        choices = NULL,

        selected = NULL,

        server = TRUE
      )


      req(
        is_spatial_entry()
      )


      samples <-
        get_spatial_samples(
          current_entry()
        )


      req(
        length(samples) > 0
      )


      # ------------------------------------------------------
      # Get VMRs from each slide
      # ------------------------------------------------------

      feature_lists <- lapply(

        samples,

        function(sample) {

          index <-
            read_spatial_index(
              sample
            )

          unique(
            index$vmr
          )
        }
      )


      # ------------------------------------------------------
      # Keep ONLY VMRs present in every slide
      # ------------------------------------------------------

      common_vmrs <- Reduce(
        intersect,
        feature_lists
      )


      common_vmrs <- sort(
        unique(
          common_vmrs
        )
      )


      # ------------------------------------------------------
      # Server-side selectize
      #
      # The VMRs remain on the server instead of being
      # rendered as 75k–100k browser options.
      # ------------------------------------------------------

      updateSelectizeInput(

        session,

        "spatial_feature",

        choices =
          common_vmrs,

        selected =
          NULL,

        server =
          TRUE,

        options = list(

          placeholder =
            "Search for a VMR...",

          maxOptions =
            50
        )
      )
    },

    ignoreInit = FALSE
  )


  # ==========================================================
  # SPATIAL PLOT UI
  # ==========================================================

  output$spatial_plots <- renderUI({

    req(
      is_spatial_entry()
    )


    feature <-
      input$spatial_feature


    # --------------------------------------------------------
    # Nothing selected yet
    # --------------------------------------------------------

    if (
      is.null(feature) ||
      length(feature) == 0 ||
      feature == ""
    ) {

      return(

        div(

          style = "
            padding:50px 20px;
            text-align:center;
            color:#64748B;
            font-size:16px;
          ",

          "Search for and select a VMR above to view its spatial distribution."
        )
      )
    }


    # --------------------------------------------------------
    # Four slides
    # --------------------------------------------------------

    tagList(

      fluidRow(

        column(
          6,

          h4(
            "E11",

            style = "
              font-weight:700;
              margin-bottom:10px;
            "
          ),

          plotlyOutput(
            "spatial_E11",
            height = "450px"
          )
        ),


        column(
          6,

          h4(
            "E13",

            style = "
              font-weight:700;
              margin-bottom:10px;
            "
          ),

          plotlyOutput(
            "spatial_E13",
            height = "450px"
          )
        )
      ),


      br(),


      fluidRow(

        column(
          6,

          h4(
            "E11 Facial",

            style = "
              font-weight:700;
              margin-bottom:10px;
            "
          ),

          plotlyOutput(
            "spatial_E11_facial",
            height = "450px"
          )
        ),


        column(
          6,

          h4(
            "P21",

            style = "
              font-weight:700;
              margin-bottom:10px;
            "
          ),

          plotlyOutput(
            "spatial_P21",
            height = "450px"
          )
        )
      )
    )
  })


  # ============================================================
# SPATIAL PLOTS
# ============================================================

for (
  sample in SPATIAL_EMBRYO_SAMPLES
) {

  local({

    this_sample <- sample

    output[[
      paste0(
        "spatial_",
        this_sample
      )
    ]] <- renderPlotly({

      req(
        is_spatial_entry()
      )

      req(
        input$spatial_feature
      )

      req(
        input$spatial_feature != ""
      )

      req(
        input$spatial_source
      )


      # ------------------------------------------------------
      # Calculate ONE color scale for the selected VMR
      # across ALL FOUR embryo slides.
      # ------------------------------------------------------

      color_range <-
        get_spatial_color_range(

          feature =
            input$spatial_feature,

          source =
            input$spatial_source
        )


      build_spatial_plot(

        sample =
          this_sample,

        feature =
          input$spatial_feature,

        source =
          input$spatial_source,

        color_range =
          color_range
      )
    })
  })
}


  # ==========================================================
  # PCA TABS
  # ==========================================================

  output$pca_tabs <- renderUI({

    req(
      !is_spatial_entry()
    )


    tabsetPanel(

      tabPanel(

        "Input RNA",

        plotlyOutput(
          "entry_pca_input",
          height = "500px"
        )
      ),


      tabPanel(

        "Predicted DNAm",

        plotlyOutput(
          "entry_pca_pred",
          height = "500px"
        )
      ),


      tabPanel(

        "Gold-standard DNAm",

        plotlyOutput(
          "entry_pca_gold",
          height = "500px"
        )
      ),


      tabPanel(

        "Static Plot",

        br(),

        if (

          "plot_path" %in%
            names(current_entry()) &&

          !is.na(
            current_entry()$plot_path[1]
          ) &&

          current_entry()$plot_path[1] != ""
        ) {

          tags$iframe(

            src =
              current_entry()$plot_path[1],

            width =
              "100%",

            height =
              "900px",

            style =
              "border:none;"
          )

        } else {

          div(

            class =
              "coming-soon-box",

            "Static plot unavailable."
          )
        }
      )
    )
  })


  # ==========================================================
  # UMAP TABS
  # ==========================================================

  output$umap_tabs <- renderUI({

    req(
      !is_spatial_entry()
    )


    tabsetPanel(

      tabPanel(

        "Input RNA",

        plotlyOutput(
          "entry_umap_input",
          height = "500px"
        )
      ),


      tabPanel(

        "Predicted DNAm",

        plotlyOutput(
          "entry_umap_pred",
          height = "500px"
        )
      ),


      tabPanel(

        "Gold-standard DNAm",

        plotlyOutput(
          "entry_umap_gold",
          height = "500px"
        )
      ),


      tabPanel(

        "Static Plot",

        br(),

        if (

          "umap_path" %in%
            names(current_entry()) &&

          !is.na(
            current_entry()$umap_path[1]
          ) &&

          current_entry()$umap_path[1] != ""
        ) {

          tags$iframe(

            src =
              current_entry()$umap_path[1],

            width =
              "100%",

            height =
              "900px",

            style =
              "border:none;"
          )

        } else {

          div(

            class =
              "coming-soon-box",

            "Static plot unavailable."
          )
        }
      )
    )
  })


  # ==========================================================
  # PCA PLOTS
  # ==========================================================

  output$entry_pca_input <- renderPlotly({

    req(
      !is_spatial_entry()
    )


    build_type_pca(

      current_entry()$input_pca[1],

      current_entry()$tissue[1],

      "Input RNA — PCA"
    )
  })


  output$entry_pca_pred <- renderPlotly({

    req(
      !is_spatial_entry()
    )


    build_type_pca(

      current_entry()$predicted_pca[1],

      current_entry()$tissue[1],

      "Predicted DNAm — PCA"
    )
  })


  output$entry_pca_gold <- renderPlotly({

    req(
      !is_spatial_entry()
    )


    build_type_pca(

      current_entry()$output_pca[1],

      current_entry()$tissue[1],

      "Gold-standard DNAm — PCA"
    )
  })


  # ==========================================================
  # UMAP PLOTS
  # ==========================================================

  output$entry_umap_input <- renderPlotly({

    req(
      !is_spatial_entry()
    )


    build_type_umap(

      current_entry()$input_umap[1],

      current_entry()$tissue[1],

      "Input RNA — UMAP"
    )
  })


  output$entry_umap_pred <- renderPlotly({

    req(
      !is_spatial_entry()
    )


    build_type_umap(

      current_entry()$predicted_umap[1],

      current_entry()$tissue[1],

      "Predicted DNAm — UMAP"
    )
  })


  output$entry_umap_gold <- renderPlotly({

    req(
      !is_spatial_entry()
    )


    build_type_umap(

      current_entry()$output_umap[1],

      current_entry()$tissue[1],

      "Gold-standard DNAm — UMAP"
    )
  })


  # ==========================================================
  # DOWNLOADS
  # ==========================================================

  output$prediction_download <- renderUI({

    href <- safe_metadata_value(
      current_entry(),
      "predicted_download_tissue",
      ""
    )

    make_download_button(
      href,
      "Download Predicted DNAm",
      primary = TRUE
    )
  })


  output$source_download <- renderUI({

    href <- safe_metadata_value(
      current_entry(),
      "goldstandard_download_tissue",
      ""
    )

    make_download_button(
      href,
      "Download Gold-standard DNAm"
    )
  })


  output$rna_download <- renderUI({

    href <- safe_metadata_value(
      current_entry(),
      "input_download_tissue",
      ""
    )

    make_download_button(
      href,
      "Download Input RNA"
    )
  })


  output$track_download <- renderUI({

    href <- safe_metadata_value(
      current_entry(),
      "track_download_tissue",
      ""
    )

    make_download_button(
      href,
      "Download DNAm Tracks"
    )
  })
}