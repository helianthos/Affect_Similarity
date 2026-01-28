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
#   Assumes data is located in data/reduced (in variable dir_data_red),
#   afer running 01_data_import.R + 03_data_reduction.R at least once
#       * data/reduced/esm_red.rds
#       * data/reduced/bg_red.rds
#       * data/reduced/vmr_red.rds
#       * data/reduced/post_red.rds
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
esm_data <- readRDS(file.path(dir_data_red, "esm_red.rds"))
bg_data <- readRDS(file.path(dir_data_red, "bg_red.rds"))
vmr_data <- readRDS(file.path(dir_data_red, "vmr_red.rds"))
post_data <- readRDS(file.path(dir_data_red, "post_red.rds"))

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

# Center variables

esm_data <- esm_data %>%
  group_by(person) %>%   # person mean centering
  mutate(
    cPA_own       = PA_own - mean(PA_own, na.rm = TRUE),
    cNA_own       = NA_own - mean(NA_own, na.rm = TRUE),
    cPA_part_perc = PA_part_perc - mean(PA_part_perc, na.rm = TRUE),
    cNA_part_perc = NA_part_perc - mean(NA_part_perc, na.rm = TRUE),
    clove         = love - mean(love, na.rm = TRUE),
    cperc_resp         = perc_resp - mean(perc_resp, na.rm = TRUE)
  )
  
esm_data <- esm_data %>%
  mutate(partner_id = ifelse(person < 700, person + 700, person -700)) %>%
  left_join(
    esm_data %>% select(person, dyad, beep, cNA_part_act = cNA_own, cPA_partn_act = cPA_own),
    by = c("dyad", "beep", "partner_id" = "person")
  )

## ########################################################################### #
# ---- END ---------------------------------------------------------------------
## ########################################################################### #
header("End of data construction Report", level = 1)
cat("Log saved to: ", log_file, "\n", sep = "")

message(paste("Output log saved to:", log_file))
sink()