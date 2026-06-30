library(shiny)
library(bslib)

source("pages/home_page.R")
source("pages/explore_page.R")
source("pages/entry_page.R")
source("pages/pca_page.R")
source("pages/models_page.R")
source("pages/news_page.R")

ui <- navbarPage(

  title = div(
    style = "font-weight:700;",
    "MethylProphet DB"
  ),

  id = "main_navbar",

  theme = bs_theme(
    version = 5,
    primary = "#0F766E",
    secondary = "#164E63"
  ),

  header = tags$head(
    tags$link(
      rel = "stylesheet",
      type = "text/css",
      href = paste0("styles.css?v=", Sys.time())
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