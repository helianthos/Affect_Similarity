############################################################################# #
# 04_data_construct.R
#
# Purpose:
#   Construction of similarity indices and we-ness and add to datasets
#
# Usage:
#   Run source("R/04_data_construct.R") to generate execution report, saved in outputs/logs.
# 
# Input :
#   Assumes imported data is located in data/reduced (in variable dir_data_red),
#   afer running 01_data_import.R
#   and 03_data_reduction.R at least once
#       * data/reduced/esm_raw.rds
#       * data/reduced/esm_bg.rds
#       * data/reduced/esm_vmr.rds
#       * data/reduced/esm_post.rds
#   
# Output:
#   Log file and datasets stored in data/analysis
#   Assumes that the output directories exist (e.g., via git clone)
#   If not, these will as fallback be created during 00_setup.R
#       * data/analysis (in dir_data_ana)
#       * outputs/logs (in dir_logs)
#
############################################################################## #

## ########################################################################### #
## ---- GLOBAL SETUP -----------------------------------------------------------
## ########################################################################### #

# 1. Load packages, paths and data configurations
source(here::here("R", "00_setup.R"))

# 2. Load datasets
esm_data <- readRDS(file.path(dir_data_red, "esm_raw.rds"))
bg_data <- readRDS(file.path(dir_data_red, "bg_raw.rds"))
vmr_data <- readRDS(file.path(dir_data_red, "vmr_raw.rds"))
post_data <- readRDS(file.path(dir_data_red, "post_raw.rds"))

# 3. Parameters
log_file  = file.path(dir_logs, "04_data_construct_log.txt")

# 4. Start logging
sink(file=log_file, append = FALSE, split = TRUE) # for cat and print
cat("============================================================\n")
cat("04_data_construct.R log\n")
cat("Log generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n", sep = "")
cat("Project root:  ", here::here(), "\n", sep = "")
cat("============================================================\n")

## ########################################################################### #
## ---- ESM DATA ---------------------------------------------------------------
## ########################################################################### #
header("A. ESM Data", level = 1)



## ########################################################################### #
# ---- END ---------------------------------------------------------------------
## ########################################################################### #
header("End of data construction Report", level = 1)
cat("Log saved to: ", log_file, "\n", sep = "")

message(paste("Output log saved to:", log_file))
sink()