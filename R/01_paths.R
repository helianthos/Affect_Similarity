# ============================================================
# 01_paths.R
# Define file paths used across scripts.
# ============================================================

source("R/02_packages.R") # load packages from project library

cfg_file <- here("config", "local_paths.R")

if (!file.exists(cfg_file)) {
  stop(
    paste(
      "Missing config/local_paths.R.",
      "Create it by copying config/local_paths_TEMPLATE.R",
      "and editing RAW_DATA_DIR.",
      sep = "\n"
    ),
    call. = FALSE
  )
}

source(cfg_file)  # defines RAW_DATA_DIR

paths <- list(
  project_dir = here(),
  raw_dir     = RAW_DATA_DIR,
  derived_dir = here("data", "derived")
)

# ---- Validation  ----

if (!dir.exists(paths$raw_dir)) {
  stop(glue::glue("Raw data directory does not exist: {paths$raw_dir}"),
       call. = FALSE)
}

if (!dir.exists(paths$derived_dir)) {
  stop(glue::glue(
    "Derived data directory is missing: {paths$derived_dir}.\n",
    "This folder should exist in the repository (see .gitkeep)."
  ), call. = FALSE)
}

paths
