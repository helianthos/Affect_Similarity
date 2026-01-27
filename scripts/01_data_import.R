# ========================================================== =
# 01_data_import.R
#
# Purpose:
#   Import raw CSV files and generate analysis-ready datasets.
#.  Raw = preprocessed, but preprocessing documented
#
# Inputs:
#   - Raw CSV files located in paths$dir_raw_data, read from
#.    config/local_raw_data_path by R/01_paths.R
#
# Outputs:
#   - data/imported/*.rds (not tracked in Git)
#
# Usage:
#   source("scripts/01_data_import.R")
#
# Notes:
#   - Requires config/local_raw_data_path.R to be present
#   - Does NOT modify raw data
# ========================================================== =

# ---- 1. Setup ----
source(here::here("R", "00_setup.R"))

log_file <- file.path(dir_logs, "01_data_import_log.txt")
sink(file = log_file, append = FALSE, split = TRUE)
cat("============================================================\n")
cat("01_data_import.R log\n")
cat("Log generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n", sep = "")
cat("Project root:  ", here::here(), "\n", sep = "")
cat("============================================================\n")


# ---- 2. Helper functions ----
read_csv_quiet <- function(path, ...) {
  message("Reading: ", basename(path))
  readr::read_csv(
    path,
    show_col_types = FALSE,
    progress = FALSE,
    ...
  )
}

# ---- 3. Validate raw data dir and find raw data files ----
if (!dir.exists(dir_raw_data)) {
  stop(sprintf("Raw data directory does not exist: %s", dir_raw_data),
       call. = FALSE)
}

raw_files <- list.files(
  dir_raw_data,
  pattern = "\\.csv$",
  full.names = TRUE
)

message("Found ", length(raw_files), " raw CSV file(s).")

# ---- 4. Import raw data ----
raw_data <- raw_files %>%
  set_names(basename(.)) %>%
  map(read_csv_quiet)

# ---- 6. Check if files are as expected ----
required_files <- list(
  bg   = "CCS_BGQuestionnaireV2_with_screener.csv",
  esm  = "CCS_ESMbeeps_individual.csv",
  vmr  ="CCS_VMR_preprocessed.csv",
  post = "CCS_Preprocessed_PostInteractionQ.csv"
)

missing_files <- setdiff(required_files, names(raw_data))

if (length(missing_files) > 0) {
  stop(
    paste("Missing required raw file(s):", paste(missing_files, collapse = ", ")),
    call. = FALSE
  )
}

# ---- 7. Save imported datasets ----
for (nm in names(required_files)) {
  obj <- raw_data[[ required_files[[nm]] ]]
  saveRDS(obj, file.path(dir_data_imp, paste0(nm, "_raw.rds")))
  cat("\n✅ Imported dataset ", paste0(nm, "_raw.rds ") ,"written to: ", dir_data_imp)
}

# ---- 7. Clean and stop logging ----
rm(obj, nm, raw_data, raw_files, required_files, missing_files, read_csv_quiet)

cat("\n\nDone.\n")
cat("\nLog saved to: ", log_file, "\n", sep = "")
sink()
