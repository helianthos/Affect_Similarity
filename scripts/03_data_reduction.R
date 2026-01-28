############################################################################# #
# 03_data_reduction.R
#
# Purpose:
#   Selection of variables to be used for analysis and renaming columns to uniform names
#   Correction for errors found during data checks (running scripts/02_data_checks.R)
#
# Usage:
#   Run source("R/03_data_reduction.R") to generate execution report, saved in outputs/logs.
# 
# Input:
#   Assumes imported data is located in data/imported (in variable dir_data_imp),
#   afer running 01_data_import.R at least once
#       * data/imported/esm_raw.rds
#       * data/imported/bg_raw.rds
#       * data/imported/vmr_raw.rds
#       * data/imported/post_raw.rds
# 
# Output:
#   log file and reduced datasets
#       * data/reduced/esm_red.rds
#       * data/reduced/bg_red.rds
#       * data/reduced/vmr_red.rds
#       * data/reduced/post_red.rds       
#   Assumes that the output directories exist (e.g., via git clone)
#   If not, these will as fallback be created during 00_setup.R
#       * data/reduced (in dir_data_red)
#       * outputs/logs (in dir_logs)
#
############################################################################## #

## ########################################################################### #
## ---- GLOBAL SETUP -----------------------------------------------------------
## ########################################################################### #

# 1. Load packages, paths and data configurations
source(here::here("R", "00_setup.R"))

# 2. Parameters
log_file  = file.path(dir_logs, "03_data_reduction_log.txt")

# 3. Start logging
sink(file=log_file, append = FALSE, split = TRUE) # for cat and print
cat("============================================================\n")
cat("03_data_reduction.R log\n")
cat("Log generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n", sep = "")
cat("Project root:  ", here::here(), "\n", sep = "")
cat("============================================================\n")

## ########################################################################### #
## ---- A. ESM DATA ------------------------------------------------------------
## ########################################################################### #
header("A. ESM Data", level = 1)

## ---- ```` Load  -------------------------------------------------------------
## --------------------------------------------------------------------------- -
esm_data <- readRDS(file.path(dir_data_imp, "esm_raw.rds"))
load_config("ESM")

## ---- ```` Reduce  -----------------------------------------------------------
## --------------------------------------------------------------------------- -

# mapping: new_name = old_name
esm_map <- c(
  dyad     = dyad,   # right hand side dyad = "PpID"
  person   = person,
  part_no  = part_no,
  beep     = beep,
  NA_own   = NA_own,
  PA_own   = PA_own,
  NA_part_perc = NA_part_perc,
  PA_part_perc = PA_part_perc,
  love     = love,
  perc_resp= perc_resp,
  neg_gen  = neg_gen,
  pos_gen  = pos_gen
)

# select and rename
esm_data <- select_and_rename(esm_data, esm_map)

  
## ---- ```` Save  -------------------------------------------------------------
## --------------------------------------------------------------------------- -
saveRDS(esm_data, file.path(dir_data_red, "esm_red.rds"))
cat(sprintf("✅ ESM data reduced to columns of interest and saved to %s\n∑", 
            file.path(dir_data_red, "esm_red.rds")))
clean_config("ESM") # Remove ESM-specific configuration variables

## ########################################################################### #
## ---- B. BG DATA -------------------------------------------------------------
## ########################################################################### #
header("B. BG Data", level = 1)

## ---- ```` Load  -------------------------------------------------------------
## --------------------------------------------------------------------------- -
bg_data <- readRDS(file.path(dir_data_imp, "bg_raw.rds"))
load_config("BG")

## ---- ```` Reduce  -----------------------------------------------------------
## --------------------------------------------------------------------------- -

# mapping: new_name = old_name
bg_map <- c(
  dyad     = dyad,   # right hand side dyad = "PpID"
  person   = person,
  setNames(paste0("DCI", 1:30), paste0("DCI", 1:30))
)

# select and rename
bg_data <- select_and_rename(bg_data, bg_map)

## ---- ```` Correct  ----------------------------------------------------------
## --------------------------------------------------------------------------- -

# dyad 59 had one partner delete and reinstall mpath so for the ESM data it was not
# clear which answers belonged to which participant and they were therefore excluded
# from ESM. They did not participate to lab sessions either, so also delete them from background data BG.
bg_data <- bg_data %>% filter(dyad != 59)

## ---- ```` Save  -------------------------------------------------------------
## --------------------------------------------------------------------------- -
saveRDS(bg_data, file.path(dir_data_red, "bg_red.rds"))
cat(sprintf("✅ BG data reduced to columns of interest and saved to %s\n", 
            file.path(dir_data_red, "bg_red.rds")))
clean_config("BG") # Remove BG-specific configuration variables


## ########################################################################### #
## ---- C. VMR DATA -------------------------------------------------------------
## ########################################################################### #
header("C. VMR Data", level = 1)

## ---- ```` Load  -------------------------------------------------------------
## --------------------------------------------------------------------------- -
vmr_data <- readRDS(file.path(dir_data_imp, "vmr_raw.rds"))
load_config("VMR")

## ---- ```` Reduce  -----------------------------------------------------------
## --------------------------------------------------------------------------- -

# mapping: new_name = old_name
vmr_map <- c(
  dyad     = dyad,   # right hand side dyad = "PpID"
  person   = person,
  topic       = topic,
  segment     = segment,
  NA_own      = NA_own,
  PA_own      = PA_own,
  NA_part_perc= NA_part_perc,
  PA_part_perc= PA_part_perc
)

# select and rename
vmr_data <- select_and_rename(vmr_data, vmr_map)

## ---- ```` Correct  ----------------------------------------------------------
## --------------------------------------------------------------------------- -

# correct CoupleID numbers higher than 700 (reduce them by 1400)
vmr_data <- vmr_data %>% mutate(dyad = ifelse(dyad < 700, dyad, dyad - 1400))

# exclude couple 2 since this was a test couple that should have been removed in preprocesing
vmr_data <- vmr_data %>% filter(dyad != 2)

## ---- ```` Save  -------------------------------------------------------------
## --------------------------------------------------------------------------- -
saveRDS(vmr_data, file.path(dir_data_red, "vmr_red.rds"))
cat(sprintf("✅ VMR data reduced to columns of interest and saved to %s\n", 
            file.path(dir_data_red, "vmr_red.rds")))
clean_config("VMR") # Remove VMR-specific configuration variables

## ########################################################################### #
## ---- D. POST DATA ------------------------------------------------------------
## ########################################################################### #
header("D. POST Data", level = 1)

## ---- ```` Load  -------------------------------------------------------------
## --------------------------------------------------------------------------- -
post_data <- readRDS(file.path(dir_data_imp, "post_raw.rds"))
load_config("POST")

## ---- ```` Reduce  -----------------------------------------------------------
## --------------------------------------------------------------------------- -

# mapping: new_name = old_name
post_map <- c(
  dyad     = dyad,   # right hand side dyad = "PpID"
  person   = person,
  love_neg = love_neg,
  close_neg= close_neg,
  love_pos = love_pos,
  close_pos= close_pos
)

# select and rename
post_data <- select_and_rename(post_data, post_map)

## ---- ```` Correct  ----------------------------------------------------------
## --------------------------------------------------------------------------- -

# exclude couple 2 since this was a test couple that should have been removed in preprocessing
post_data <- post_data %>% filter(dyad != 2)

## ---- ```` Save  -------------------------------------------------------------
## --------------------------------------------------------------------------- -
saveRDS(post_data, file.path(dir_data_red, "post_red.rds"))
cat(sprintf("✅ POST data reduced to columns of interest and saved to %s\n", 
            file.path(dir_data_red, "post_red.rds")))
clean_config("POST") # Remove POST-specific configuration variables

## ########################################################################### #
## ---- E. CHECKS ------------------------------------------------------------
## ########################################################################### #
header("E. Cross dataset checks after reduction", level = 1)

check_data_participant_overlap(esm_data$person, bg_data$person, "ESM", "BG")
check_data_participant_overlap(vmr_data$person, post_data$person, "VMR", "POST")
check_data_participant_overlap(esm_data$person, vmr_data$person, "ESM", "VMR")
check_data_participant_overlap(vmr_data$person, bg_data$person, "VMR", "BG")

## ########################################################################### #
# ---- END ---------------------------------------------------------------------
## ########################################################################### #
header("End of data reduction report", level = 1)
cat("Log saved to: ", log_file, "\n", sep = "")

message(paste("Output log saved to:", log_file))
sink()