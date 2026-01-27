############################################################################# #
# 03_data_reduction.R
#
# Purpose:
#   Selection of variables to be used for analysis and renaming columns to uniform names,
#
# Usage:
#   Run source("R/03_reduce_data.R") to generate execution report, saved in outputs/logs.
# 
# Input:
#   Assumes imported data is located in data/imported (in variable dir_data_imp),
#   afer running 01_data_import.R at least once
#       * data/imported/esm_raw.rds
#       * data/imported/esm_bg.rds
#       * data/imported/esm_vmr.rds
#       * data/imported/esm_post.rds
# 
# Output:
#   log file and reduced datasets
#       * data/reduced/esm_reduced.rds
#       * data/reduced/bg_reduced.rds
#       * data/reduced/vmr_reduced.rds
#       * data/reduced/post_reduced.rds       
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

# 2. Load datasets


vmr_data <- readRDS(file.path(dir_data_imp, "vmr_raw.rds"))
post_data <- readRDS(file.path(dir_data_imp, "post_raw.rds"))

# 3. Parameters
log_file  = file.path(dir_logs, "03_data_reduction_log.txt")

# 4. Start logging
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

## ---- ```` Save  -------------------------------------------------------------
## --------------------------------------------------------------------------- -
saveRDS(post_data, file.path(dir_data_red, "post_red.rds"))
cat(sprintf("✅ POST data reduced to columns of interest and saved to %s\n", 
            file.path(dir_data_red, "post_red.rds")))
clean_config("POST") # Remove POST-specific configuration variables

## ########################################################################### #
# ---- END ---------------------------------------------------------------------
## ########################################################################### #
header("End of data reduction report", level = 1)
cat("Log saved to: ", log_file, "\n", sep = "")

message(paste("Output log saved to:", log_file))
sink()