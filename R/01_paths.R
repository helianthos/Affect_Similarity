# ============================================================
# R/01_paths.R
#
# Purpose:
#   Define and validate file paths used across scripts.
#
# Usage:
#   Source this file to load paths:  source(here::here("R", "01_paths.R"))
#   Sourcing is included in R/00_setup.R together with R/02_packages.R and
#   R/03_data_config.R
#
# Notes:
#   - This file reads and validates the raw data path provided by the user
#     in config/local_raw_data_path.R. This is the only path that is computer/user
#     dependent and needs to be provided (see README.md)
#   - The package 'here' is used to determine file path to project/working
#     directory and set file paths to other project sub-directories
#   - The project directory structure should exist since it is tracked by git
#     (in case of cloning) or included in the project compressed file.
#   - In case the core directories would not exist, they are created
#   - The package 'here' should be installed, in case it is not, renv will 
#     install it when doing renv::restore() (see README.md or renv_worklflow.md)
#   - Do NOT call install.packages() in this file.
# ============================================================

# Read local data path from config/local_raw_data_path.R
cfg_file <- here::here("config", "local_raw_data_path.R")
if (!file.exists(cfg_file)) {
  stop(
    paste(
      "Missing config/local_raw_data_path.R.",
      "Create it by copying config/local_raw_data_path_TEMPLATE.R",
      "and editing RAW_DATA_DIR.",
      sep = "\n"
    ),
    call. = FALSE
  )
}

# Load RAW_DATA_DIR variable + check it exists
source(cfg_file)
if (!exists("RAW_DATA_DIR") ||       # missing?
    !is.character(RAW_DATA_DIR) ||   # wrong type?
    length(RAW_DATA_DIR) != 1) {     # not exactly one string?
  stop(
    "config/local_raw_data_path.R must define RAW_DATA_DIR as a single character string.",
    call. = FALSE
  )
}

# Define paths list, paths should exist since tracked by git
paths <- list(
  dir_project      = here::here(),
  dir_raw_data     = RAW_DATA_DIR,
  dir_data         = here::here("data", "imported"),
  dir_plots        = here::here("outputs", "plots"),
  dir_logs         = here::here("outputs", "logs")
)

# Safeguard: create paths in case they don't exist
dir.create(paths$dir_data,  recursive = TRUE, showWarnings = FALSE)
dir.create(paths$dir_plots, recursive = TRUE, showWarnings = FALSE)
dir.create(paths$dir_logs,  recursive = TRUE, showWarnings = FALSE)

rm(cfg_file, RAW_DATA_DIR)

paths
