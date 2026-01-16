# ============================================================
# 01_import.R
#
# Purpose:
#   Import raw CSV files and generate analysis-ready datasets.
#
# Inputs:
#   - Raw CSV files located in paths$raw_dir
#
# Outputs:
#   - data/derived/*.rds (not tracked in Git)
#
# Usage:
#   source("scripts/01_import.R")
#
# Notes:
#   - Requires config/local_paths.R to be present
#   - Does NOT modify raw data
# ============================================================

# ---- Setup ----
source("R/02_packages.R")
paths <- source("R/01_paths.R")$value

# ---- Helper functions ----

read_csv_quiet <- function(path, ...) {
  message("Reading: ", basename(path))
  readr::read_csv(
    path,
    show_col_types = FALSE,
    progress = FALSE,
    ...
  )
}

# ---- Locate raw files ----

raw_files <- list.files(
  paths$raw_dir,
  pattern = "\\.csv$",
  full.names = TRUE
)

if (length(raw_files) == 0) {
  stop("No CSV files found in raw data directory.", call. = FALSE)
}

message("Found ", length(raw_files), " raw CSV file(s).")

# ---- Import raw data ----

raw_data <- raw_files %>%
  set_names(basename(.)) %>%
  map(read_csv_quiet)

# ---- Check if required files exist ----
required_files <- c(
  "CCS_BGQuestionnaireV1_without_screener.csv",
  "CCS_ESMbeeps_individual.csv",
  "CCS_Preprocessed_PostInteractionQ.csv",
  "CCS_VMR_preprocessed.csv"
)

missing_files <- setdiff(required_files, names(raw_data))

if (length(missing_files) > 0) {
  stop(
    paste("Missing required raw file(s):", paste(missing_files, collapse = ", ")),
    call. = FALSE
  )
}

# ---- Save derived datasets ----

bg_q_raw <- raw_data[["CCS_BGQuestionnaireV1_without_screener.csv"]]
esm_raw <- raw_data[["CCS_ESMbeeps_individual.csv"]]
vmr_raw <- raw_data[["CCS_VMR_preprocessed.csv"]]
post_q_raw <- raw_data[["CCS_Preprocessed_PostInteractionQ.csv"]]

saveRDS(bg_q_raw,  here::here("data", "derived", "bg_q_raw.rds"))
saveRDS(esm_raw,  here::here("data", "derived", "esm_raw.rds"))
saveRDS(vmr_raw,  here::here("data", "derived", "vmr_raw.rds"))
saveRDS(post_q_raw, here::here("data", "derived", "post_q_raw.rds"))

message("Derived datasets written to data/derived/")
