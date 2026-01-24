# ============================================================
# R/00_setup.R
# 
# Purpose:
#     * load file paths (unpacked to .GlobalEnv) (01_paths.R)
#     * Load packages (02_packages.R)
#     * load data configuration lists (03_data_config.R)
#
# Used across scripts.
# ============================================================

paths <- source(here::here("R", "01_paths.R"))$value
list2env(paths, envir = .GlobalEnv)
rm(paths)
suppressPackageStartupMessages(source(here::here("R", "02_packages.R")))
source(here::here("R", "03_data_config.R"))
