# =====================================================
# LOAD GTEX MATRIX FROM DROPBOX
# =====================================================

url <- "https://www.dropbox.com/s/9p88q86ry43todx/ramp.rds?dl=1"

temp_file <- tempfile(
  fileext = ".rds"
)

options(timeout = 10000)

download.file(
  
  url,
  
  temp_file,
  
  mode = "wb",
  
  method = "libcurl"
)

gtex <- readRDS(
  temp_file
)

# =====================================================
# CREATE OUTPUT FOLDER
# =====================================================

dir.create(
  "data/downloads/gtex_bulk",
  recursive = TRUE,
  showWarnings = FALSE
)

# =====================================================
# SAFE FOLDER NAMES
# =====================================================

safe_name <- function(x) {
  
  x <- tolower(x)
  
  x <- gsub(
    " ",
    "_",
    x
  )
  
  x <- gsub(
    "-",
    "_",
    x
  )
  
  x
}

# =====================================================
# SPLIT TISSUES
# =====================================================

for (tissue_name in colnames(gtex)) {
  
  cat(
    "\nProcessing:",
    tissue_name,
    "\n"
  )
  
  tissue_matrix <- gtex[
    ,
    tissue_name,
    drop = FALSE
  ]
  
  folder_name <- safe_name(
    tissue_name
  )
  
  output_dir <- paste0(
    "data/downloads/gtex_bulk/",
    folder_name
  )
  
  dir.create(
    output_dir,
    recursive = TRUE,
    showWarnings = FALSE
  )
  
  # SAVE RDS
  
  saveRDS(
    
    tissue_matrix,
    
    paste0(
      output_dir,
      "/",
      folder_name,
      "_predicted_dnAm.rds"
    )
  )
  
  # README
  
  readme_text <- paste(
    
    "# GTEx Predicted DNA Methylation",
    
    "",
    
    paste(
      "Tissue:",
      tissue_name
    ),
    
    "Dataset: GTEx",
    
    "Species: homo sapiens",
    
    "Input Technology: RNA-seq",
    
    "Output Technology: WGBS",
    
    paste(
      "CpGs:",
      nrow(tissue_matrix)
    ),
    
    paste(
      "Samples:",
      ncol(tissue_matrix)
    ),
    
    "",
    
    "Predicted DNA methylation profiles reconstructed from GTEx transcriptomic data.",
    
    sep = "\n"
  )
  
  writeLines(
    
    readme_text,
    
    paste0(
      output_dir,
      "/README.md"
    )
  )
  
  cat(
    "Saved:",
    folder_name,
    "\n"
  )
}

cat(
  "\n=================================\n"
)

cat(
  "GTEX SPLITTING COMPLETE\n"
)

cat(
  "=================================\n"
)