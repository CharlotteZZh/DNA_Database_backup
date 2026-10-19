library(shiny)

# Media lives in www/manual/. Screenshots are still images; "live" figures are
# looping animated WebP walkthroughs with a still poster shown when paused.

# Bold text without the whitespace htmltools adds around inline tags, so
# punctuation can follow directly ("Dataset, Species").
manual_bold <- function(...) tags$strong(..., .noWS = "outside")

manual_shot <- function(file, alt, caption = NULL, narrow = FALSE) {
  tags$figure(
    class = paste("manual-media", if (narrow) "is-narrow"),
    tags$a(
      href = paste0("manual/", file),
      target = "_blank",
      rel = "noopener",
      title = "Open full-size image",
      tags$img(
        src = paste0("manual/", file),
        alt = alt,
        loading = "lazy"
      )
    ),
    if (!is.null(caption)) tags$figcaption(caption)
  )
}

manual_live <- function(name, alt, caption = NULL) {
  tags$figure(
    class = "manual-media manual-live",
    tags$button(
      type = "button",
      class = "manual-live-toggle",
      `aria-label` = paste("Play or pause animation:", alt),
      `aria-pressed` = "false",
      tags$img(
        src = paste0("manual/", name, "-poster.jpg"),
        `data-poster` = paste0("manual/", name, "-poster.jpg"),
        `data-anim` = paste0("manual/", name, ".webp"),
        alt = alt,
        loading = "lazy"
      ),
      tags$span(class = "manual-live-badge", tags$span(class = "manual-live-dot"), "Live"),
      tags$span(class = "manual-live-icon", `aria-hidden` = "true")
    ),
    if (!is.null(caption)) tags$figcaption(caption)
  )
}

manual_step <- function(id, number, title, ...) {
  tags$section(
    id = id,
    class = "feature-card manual-step",
    div(
      class = "manual-step-head",
      span(class = "manual-step-number", number),
      h2(title)
    ),
    ...
  )
}

manual_ui <- function() {

  fluidPage(
    class = "site-page manual-page",

    div(
      style = "max-width:1400px; margin:auto; padding-top:30px;",

      div(
        class = "page-heading",
        h1("User Manual"),
        p(
          "A visual guide to DreamlandDB: finding datasets, reading entry pages, ",
          "exploring PCA, UMAP and spatial views, and downloading data and models."
        )
      ),

      div(
        class = "manual-layout",

        tags$nav(
          class = "manual-toc",
          `aria-label` = "User manual contents",
          h2("Contents"),
          tags$ol(
            tags$li(tags$a(href = "#manual-start", "Getting around")),
            tags$li(tags$a(href = "#manual-search", "Searching datasets")),
            tags$li(tags$a(href = "#manual-open", "Opening an entry")),
            tags$li(tags$a(href = "#manual-entry", "Reading an entry page")),
            tags$li(tags$a(href = "#manual-plots", "PCA and UMAP plots")),
            tags$li(tags$a(href = "#manual-spatial", "Spatial entries")),
            tags$li(tags$a(href = "#manual-downloads", "Downloading data")),
            tags$li(tags$a(href = "#manual-models", "Prediction models")),
            tags$li(tags$a(href = "#manual-tips", "Tips"))
          ),
          p(
            class = "manual-toc-note",
            span(class = "manual-live-dot"),
            " Live figures play when scrolled into view. Click one to pause or replay it."
          )
        ),

        div(
          class = "manual-content",

          manual_step(
            "manual-start", "1", "Getting around",
            p(
              "Every page shares the navigation bar at the top. ",
              manual_bold("About"), " introduces the database, ",
              manual_bold("Datasets"), " is where you search entries, ",
              manual_bold("Full Datasets"), " lists whole-dataset downloads, ",
              manual_bold("Models"), " describes the prediction models, and ",
              manual_bold("News"), " lists updates. Clicking ",
              manual_bold("Explore Datasets"), " on the About page also takes you to the search."
            ),
            manual_shot(
              "01-navigation.jpg",
              "DreamlandDB About page with the navigation bar and Explore Datasets button highlighted",
              "1: navigation bar. 2: animation pause button. 3: Explore Datasets shortcut."
            )
          ),

          manual_step(
            "manual-search", "2", "Searching datasets",
            p(
              "On the ", manual_bold("Datasets"), " page, narrow the catalog with the filters on the left: ",
              manual_bold("Dataset"), ", ", manual_bold("Species"), ", ", manual_bold("Tissue"), ", ",
              manual_bold("Input Technology"), " (for example RNA-seq or single-cell RNA-seq) and ",
              manual_bold("Output Technology"), " (WGBS, 450K, EPIC and others). Then click ",
              manual_bold("Search Database"), ". The results table updates to show the matching entries."
            ),
            manual_live(
              "02-search",
              "Choosing the TCGA dataset filter and clicking Search Database to update the results table",
              "Filtering to TCGA, then running the search."
            ),
            p(
              "The table itself can be sorted by clicking any column header, searched with the ",
              manual_bold("Search"), " box above it, and paged with the controls underneath."
            ),
            manual_shot(
              "03-datasets.jpg",
              "Datasets page with filters, search button, table search box and an entry link highlighted",
              "1: filters. 2: Search Database. 3: quick search within the table. 4: entry name links. 5: pages."
            )
          ),

          manual_step(
            "manual-open", "3", "Opening an entry",
            p(
              "Each row is one entry: a tissue, cancer type or cell type within a dataset. ",
              "Click the blue entry name to open its page. A short loading message appears ",
              "while the entry's plots are prepared."
            ),
            manual_live(
              "04-open-entry",
              "Clicking an entry name in the results table, which opens the entry page",
              "Opening GTEx_Brain_bulk from the results table."
            )
          ),

          manual_step(
            "manual-entry", "4", "Reading an entry page",
            p(
              "The left column summarizes the entry. The header shows the tissue, dataset, species ",
              "and disease status, with a badge for the input and output technology (for example ",
              manual_bold("RNA-seq → WGBS"), "). The ", manual_bold("Entry"), " tiles describe this entry ",
              "(samples, number of CpGs). The ", manual_bold("Dataset"), " tiles describe the full dataset it belongs to."
            ),
            manual_shot(
              "05-entry-summary.jpg",
              "Entry summary card showing tissue, dataset, technology badge and metadata tiles",
              "1: entry title and source. 2: input → output technology. 3: entry details. 4: dataset details.",
              narrow = TRUE
            ),
            p(
              "Below the summary, ", manual_bold("Dataset Description"), " explains how the entry was built."
            )
          ),

          manual_step(
            "manual-plots", "5", "PCA and UMAP plots",
            p(
              "The right column shows where this entry sits relative to the rest of its dataset. Both ",
              manual_bold("Principal Component Analysis"), " and ", manual_bold("UMAP Embeddings"),
              " have tabs for the ", manual_bold("Input RNA"), ", the ", manual_bold("Predicted DNAm"),
              " and, where measured data exist, the ", manual_bold("Gold-standard DNAm"),
              ". The current entry is marked with a ", manual_bold("diamond"), "."
            ),
            manual_live(
              "06-plots",
              "Switching between Input RNA, Predicted DNAm and Gold-standard DNAm tabs and hovering a point",
              "Switching PCA tabs and hovering a point for details."
            ),
            tags$ul(
              class = "manual-list",
              tags$li("Hover any point to see its sample and group."),
              tags$li("Click a legend item to hide or show that group; double-click to show only that group."),
              tags$li("Drag to zoom into a region; double-click the plot to reset the view."),
              tags$li("Use the toolbar in the plot's top-right corner to download it as a PNG.")
            )
          ),

          manual_step(
            "manual-spatial", "6", "Spatial entries",
            p(
              "Spatial transcriptomics entries (Mouse Embryo and Mouse Pancreas) show methylation ",
              "across tissue sections instead of PCA and UMAP. Choose a feature in ",
              manual_bold("Select CpG"), " and switch between ", manual_bold("Predicted DNAm"), " and ",
              manual_bold("Measured DNAm"), " where both are available. All sections share one color ",
              "scale, so colors can be compared directly between samples."
            ),
            manual_live(
              "07-spatial",
              "Choosing different CpG features in the Mouse Embryo spatial view and watching every section update",
              "Picking a CpG feature updates all embryo sections at once."
            )
          ),

          manual_step(
            "manual-downloads", "7", "Downloading data",
            p(
              "Each entry page has a ", manual_bold("Downloads"), " card with files for that tissue, ",
              "cancer type or cell type: predicted DNAm, gold-standard (measured) DNAm, input RNA ",
              "and DNAm tracks for genome browsers. If a file does not exist for an entry, its button ",
              "has a dashed outline and says unavailable. ", manual_bold("View on Full Dataset Downloads"),
              " jumps to the complete dataset."
            ),
            manual_shot(
              "08-entry-downloads.jpg",
              "Downloads card on an entry page with download buttons and the link to full datasets",
              "1: per-entry files. 2: link to the full dataset.",
              narrow = TRUE
            ),
            p(
              "The ", manual_bold("Full Datasets"), " page lists every dataset with its technologies, ",
              "species and number of entries. A dash means that file type does not exist for the dataset."
            ),
            manual_shot(
              "09-full-downloads.jpg",
              "Full Dataset Downloads table with download buttons for predicted DNAm, input RNA and gold-standard DNAm",
              "Whole-dataset downloads."
            )
          ),

          manual_step(
            "manual-models", "8", "Prediction models",
            p(
              "The ", manual_bold("Models"), " page describes the three transcriptome-to-methylome models ",
              "behind the predictions (Dreamland, MethylProphet and Ramp), with links to download ",
              "each model, its code and pretrained weights, plus a side-by-side comparison."
            ),
            manual_shot(
              "10-models.jpg",
              "Models page showing Dreamland, MethylProphet and Ramp cards",
              "Model cards with download links."
            )
          ),

          manual_step(
            "manual-tips", "9", "Tips",
            tags$ul(
              class = "manual-list",
              tags$li(
                "The DNA animation at the top of the About page can be paused with the round ",
                manual_bold("pause"), " button under the site name."
              ),
              tags$li(
                "Large plots can take a few seconds to load. A thin progress bar at the top ",
                "of the page shows that the site is working."
              ),
              tags$li(
                "To compare tissues, keep one entry open and use the PCA or UMAP legend to ",
                "highlight other groups rather than opening many entries."
              ),
              tags$li(
                "Downloads are hosted on Hugging Face and open in your browser's download manager. ",
                "Full datasets can be several gigabytes."
              )
            )
          )
        )
      )
    ),

    tags$script(HTML("
      (function () {
        var reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
        function setPlaying(btn, on) {
          var img = btn.querySelector('img');
          var want = on ? img.dataset.anim : img.dataset.poster;
          if (img.getAttribute('src') !== want) img.setAttribute('src', want);
          btn.classList.toggle('is-playing', on);
          btn.setAttribute('aria-pressed', on ? 'true' : 'false');
        }
        function init() {
          var buttons = document.querySelectorAll('.manual-live-toggle');
          if (!buttons.length) return false;
          var observer = 'IntersectionObserver' in window && !reduce ?
            new IntersectionObserver(function (entries) {
              entries.forEach(function (e) {
                var btn = e.target;
                if (btn.dataset.userPaused === '1') return;
                setPlaying(btn, e.isIntersecting);
              });
            }, { threshold: 0.35 }) : null;
          buttons.forEach(function (btn) {
            btn.addEventListener('click', function () {
              var on = !btn.classList.contains('is-playing');
              btn.dataset.userPaused = on ? '0' : '1';
              setPlaying(btn, on);
            });
            if (observer) observer.observe(btn);
          });
          return true;
        }
        if (!init()) document.addEventListener('DOMContentLoaded', init);
      })();
    "))
  )
}
