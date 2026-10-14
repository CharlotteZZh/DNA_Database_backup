library(shiny)
library(bslib)

source("pages/home_page.R")
source("pages/explore_page.R")
source("pages/entry_page.R")
source("pages/pca_page.R")
source("pages/models_page.R")
source("pages/news_page.R")
source("pages/full_downloads_page.R")
source("pages/manual_page.R")

ui <- navbarPage(

  title = div(
    style = "font-weight:700;",
    "MethylProphet DB"
  ),

  id = "main_navbar",

  theme = bs_theme(
    version = 5,
    primary = "#2470B3",
    secondary = "#164E63"
  ),

  header = tags$head(
    tags$link(
      rel = "stylesheet",
      type = "text/css",
      href = paste0("styles.css?v=", Sys.time())
    ),
    tags$link(
      rel = "stylesheet",
      type = "text/css",
      href = paste0("polish.css?v=", Sys.time())
    ),
    tags$script(
      src = paste0("polish.js?v=", Sys.time()),
      defer = NA
    )
  ),

  # About (old Home + About merged)
  tabPanel(
    "About",
    home_ui()
  ),

  # Datasets (old Explore)
  tabPanel(
    "Datasets",
    explore_ui()
  ),

  # Full-dataset downloads
  tabPanel(
    "Full Datasets",
    full_downloads_ui()
  ),

  # Hidden entry page
  tabPanel(
    title = "Entry Details",
    value = "entry_hidden",
    entry_ui()
  ),

  # Models
  tabPanel(
    "Models",
    models_ui()
  ),

  # News
  tabPanel(
    "News",
    news_ui()
  ),

  # User manual
  tabPanel(
    "User Manual",
    manual_ui()
  ),

  # Site-wide footer with funding acknowledgment
  footer = tags$footer(
    class = "site-footer",
    tags$a(
      href = "https://www.nih.gov",
      target = "_blank",
      rel = "noopener",
      class = "site-footer-logo",
      tags$img(
        src = "images/nih-logo.svg",
        alt = "National Institutes of Health"
      )
    ),
    div(
      class = "site-footer-text",
      p("Supported by the National Institutes of Health (NIH)."),
      p(class = "site-footer-name", "MethylProphet DB")
    )
  )
)

server <- function(input, output, session) {

  selected_entry <- reactiveVal(NULL)

  home_server(
    input,
    output,
    session
  )

  explore_server(
    input,
    output,
    session,
    selected_entry
  )

  entry_server(
    input,
    output,
    session,
    selected_entry
  )

  models_server(
    input,
    output,
    session
  )

  news_server(
    input,
    output,
    session
  )
}

shinyApp(ui, server)
