# ============================================================
# R/00_setup.R
# Load packages and define file paths.
# Used across scripts.
# ============================================================

suppressPackageStartupMessages(source(here::here("R", "02_packages.R")))
paths <- source(here::here("R", "01_paths.R"))$value
list2env(paths, envir = .GlobalEnv)
rm(paths)