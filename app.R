library(shiny)
library(bslib)

source("pages/home_page.R")
source("pages/explore_page.R")
source("pages/entry_page.R")
source("pages/pca_page.R")
source("pages/downloads_page.R")
source("pages/about_page.R")
source("pages/models_page.R")

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
      href = "styles.css"
    )
  ),
  
  tabPanel(
    "Home",
    home_ui()
  ),
  
  tabPanel(
    "Explore",
    explore_ui()
  ),
  
  # hidden entry page
  tabPanel(
    title = "Entry Details",
    value = "entry_hidden",
    entry_ui()
  ),
  
  tabPanel(
    "Models",
    models_ui()
  ),
  
  tabPanel(
    "Downloads",
    downloads_ui()
  ),
  
  tabPanel(
    "About",
    about_ui()
  )
)

server <- function(input, output, session) {
  
  selected_entry <- reactiveVal(NULL)
  
  home_server(input, output, session)
  
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
  
  models_server(input, output, session)
  
  downloads_server(input, output, session)
  
  about_server(input, output, session)
}

shinyApp(ui, server)