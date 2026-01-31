############################################################################# #
# 04_data_construct.R
#
# Purpose:
#   Construction of similarity indices and we-ness, added to datasets. Reversing
#   negative DCI items.
#
# Usage:
#   Run source("R/04_data_construct.R") to generate execution report, saved in 
#   outputs/logs.
# 
# Input :
#   Assumes data is located in data/reduced/ (in variable dir_data_red),
#   after running 01_data_import.R + 03_data_reduction.R at least once
#       * data/reduced/esm_red.rds
#       * data/reduced/bg_red.rds
#       * data/reduced/vmr_red.rds
#       * data/reduced/post_red.rds
#   
# Output:
#   Log file and datasets stored in data/analysis/ (in variable dir_data_ana)
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

# 2. Start logging
log_file  = file.path(dir_logs, "04_data_construct_log.txt")

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

# 1. Load data ----
esm_data <- readRDS(file.path(dir_data_red, "esm_red.rds"))
load_config("ESM")

# 2. Centering ----
esm_data <- esm_data %>%
  group_by(person) %>%   # person mean centering
  mutate(
    cPA_own       = PA_own - mean(PA_own, na.rm = TRUE),
    cNA_own       = NA_own - mean(NA_own, na.rm = TRUE),
    cPA_part_perc = PA_part_perc - mean(PA_part_perc, na.rm = TRUE),
    cNA_part_perc = NA_part_perc - mean(NA_part_perc, na.rm = TRUE),
    clove         = love - mean(love, na.rm = TRUE),
    cperc_resp    = perc_resp - mean(perc_resp, na.rm = TRUE)
  ) %>%
  ungroup()

# 3. Partner actual affect ----
esm_data <- esm_data %>%
  mutate(partner_id = ifelse(person < 700, person + 700, person -700)) %>%
  left_join(
    esm_data %>% select(person, dyad, beep, cNA_part_act = cNA_own, cPA_part_act = cPA_own),
    by = c("dyad", "beep", "partner_id" = "person")
  )

# 4. Mean elevation and affect distance ----
esm_data <- esm_data %>%
  mutate(
    PA_elevation_act  = (cPA_own + cPA_part_act)/2,
    PA_elevation_perc = (cPA_own + cPA_part_perc)/2,
    PA_distance_act   = abs(cPA_own - cPA_part_act),
    PA_distance_perc  = abs(cPA_own - cPA_part_perc),
    NA_elevation_act  = (cNA_own + cNA_part_act)/2,
    NA_elevation_perc = (cNA_own + cNA_part_perc)/2,
    NA_distance_act   = abs(cNA_own - cNA_part_act),
    NA_distance_perc  = abs(cNA_own - cNA_part_perc)
  )

# 5. Actual and perceived similarity ----
esm_data <- esm_data %>%
  mutate(
    PA_similarity_act  = PA_elevation_act - PA_distance_act,
    PA_similarity_perc = PA_elevation_perc - PA_distance_perc,
    NA_similarity_act  = NA_elevation_act - NA_distance_act,
    NA_similarity_perc = NA_elevation_perc - NA_distance_perc
  )

# 6. Save ----
saveRDS(esm_data, file.path(dir_data_ana, "esm_ana.rds"))
cat(sprintf("ESM data extended with centralized affect measures and similarity measures saved to %s\n", 
            file.path(dir_data_red, "esm_ana.rds")))
clean_config("ESM")

## ########################################################################### #
## ---- BG DATA ---------------------------------------------------------------
## ########################################################################### #
header("B. BG Data", level = 1)

# 1. Load data and data configuration ----
bg_data <- readRDS(file.path(dir_data_red, "bg_red.rds"))
load_config("BG")

# 2. Reverse negative DCI items ----
bg_data <- bg_data %>%
  mutate(across(all_of(DCI_reverse_items), ~ 6 - .))

# 3. We-ness and total DCI ----
bg_data <- bg_data %>%
  mutate(
    # add columns
    dci_total = rowSums(pick(all_of(scale_DCI))),
    we_ness   = rowMeans(pick(all_of(DCI_weness_items)))
  )

# 4. Save ----
saveRDS(bg_data, file.path(dir_data_ana, "bg_ana.rds"))
cat(sprintf("BG data extended with we-ness construct and saved to %s\n", 
            file.path(dir_data_red, "bg_ana.rds")))
clean_config("BG")

## ########################################################################### #
## ---- VMR DATA ---------------------------------------------------------------
## ########################################################################### #
header("C. VMR Data", level = 1)

# 1. Load data and data configuration ----
vmr_data <- readRDS(file.path(dir_data_red, "vmr_red.rds"))
load_config("VMR")

# 2. Centering ----
vmr_data <- vmr_data %>%
  group_by(person) %>%   # person mean centering
  mutate(
    cPA_own       = PA_own - mean(PA_own, na.rm = TRUE),
    cNA_own       = NA_own - mean(NA_own, na.rm = TRUE),
    cPA_part_perc = PA_part_perc - mean(PA_part_perc, na.rm = TRUE),
    cNA_part_perc = NA_part_perc - mean(NA_part_perc, na.rm = TRUE)
  ) %>%
  ungroup()

# 3. Partner actual affect ----
vmr_data <- vmr_data %>%
  mutate(partner_id = ifelse(person < 700, person + 700, person -700)) %>%
  left_join(
    vmr_data %>% select(person, dyad, segment, topic, cNA_part_act = cNA_own, cPA_part_act = cPA_own),
    by = c("dyad", "segment", "topic", "partner_id" = "person")
  )

# 4. Mean elevation and affect distance ----
vmr_data <- vmr_data %>%
  mutate(
    PA_elevation_act  = (cPA_own + cPA_part_act)/2,
    PA_elevation_perc = (cPA_own + cPA_part_perc)/2,
    PA_distance_act   = abs(cPA_own - cPA_part_act),
    PA_distance_perc  = abs(cPA_own - cPA_part_perc),
    NA_elevation_act  = (cNA_own + cNA_part_act)/2,
    NA_elevation_perc = (cNA_own + cNA_part_perc)/2,
    NA_distance_act   = abs(cNA_own - cNA_part_act),
    NA_distance_perc  = abs(cNA_own - cNA_part_perc)
  )

# 5. Actual and perceived similarity ----
vmr_data <- vmr_data %>%
  mutate(
    PA_similarity_act  = PA_elevation_act - PA_distance_act,
    PA_similarity_perc = PA_elevation_perc - PA_distance_perc,
    NA_similarity_act  = NA_elevation_act - NA_distance_act,
    NA_similarity_perc = NA_elevation_perc - NA_distance_perc
  )

# 6. Save ----
saveRDS(vmr_data, file.path(dir_data_ana, "vmr_ana.rds"))
cat(sprintf("VMR data saved to %s\n", 
            file.path(dir_data_red, "vmr_ana.rds")))
clean_config("VMR")

## ########################################################################### #
## ---- POST DATA ---------------------------------------------------------------
## ########################################################################### #
header("D. POST Data", level = 1)

# 1. Load data and data configuration ----
post_data <- readRDS(file.path(dir_data_red, "post_red.rds"))
load_config("POST")


# 2. Save ----
saveRDS(post_data, file.path(dir_data_ana, "post_ana.rds"))
cat(sprintf("POST data saved to %s\n", 
            file.path(dir_data_red, "post_ana.rds")))
clean_config("POST")

## ########################################################################### #
# ---- END ---------------------------------------------------------------------
## ########################################################################### #
header("End of data construction Report", level = 1)
cat("Log saved to: ", log_file, "\n", sep = "")

message(paste("Output log saved to:", log_file))
sink()