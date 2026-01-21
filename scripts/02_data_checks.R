############################################################################# #
# 02_structure_checks.R
#
# Purpose:
# Data checks on the 4 imported datasets
#
# Usage:
# Run source("R/02_structure_checks.R") to see the report without code echoing.
# Assumes data is located in
#       * data/derived/esm_raw.rds
#       * data/derived/esm_bg.rds
#       * data/derived/esm_vmr.rds
#       * data/derived/esm_post.rds
# Assumes that the output directories exist (e.g., via git clone)
#       * outputs/plots
#       * output/logs
#
############################################################################## #

## ---- GLOBAL SETUP  ----------------------------------------------------------
## --------------------------------------------------------------------------- -

# 1. Load packages
suppressPackageStartupMessages(source("R/02_packages.R"))

# 2. Load datasets
esm_data <- readRDS(here("data", "derived", "esm_raw.rds"))
bg_data <- readRDS(here("data", "derived", "bg_raw.rds"))
vmr_data <- readRDS(here("data", "derived", "vmr_raw.rds"))
post_data <- readRDS(here("data", "derived", "post_raw.rds"))

# 3. Global settings/paths
SETTINGS_GLOBAL <- list(
  plots_dir = here("outputs", "plots"),
  logs_dir = here("outputs", "logs"),
  log_file  = here("outputs", "logs", "02_data_checks_log.txt"),
  variable_config_sublists = c("cols", "vars", "scales")
)
list2env(SETTINGS_GLOBAL, envir = .GlobalEnv)

plot_counter <- 1

if(!dir.exists(plots_dir)) {
  stop("\n\n!!! ERROR: Output directory does not exist.\n")
}

# 4. Start logging
sink(file=log_file, append = FALSE, split = TRUE) # for cat and print
cat(paste0("Log Generated: ", Sys.time(), "\n\n"))

# # ---- GLOBAL DATA CONFIGURATION ---------------------------------------------
# # -------------------------------------------------------------------------- -

# ----````  1. ESM centralized configuration list ---- 
CONFIG_ESM <- list(
  # Columns mapping
  cols = list(
    col_person = "PpID",
    col_dyad   = "CoupleID",
    col_beep   = "beepno",
    col_compl  = "compliance",
    col_start  = "started",
    col_end    = "complete",
    col_ts_sent   = "timeStampSent",
    col_ts_sched  = "timeStampScheduled",
    col_ts_start  = "timeStampStart",
    col_ts_stop   = "timeStampStop",
    col_part_no   = "partner_no",      # Partner number (1 or 2)
    col_neg_gen   = "negevent_general",
    col_pres_oth  = "presence_others",
    col_cont_oth  = "contact_others",
    col_part_pres = "partner_presence", # 0=No, 1=Yes
    col_part_cont = "partner_contact"  # 1=No contact, 2-4=Types of contact
  ),
  # List of specific variables for targeted missingness or conditional items checks
  vars = list(
    vars_affect = c('NA_own', 'PA_own', 'NA_partner', 'PA_partner', 
                     'loving', 'perc_respons', 'negevent_partner', 'posevent_partner'),
    
    vars_time = c("timeStampScheduled", "timeStampSent", "timeStampStart", "timeStampStop"),
    
    vars_non_core = c("GeneralComments", "ESMComments", 
                      "timeStampScheduled", "timeStampSent", "timeStampStart", 
                      "timeStampStop", "started", "complete", "compliance"),
    
    vars_branch_partner = c(
      "negevent_partner", "posevent_partner", "reassurance_own", "extrinsicIER", 
      "expression_own", "dominance_own", "affiliation_own", "reassurance_partner", 
      "expression_partner", "dominance_partner", "affiliation_partner"),
    
    vars_branch_no_partner = c(
      "presence_others", "contact_others", "negevent_general", "posevent_general", 
      "lonely", "rumination", "posthoughts", "expression_desire", "affection_desire")
  ),
  # Settings
  settings = list(
    min_compliance = 30,
    expected_beeps = 90 #    Expected = (10*5) + (4*10) = 90 beeps
  )
)

#  ----````  2. BG centralized configuration list ----
CONFIG_BG <- list(
  # Column Names (Mapping your raw data names to generic roles)
  cols = list(
    col_person  = "PpID",
    col_dyad    = "CoupleID",
    col_age     = "AgeYEARS",
    col_gender  = "gender",
    col_nat     = "nationality",
    col_etn     = "etnicity",
    col_edu     = "edu",
    col_child   = "childrenYN",
    col_liv_tog = "livingTogether",
    col_rel_dur = "RelDurMonths",
    col_med     = "medication_none" # NA = no, 1=yes
  ),
  value_labels = list(
    col_gender  = c("1" = "Male", "2" = "Female", "3" = "Other"),
    col_nat     = c("4" = "Belgian", "5" = "Dutch", "6" = "Other"),
    col_etn     = c("1" = "Asian", "2" = "Black or AFrican-American", 
                    "3" = "Spanish or Latino", "4" = "White", "5" = "Other"),
    col_edu     = c("1" = "Primary School", "2" = "High School", 
                    "3" = "Bachelor", "4" = "Master", "5" = "PhD"),
    col_child   = c("0" = "No", "1" = "Yes"),
    col_liv_tog = c("1" = "No", "2" = "Yes"),
    col_med     = c("0" = "Not Medicated", "1" = "Medicated") # NA = no, 1=yes
  ),
  # Lists of scale items for range checks
  scales = list(
    scale_NSF = paste0("NSF", 1:16),      # Need Satisfaction & Frustration
    scale_CESD  = paste0("CESD", 1:20),   # Depressive syptoms     
    scale_DCI   = paste0("DCI", 1:30),    # Dyadic coping
    scale_ECR   = paste0("ECR", 1:12),    # Attachment 
    scale_EROS  = paste0("EROS", 1:9),    # Emotion Regulation Others and Self
    scale_IDSSR = paste0("IDSSR", 1:30),  # Depressive Symptoms      
    scale_PAQ   = paste0("PAQ", 1:16),    # Problem Areas in relationships
    scale_PRQCI = paste0("PRQCI", 1:18),  # Perceived Relationship Quality   
    scale_QSI6  = paste0("QSI6", 1:12),   # Sexual Satisfaction
    scale_ROES  = paste0("ROES", 1:32),   # Interpersonal emotion regulation  
    scale_RRS   = paste0("RRS", 1:26),    # Reflection and Rumination
    scale_RSE   = paste0("RSE", 1:10),    # Self Esteem
    scale_SIS   = paste0("SIS", 1:14),    # Sexual Inhibition 
    scale_SWLS  = paste0("SWLS", 1:5),    # Satisfaction With Life Scale
    scale_ADPIV1= paste0("ADPIV1.", 1:10),# Borderline Symptoms
    scale_ADPIV2= paste0("ADPIV2.", 1:10),# Borderline Symptoms     
    scale_CSIV  = paste0("CSIV", 1:32),   # Interpersonal Values
    scale_DIRIRS= paste0("DIRIRS", 1:4),  # Reinsurance seeking
    scale_WHODAS_likert = paste0("WHODAS", 1:12), # General Functioning
    scale_WHODAS_days   = paste0("WHODAS", 13:15) # General Functioning
  ),
  item_subsets = list(
    dci_neg_indices = c(7, 10, 11, 15, 22, 25, 26, 27)
  ),
  # Valid Ranges (Min, Max) for each scale
  ranges = list(
    limits_NSF   = c(1, 5),      
    limits_CESD  = c(0, 3),   
    limits_DCI   = c(1, 5),    
    limits_ECR   = c(1, 7),    
    limits_EROS  = c(1, 5),    
    limits_IDSSR = c(0, 3),   
    limits_PAQ   = c(1, 7),    
    limits_PRQCI = c(1, 7),  
    limits_QSI6  = c(1, 6),   
    limits_ROES  = c(1, 6),   
    limits_RRS   = c(1, 4),    
    limits_RSE   = c(0, 3),    
    limits_SIS   = c(1, 4),    
    limits_SWLS  = c(1, 7),    
    limits_WHODAS= c(1, 5), 
    limits_ADPIV1= c(1, 7),
    limits_ADPIV2= c(1, 3),
    limits_CSIV  = c(1, 5),   
    limits_DIRIRS= c(1, 7),
    limits_WHODAS_likert = c(1, 5), 
    limits_WHODAS_days   = c(0, 30)  # Days range
  ),
  settings = list(
    min_age = 18,
    max_age = 65 # max in codebook
  )
)

# ----````  3. VMR centralized configuration list ----
CONFIG_VMR <- list(
  cols = list(
    col_person = "PpID"
              ),
  vars = list(), 
  settings = list()
)

# ----````  4. POST centralized configuration list ----
CONFIG_POST <- list(
  cols = list(
    col_person = "PpID"
  ),
  vars = list(), 
  settings = list()
)

## ---- HELPER FUNCTIONS ----------------------------------------------------
## --------------------------------------------------------------------------- -

load_config <- function(config, to_global = TRUE) {
  # 1. Select the config list
  cfg <- switch(config,
                "ESM"  = CONFIG_ESM,
                "BG"   = CONFIG_BG,
                "VMR"  = CONFIG_VMR,
                "POST" = CONFIG_POST)
  
  if(is.null(cfg)) stop(paste("Configuration not found for:", config))
  # 2. Unpack non-empty sublists to Global Environment except if argument is set to FALSE
  if(to_global) {
    sublists_to_unpack <- names(cfg)
    for (sublist in sublists_to_unpack) {
      if(is.list(cfg[[sublist]]) && !is.null(cfg[[sublist]]))  {
        list2env(cfg[[sublist]], envir = .GlobalEnv)
      } 
    }
    cat(sprintf("✅ %s config unpacked to Global Env (Sublists: %s).\n", 
                config, paste(sublists_to_unpack, collapse=", ")))  }
  # 3. Return the config object invisibly
  invisible(cfg)
}

clean_config <- function(config) {
  # 1. Get the config to know WHAT to remove, to_global = FALSE to not unpack
  cfg <- load_config(config, to_global = FALSE) 
  # 2. Collect all variable names
  vars_to_remove <- c()
  sublists_to_remove <- names(cfg)
  for (sublist in sublists_to_remove) {
    if (is.list(cfg[[sublist]]) && !is.null(cfg[[sublist]])) {
      vars_to_remove <- c(vars_to_remove, names(cfg[[sublist]]))
    }
  }
  # 3. Limit to what exists in GlobalEnv to avoid warnings
  vars_to_remove <- vars_to_remove[sapply(vars_to_remove, exists, envir = .GlobalEnv)]
  vars_to_remove <- unique(vars_to_remove) # avoid attempting to remove twice
  # 4. Remove them from GlobalEnv
  if(length(vars_to_remove) > 0) {
    rm(list = vars_to_remove, envir = .GlobalEnv)
    cat(sprintf("\n🧹 %s vars removed from Global Env.\n", config))
  }
}

validate_variables <- function(config, dataset) {
  # 1. Get the config locally (not to global env)
  cfg <- load_config(config, to_global = FALSE)
  # 2. Gather all expected column names (in GLOBAL_SETTINGS variable_config_sublists)
  vars_required <- c()
  sublists_to_check <- intersect(names(cfg), variable_config_sublists)
  for (sublist in sublists_to_check) {
    if (!is.null(cfg[[sublist]]) && is.list(cfg[[sublist]])) {
      vars_required <- c(vars_required, unlist(cfg[[sublist]]))
    }
  }
  # 3. Compare against the actual dataframe
  vars_missing <- setdiff(vars_required, names(dataset))
  # 4. Stop if any are missing
  if(length(vars_missing) > 0) {
    cat(sprintf("\n\n!!! ERROR: The '%s' dataset is missing these variables:\n%s\n", 
                 config, 
                 paste(vars_missing, collapse = ", ")))
  }
  cat(sprintf("✅ %s dataset validated: All %d required variables found (checked: %s).\n", 
              config, length(vars_required), paste(sublists_to_check, collapse=", ")))
}

check_data_participant_overlap <- function(data1_ids, data2_ids, data1_label, data2_label) {
  # 1. Calculate differences
  missing <- setdiff(data1_ids, data2_ids) # in data1, not in data2
  extra   <- setdiff(data2_ids, data1_ids) # in data2, not in data1
  # 2. Header
  cat(sprintf("\nComparing %s (N=%d) vs %s (N=%d):\n", 
              data1_label, length(data1_ids), data2_label, length(data2_ids)))
  # 3. Check for match
  if(length(missing) == 0 && length(extra) == 0) {
    cat(sprintf("✅ All %s participants match %s participants.\n",data1_label, data2_label))
  } else {
    # 4. report discrepancies
    if (length(missing) > 0) {
      cat(sprintf("⚠️ WARNING: %d participants are in %s but MISSING from %s:\n", 
                  length(missing), data1_label, data2_label))
      print(missing)
    }
    if(length(extra) > 0) {
      cat(sprintf("⚠️ WARNING: %d participants in %s are NOT in %s)\n", 
                  length(extra), data2_label, data1_label))
      print(extra)
    }
  }
}

print_header <- function(text, level = 2) {
  if (level == 2) {
    cat("\n")
    cat(paste("--- ", text, " ---"), "\n")
    cat(paste0(rep("-", 60), collapse = ""), "\n")
  } else {
    cat("\n")
    cat(paste0(rep("=", 60), collapse = ""), "\n")
    cat(paste("  ", toupper(text)), "\n")
    cat(paste0(rep("=", 60), collapse = ""), "\n")
  }
}

check_mc_consistency <- function(var,no_resp, not_no_resp) {
  cat(paste0("\nLogical Consistency of '", var, "' (Mutually Exclusive MC Answers)\n"))
  inconsistent <- esm_data %>%
    select(all_of(col_person), all_of(col_beep), all_of(var)) %>%
    mutate(
      no  = grepl(no_resp, as.character(.data[[var]])),
      not_no = grepl(not_no_resp, as.character(.data[[var]]))
    ) %>%
    filter(no & not_no)
  
  if(nrow(inconsistent) > 0) {
    cat(sprintf("⚠️ WARNING: %d rows contain contradictory multiple choice answers.\n",
                nrow(inconsistent)))
    print(inconsistent)
  } else {
    cat("✅ All ", var," responses are logically consistent.\n\n")
  }
}

check_branch_consistency <-  function(is_gate_open, vars_conditional, label) {
  # rows where gate is closed but data exists in conditional items
  leaking_rows <- esm_data %>%
    # NOTE: We use %in% TRUE to handle NAs safely. 
    # !(... %in% TRUE) means "The condition is either FALSE or NA" (i.e., not explicitly met).
    filter(! (is_gate_open %in% TRUE)) %>%
    filter(if_any(all_of(vars_conditional), ~ !is.na(.)))
  if(nrow(leaking_rows) > 0) {
    cat(sprintf("⚠️ WARNING: %d rows contain '%s' data despite closed gate.\n",
                nrow(leaking_rows), label))
    # Show which specific variables are leaking
    cat("   Violating variables found in these rows:\n")  
    leaking_rows %>%
      select(all_of(vars_conditional)) %>%
      summarise(across(everything(), ~sum(!is.na(.)))) %>%
      pivot_longer(everything(), names_to = "Variable", values_to = "Illegal_Entries") %>%
      filter(Illegal_Entries > 0) %>%
      print()
  } else {cat("✅ Conditional" , label,  "logic is consistent.\n")
  }
}

save_plot <- function(plot_obj, filename, w=10, h=8) {
  # 1. Create prefix (e.g., "01_", "02_")
  prefix <- sprintf("%02d_", plot_counter) 
    # 2. Update filename
  new_filename <- paste0(prefix, filename)
  full_path <- file.path(plots_dir, new_filename)
    # 3. Save
  ggsave(full_path, plot_obj, width = w, height = h, bg = "white")
  cat(sprintf("✅ Saved: %s\n   Location: %s\n", new_filename, full_path))
    # 4. Increment counter globally
  plot_counter <<- plot_counter + 1
}

save_base_plot <- function(plot_code, filename, w=10, h=8) {
  # 1. Create prefix using global counter
  prefix <- sprintf("%02d_", plot_counter) 
  # 2. Update filename
  new_filename <- paste0(prefix, filename)
  full_path <- file.path(plots_dir, new_filename)
  # 3. Open PNG device
  png(filename = full_path, width = w, height = h, units = "in", res = 300)
  # 4. Execute the plotting code
  #    use 'force()' to ensure the code block runs inside the device
  force(plot_code)
  # 5. Close device
  dev.off()
  # 6. Log and Increment
  cat(sprintf("✅ Saved: %s\n   Location: %s\n", new_filename, full_path))
  plot_counter <<- plot_counter + 1
}

check_range <- function(data, vars, min_v, max_v, scale_name) {
  vars_present <- intersect(vars, names(data))
  vars_missing <- setdiff(vars, names(data))
  if(length(vars_present) == 0) {
    cat(sprintf("ℹ️  Note: No variables found for %s scale.\n", scale_name))
    return(NULL)
  }
  # Find values outside range (ignoring NA)
  out_of_bounds <- data %>%
    select(all_of(col_person), all_of(vars_present)) %>%
    filter(if_any(all_of(vars_present), ~ . < min_v | . > max_v))
  if(nrow(out_of_bounds) > 0) {
    cat(sprintf("⚠️  %s: %d rows have values outside range [%d, %d]\n", 
                scale_name, nrow(out_of_bounds), min_v, max_v))
  } else {
    if(length(vars_missing) == 0) {
      # Perfect: All items found + All valid
      cat(sprintf("✅ %s: All items found and values within codebook range [%d, %d]\n", 
                  scale_name, min_v, max_v))
    } else {
      # Partial Success: Found items are valid, but some are missing
      cat(sprintf("✅ %s: Existing items valid [%d, %d], but %d items missing (%s)\n", 
                  scale_name, min_v, max_v, length(vars_missing), 
                  paste(vars_missing, collapse=", ")))
    }  
  }
}

get_label <- function(data, col_name) {
  # 1. Retrieve the column name and the label map
  var_name <- CONFIG_BG$cols[[col_name]]
  lbls     <- CONFIG_BG$value_labels[[col_name]]
  # 2. Extract the data vector for var_name
  vec <- trimws(as.character(data[[var_name]]))
  # 3. Fix: If this is the medication column, treat NA as 0
  if (col_name == "col_med") {
    vec <- replace_na(vec, "0")
  }
  # 4. Return the Factor
  factor(vec, levels = names(lbls), labels = lbls)
}

freq_table <- function(data, var, sort_desc = TRUE) {
  data %>%
    mutate(value = .data[[var]]) %>%
    count(value, name = "n", sort = sort_desc) %>%
    mutate(pct = round(100 * n / sum(n), 1))
}

plot_hist_numeric <- function(data, var, title, xlab, binwidth = NULL) {
  df <- data %>%
    transmute(value = suppressWarnings(as.numeric(.data[[var]]))) %>%
    filter(!is.na(value))
  ggplot(df, aes(x = value)) +
    geom_histogram(binwidth = binwidth) +
    labs(title = title, x = xlab, y = "Count") +
    theme_minimal()
}

plot_bar_categorical <- function(data, var, title, xlab) {
  df <- data %>%
    transmute(category = fct_na_value_to_level(as.factor(.data[[var]]), level = "(Missing)")) %>%
    count(category, name = "n") %>%
    mutate(category = fct_reorder(category, n))
  ggplot(df, aes(x = category, y = n)) +
    geom_col() +
    coord_flip() +
    labs(title = title, x = xlab, y = "Count") +
    theme_minimal()
}

## ########################################################################### #
## ---- A. ESM DATA CHECKS -----------------------------------------------------
## ########################################################################### #

## ---- ```` ESM SETUP & VALIDATION ----------------------------------------
## --------------------------------------------------------------------------- -
print_header("A. ESM Data Checks", level = 1)

load_config("ESM")
validate_variables("ESM", esm_data)

## ---- ```` A1. ESM STRUCTURAL CHECKS -----------------------------------------
## --------------------------------------------------------------------------- -
print_header("A1. ESM Dataset Overview & Structure")

# 1. Dimensions and variables
str(esm_data, 
    list.len = ncol(esm_data), # Show ALL columns
    strict.width = "cut",      # FORCE single line (no wrapping!)
    give.attr = FALSE)         # Remove the messy attributes at the bottom
cat(sprintf("\nUnique Persons: %d\n", n_distinct(esm_data[[col_person]])))
cat(sprintf("Unique Dyads:   %d\n", n_distinct(esm_data[[col_dyad]])))

# 2. Check persons per dyad
cat("\nDyad Integrity:\n")
problem_dyads <- esm_data %>%
  group_by(.data[[col_dyad]]) %>%
  summarise(n_persons = n_distinct(.data[[col_person]])) %>%
  filter(n_persons != 2)

if(nrow(problem_dyads) == 0) {
  cat("✅ All dyads contain exactly 2 unique persons.\n")
} else {
  cat("⚠️ WARNING: The following dyads do not have exactly 2 persons:\n")
  print(problem_dyads)
}

# 3. Check beep counts
beeps_per_person <- esm_data %>% count(.data[[col_person]], name = "n_beeps")

cat("\nSummary of Total Beeps per Person (should be", expected_beeps, "):\n")
summary(beeps_per_person$n_beeps) %>% print()

unique_n <- unique(beeps_per_person$n_beeps)

if ((length(unique_n) == 1) && (unique_n == expected_beeps)) {
  cat("\n✅ All participants have" , expected_beeps, "rows/beeps.\n")
} else if (length(unique_n) == 1) {
  cat("\n⚠️ WARNING: All participants have the same number of beeps (", unique_n,
      "), but this differs from expected (", expected_beeps, ").\n", sep = "") 
} else {
  cat("\n⚠️ WARNING: Number of beeps VARIES between participants.\n")
}

cat("Distribution of Total Beeps (How many people have X beeps?):\n")
beeps_per_person %>% 
  count(n_beeps, name = "n_participants") %>% 
  print()

cat("\nCheck Missing Beeps: Which beep numbers are most frequently missing?\n")
beep_counts <- esm_data %>%
  count(.data[[col_beep]], name = "count_present") %>%
  mutate(missing_count = n_distinct(esm_data[[col_person]]) - count_present) %>%
  arrange(desc(missing_count)) %>%
  head(15) %>%
  print()

# 4. Check Total Beeps
outliers <- beeps_per_person %>% filter(n_beeps != expected_beeps)

if(nrow(outliers) > 0) {
  cat("\n\nTotal Beep Count Anomalies (Expected", expected_beeps,")\n")
  print(head(outliers, 10))
} else {
  cat("\n\n✅ Total Beep Check: All participants have exactly" , expected_beeps, "beeps.\n")
}

# 5. Check for duplicate beep numbers within persons
cat("\nCheck: Are beep numbers unique within persons?\n")
duplicates <- esm_data %>%
  group_by(.data[[col_person]], .data[[col_beep]]) %>%
  count() %>%
  filter(n > 1)

if(nrow(duplicates) == 0) {
  cat("✅ No duplicate beep numbers found within participants.\n")
} else {
  cat("⚠️ WARNING: Duplicate beep numbers found for specific persons (showing first 5):\n")
  print(head(duplicates, 5))
}

# 6. Response timestamp distribution (saved to plot)
cat("\n... Generating Response Timestamp Distribution ...\n")

plot_time <- esm_data %>%
  filter(.data[[col_start]] == 1) %>%
  mutate(
    hour_decimal = lubridate::hour(.data[[col_ts_start]]) + 
      (lubridate::minute(.data[[col_ts_start]]) / 60)
  ) %>%
  ggplot(aes(x = hour_decimal)) +
  geom_histogram(binwidth = 0.5, fill = "steelblue", color = "white") +
  scale_x_continuous(breaks = seq(0, 24, 1)) +
  coord_cartesian(xlim = c(0, 24)) +
  labs(title = "Distribution of Responses by Time of Day (Half Hour Buckets)",
       x = "Hour of Day (0-24)", y = "Count of Beeps") +
  theme_minimal()

save_plot(plot_time, "ESM_response_time_dist.png")

# 7. Timestamp Order Check 
cat("\nTimestamp Logic (Scheduled < Sent < Start < Stop):\n")

logic_failures <- esm_data %>%
  filter(.data[[col_end]] == 1) %>% # Only check completed beeps
  filter(
    (.data[[col_ts_sent]] < .data[[col_ts_sched]]) |
      (.data[[col_ts_start]] < .data[[col_ts_sent]]) | 
      (.data[[col_ts_stop]] < .data[[col_ts_start]])
  ) %>%
  select(all_of(col_person), all_of(col_beep), all_of(vars_time))

if(nrow(logic_failures) == 0) {
  cat("✅ SUCCESS: All completed beeps follow logical timestamp order.\n")
} else {
  cat(sprintf("⚠️ WARNING: %d beeps have illogical timestamps:\n", nrow(logic_failures)))
  print(logic_failures)
}

# 8. Multiple choice consistency check

#    partner_contact 1 (No) should be mutually exclusive from 2-4 (Yes contact).
check_mc_consistency(col_part_cont, "1", "[234]")

#    presence_others 7 (Nobody) should be mutually exclusive from 1-6
check_mc_consistency(col_pres_oth, "7", "[123456]")

#    contact_others 7 (Nobody) should be mutually exclusive from 1-6
check_mc_consistency(col_cont_oth, "7", "[123456]")

## ---- ```` A2. ESM CONDITIONAL ITEM CHECKS -----------------------------------
## --------------------------------------------------------------------------- -
print_header("A2. ESM: Conditional Item Checks")

# 1. Orphaned 'partner_contact' check
#    'partner_contact' can only have data if 'partner_presence' == 0 (=no)
cat(paste0("\nCheck 1: Does '", col_part_cont, "' have data while '",
           col_part_pres, "' is 'yes' or missing?\n"))

invalid_contact <- esm_data %>%
  filter(
    !is.na(.data[[col_part_cont]]) &       # partner_contact has data...
      ! (.data[[col_part_pres]] %in% 0)    # ...but presence is NOT 0 (covers 1 and NA)
  )

if(nrow(invalid_contact) > 0) {
  cat(sprintf("⚠️ WARNING: %d rows have %s data while %s is 'yes' or missing.\n", 
              nrow(invalid_contact), col_part_cont, col_part_pres))
  print(head(invalid_contact))
} else {
  cat("✅ No invalid or orphaned partner_contact data found.\n")
}

# 2. Partner branch leakage check
#    The variables in vars_branch_partner are asked ONLY IF
#    partner is present or if there was contact since last beep.
cat("\nCheck 2: 'Partner Branch' variables present without valid trigger?\n")
cat("   (Trigger: partner_presence=1 OR partner_contact contains 2,3, or 4)\n")

#    is_*_gate_open is logical vector (an element per beep) containing if the
#    participant was allowed to answer the branched items
#    NOTE: 'partner_contact' is multiple choice (e.g., "24" = texted and saw each other).
#         We check if specific digits appear in the string using regex (grepl).
is_partner_gate_open <- (esm_data[[col_part_pres]] == 1) | 
  grepl("[234]", as.character(esm_data[[col_part_cont]]))

check_branch_consistency(is_partner_gate_open, vars_branch_partner, 
                         "'Partner Branch'")

# 3. No-partner branch leakage check
#    The variables in vars_branch_no_partner are asked ONLY IF 
#    (Partner Present == 0 = no) AND (Contact since last beep == 1 "No").
#    Error: A conditional item has data, but the gate conditions are NOT met.
cat("\nCheck 3: 'No-partner Branch' variables present without valid trigger?\n")
cat("   (Trigger: partner_presence=0 AND partner_contact=1)\n")

is_general_gate_open <- (esm_data[[col_part_pres]] == 0) & 
  grepl("1", as.character(esm_data[[col_part_cont]]))

check_branch_consistency(is_general_gate_open, vars_branch_no_partner, 
                         "'No-partner Branch'")

## ---- ```` A3. ESM SCHEDULE CHECKS -------------------------------------------
## --------------------------------------------------------------------------- -
print_header("A3. ESM: Protocol Schedule Compliance")

# 1. Calculate beeps per day and determine day type
daily_counts <- esm_data %>% 
  mutate(
    date_val = as.Date(.data[[col_ts_sent]]),
    # wday: 1=Sunday, 7=Saturday
    day_num  = lubridate::wday(date_val), 
    day_type = if_else(day_num %in% c(1, 7), "Weekend", "Weekday")
  ) %>%
  count(.data[[col_person]], .data[[col_dyad]], date_val, day_type, name = "n_beeps")

# 2. Check patterns per person
#    Expected: 10 Weekdays (with 5 beeps) and 4 Weekend days (with 10 beeps)
schedule_compliance <- daily_counts %>%
  group_by(.data[[col_person]], .data[[col_dyad]]) %>%
  summarise(
    n_valid_weekdays = sum(day_type == "Weekday" & n_beeps == 5),
    n_valid_weekends = sum(day_type == "Weekend" & n_beeps == 10),
    n_invalid_days   = sum((day_type == "Weekday" & n_beeps != 5) | 
                             (day_type == "Weekend" & n_beeps != 10)),
    total_days       = n(),
    .groups = "drop"
  )

# 3. Aggregated Summary (Pattern-based)
schedule_patterns <- schedule_compliance %>%
  count(n_valid_weekdays, n_valid_weekends, n_invalid_days, total_days, name = "n_participants") %>%
  arrange(desc(n_participants))

cat("\nSchedule Adherence Patterns\n")
cat("Target: 10 valid weekdays + 4 valid weekend days (0 invalid, 14 total)\n\n")
print(schedule_patterns)

# 4. Identify deviations
#    Filter for anyone who is NOT perfectly following the protocol
deviants <- schedule_compliance %>%
  filter(n_invalid_days > 0 | total_days != 14) %>%
  select(all_of(col_person), all_of(col_dyad), n_invalid_days, total_days) %>%
  arrange(desc(n_invalid_days))

if(nrow(deviants) > 0) {
  cat("\n\n⚠️  Participants with Schedule Deviations\n")
  cat("Listing PpIDs with Invalid Days != 0 OR Total Days != 14:\n\n")
  print(deviants, n = Inf) 
} else {
  cat("\n\n✅ No deviations found. All participants follow the 14-day schedule perfectly.\n")
}

## ---- ```` A4. ESM MISSINGNESS ANALYSIS --------------------------------------
## --------------------------------------------------------------------------- -
print_header("A4. ESM: Missingness")

# 1. General missingness
cat(sprintf("\nGeneral dataset missingness: %.2f%%\n", pct_miss(esm_data)))
cat("\nTop 10 general variables missingness\n")
print(miss_var_summary(esm_data) %>% head(10))

# 2. Total core variables data missingness
pct_core <- esm_data %>%
  select(all_of(vars_affect)) %>%
  pct_miss()
cat(sprintf("\nTotal core dataset missingness: %.2f%%\n", pct_core))
cat("\nTop 10 core variables missingness\n")
subset_core <- esm_data %>% select(all_of(vars_affect))
print(miss_var_summary(subset_core) %>% head(10))

# 3. Beep completion
cat("\nBeep completion stats:\n")
completion_stats <- esm_data %>%
  summarise(
    Total_Rows = n(),
    Started = sum(.data[[col_start]] == 1, na.rm = TRUE),
    Completed = sum(.data[[col_end]] == 1, na.rm = TRUE),
    Started_But_Incomplete = sum(.data[[col_start]] == 1 & .data[[col_end]] == 0, na.rm = TRUE)
  )
print(completion_stats)
cat(sprintf("Percentage of started beeps that were NOT completed: %.2f%%\n", 
            (completion_stats$Started_But_Incomplete / completion_stats$Started) * 100))

# 4. Missingness Map (saved as plot)
cat("\n... Generating Missingness Heatmap (this may take a moment) ...\n")

plot_miss <- naniar::vis_miss(esm_data, warn_large_data = FALSE) +
  theme(axis.text.x = element_text(angle = 90)) +
  labs(title = "Missingness Map (Black = Missing)")

save_plot(plot_miss, "ESM_missingness_map.png")


## ---- ```` A5. ESM COMPLIANCE ANALYSIS ---------------------------------------
## --------------------------------------------------------------------------- -
print_header("A5. ESM: Compliance Analysis")

# 1. Calculate Compliance per Person (as Percentage 0-100)
person_compliance <- esm_data %>%
  group_by(.data[[col_person]]) %>%
  summarise(
    n_total   = n(),
    comp_rate = mean(.data[[col_compl]], na.rm = TRUE) * 100, 
    .groups   = "drop"
  )

# 2. Summary statistics
cat("\nSummary statistics for Participant Compliance Rates (%):\n")
summary(person_compliance$comp_rate) %>% print()

# 3. Compliance frequency table
thresholds <- seq(10, 100, by = 5)

counts_pass <- sapply(thresholds, function(x) {
  sum(person_compliance$comp_rate <= x)
})   # Calculate counts for each threshold

cumulative_table <- as.data.frame(t(counts_pass))
colnames(cumulative_table) <- c(paste0(" ≤", thresholds, "%"))
cat("\nParticipant Cumulative Distribution of Compliance Rates:\n")
print(cumulative_table) # Create and print 1-row summary table

# 4. Identify low compliers
low_compliers <- person_compliance %>% 
  filter(comp_rate < min_compliance) %>%
  arrange(comp_rate) # Participants below minimim compliance

cat(sprintf("\n⚠️ Participants with < %d%% compliance (Total: %d):\n",
            min_compliance, nrow(low_compliers)))
if(nrow(low_compliers) > 0) {
  print(head(low_compliers))
}

# 5. Compliance heatmap (saved as plot)
cat("\n... Generating Compliance Heatmap ...\n")

plot_comp_heatmap <- daily_counts %>%  # Uses object created in Section 3
  ggplot(aes(x = date_val, y = as.factor(.data[[col_person]]), fill = n_beeps)) +
  geom_tile(color = "white") +
  scale_fill_gradient(low = "red", high = "green", na.value = "grey90") +
  labs(title = "Daily Compliance Heatmap",
       x = "Study Date", y = "Participant ID", fill = "Beeps/Day") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 6)) 

save_plot(plot_comp_heatmap, "ESM_compliance_heatmap.png")

# 6. Normalized compliance heatmap (saved as plot)
cat("\n... Generating Normalized Compliance Heatmap ...\n")

#   Normalize time so everyone starts at "Day 1"
esm_relative <- esm_data %>%
  arrange(.data[[col_person]], .data[[col_ts_sent]]) %>%
  group_by(.data[[col_person]]) %>%
  mutate(
    # 1. Study Day: Day 1 is the participant's first day
    start_date = min(as.Date(.data[[col_ts_sent]]), na.rm = TRUE),
    current_date = as.Date(.data[[col_ts_sent]]),
    study_day = as.numeric(difftime(current_date, start_date, units = "days")) + 1,
        # 2. Daily Beep Number: 1 to 10 (or 5) within that specific day
    beep_daily_num = ave(as.numeric(.data[[col_ts_sent]]), current_date, FUN = seq_along)
  ) %>%
  ungroup()

plot_norm_comp_heatmap <- esm_relative %>%
  # Summarize compliance per Study Day
  group_by(.data[[col_person]], study_day) %>%
  summarise(
    n_beeps = n(),
    n_complete = sum(.data[[col_end]] == 1, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  ggplot(aes(x = factor(study_day), y = factor(.data[[col_person]]), fill = n_complete)) +
  geom_tile(color = "white") +
  scale_fill_gradient(low = "red", high = "green", na.value = "grey95") +
  labs(title = "Normalized Compliance Heatmap",
       x = "Study Day (1 - 14+)", 
       y = "Participant ID", 
       fill = "Completed") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 5))

save_plot(plot_norm_comp_heatmap, "ESM_compliance_heatmap_normalized.png")

# 7. Fatigue heatmap
cat("\n... Generating Fatigue Heatmap  ...\n")

main_grid <- esm_relative %>%
  filter(study_day <= 14) %>% # exclude 1 couple's day 15 data
  group_by(study_day, beep_daily_num) %>%
  summarise(
    pct_complete = mean(.data[[col_end]], na.rm = TRUE) * 100,
    .groups = "drop"
  ) %>%
  mutate(
    day_label = as.character(study_day),
    beep_label = as.character(beep_daily_num)
  )

#  Calculate Row Averages (Avg compliance per Day)
row_avgs <- main_grid %>%
  group_by(day_label) %>%
  summarise(pct_complete = mean(pct_complete), .groups = "drop") %>%
  mutate(beep_label = "Day Avg") 

#  Calculate Column Averages (Avg compliance per Beep slot)
col_avgs <- main_grid %>%
  group_by(beep_label) %>%
  summarise(pct_complete = mean(pct_complete), .groups = "drop") %>%
  mutate(day_label = "Beep Avg")

#  Calculate Grand Mean (corner cell)
grand_avg <- tibble(
  day_label = "Beep Avg",   # Matches the label used in col_avgs
  beep_label = "Day Avg",   # Matches the label used in row_avgs
  pct_complete = mean(main_grid$pct_complete, na.rm = TRUE)
)

# Plot
plot_data <- bind_rows(main_grid, row_avgs, col_avgs, grand_avg)

level_x <- c(as.character(1:10), "Day Avg")
level_y <- c(as.character(1:14), "Beep Avg")

plot_fatigue_avg <- plot_data %>%
  mutate(
    beep_label = factor(beep_label, levels = level_x),
    day_label = factor(day_label, levels = level_y)
  ) %>%
  ggplot(aes(x = beep_label, y = day_label, fill = pct_complete)) +
  geom_tile(color = "white") +
  geom_text(aes(label = round(pct_complete, 0)), color = "black", size = 3) +
  scale_color_identity() + 
  scale_fill_gradient2(
    low = "red",     
    # mid = "white,        
    high = "forestgreen",  
    midpoint = 75,         
    limits = c(0, 100)
  ) +
  geom_vline(xintercept = 10.5, linewidth = 0.5, color = "grey50") +
  geom_hline(yintercept = 14.5, linewidth = 0.5, color = "grey50") +
  labs(title = "Compliance Fatigue Map with Marginal Averages",
       subtitle = "Numbers show daily/beep average compliance (%)",
       x = "Beep Sequence ( + Daily Avg)", 
       y = "Study Day ( + Beep Avg)", 
       fill = "% Compliance") +
  theme_minimal()

save_plot(plot_fatigue_avg, "ESM_fatigue_map.png")

## ---- ```` A6. ESM PARTNER BEEP SYNCHRONIZATION ------------------------------
## --------------------------------------------------------------------------- -

print_header("A6. ESM: Dyadic Beep Synchronization")

# 1. Create Dyadic Dataset (Self vs Partner) for timestamps
p1 <- esm_data %>% 
  filter(.data[[col_part_no]] == 1) %>% 
  select(all_of(col_dyad), all_of(col_beep), start_p1 = all_of(col_ts_start))

p2 <- esm_data %>% 
  filter(.data[[col_part_no]] == 2) %>% 
  select(all_of(col_dyad), all_of(col_beep), start_p2 = all_of(col_ts_start))

dyadic_sync <- inner_join(p1, p2, by = c(col_dyad, col_beep)) %>%
  mutate(
    diff_start_mins = abs(as.numeric(difftime(start_p1, start_p2, units = "mins")))
  ) %>%
  filter(!is.na(diff_start_mins))

cat("\nSummary of time difference between partners starting the SAME beep (mins):\n")
summary(dyadic_sync$diff_start_mins) %>% print()

# 2. Calculate Cumulative Counts (<=1, <=2, ... <=15) and >15
thresholds <- 1:15

# Calculate cumulative counts for each threshold
counts_cumulative <- sapply(thresholds, function(x) {
  sum(dyadic_sync$diff_start_mins <= x, na.rm = TRUE)
})

# Calculate count for > 15
count_over_15 <- sum(dyadic_sync$diff_start_mins > 15, na.rm = TRUE)

# Format into a 1-row table
sync_table <- as.data.frame(t(c(counts_cumulative, count_over_15)))
colnames(sync_table) <- c(paste0("≤", thresholds), ">15")

cat("\nCumulative count of dyadic beeps started within X minutes:\n")
print(sync_table)

# 3. Calculate Cumulative Percentages (<=1, <=2, ... <=15) and >15
n_total <- nrow(dyadic_sync) # Total valid dyadic pairs

sync_table_pct <- round((sync_table/n_total)*100,1)
colnames(sync_table_pct) <- c(paste0("≤", thresholds, "m"), ">15m")

cat(sprintf("\nCumulative percentage of dyadic beeps started within X minutes (N=%d):\n", n_total))
print(sync_table_pct)

## ---- ```` ESM CLEANUP ------------------------------------------------------
## --------------------------------------------------------------------------- -
clean_config("ESM") # Remove ESM-specific configuration variables

## ########################################################################### #
## ---- B. BG DATA CHECKS ------------------------------------------------------
## ########################################################################### #

## ---- ```` BG SETUP & VALIDATION ---------------------------------------------
## --------------------------------------------------------------------------- -
print_header("B. Background Questionnaires Data Checks", level = 1)

load_config("BG")
validate_variables("BG", bg_data)

## ---- ```` B1. BG STRUCTURAL CHECKS-------------------------------------------
## --------------------------------------------------------------------------- -
print_header("B1. BG Structural Checks")

# 1. Dimensions and variables
str(bg_data, 
    list.len = ncol(bg_data), # Show ALL columns
    strict.width = "cut",      # FORCE single line (no wrapping!)
    give.attr = FALSE)         # Remove the messy attributes at the bottom
cat(sprintf("\nUnique Persons: %d\n", n_distinct(esm_data[[col_person]])))
cat(sprintf("Unique Dyads:   %d\n", n_distinct(esm_data[[col_dyad]])))

# 2. Scale Range Checks
scale_names <- names(CONFIG_BG$scales)
for(name in scale_names) {
  # Get the items from the config
  items <- CONFIG_BG$scales[[name]]
  # Find the matching limit
  limit_name <- sub("scale_", "limits_", name)
  limits     <- CONFIG_BG$ranges[[limit_name]]
  # Run check
  check_range(bg_data, items, limits[1], limits[2], name)
}

## ---- ```` B2. BG DESCRIPTIVES (DEMOGRAPHICS) -------------------------------
## --------------------------------------------------------------------------- -
print_header("B2. BG Descriptive statistics (demographics)")

# 1. AGE (numeric)
cat("\nAge (years):\n")
age <- suppressWarnings(as.numeric(bg_data[[col_age]]))
print(summary(age))
cat(sprintf("Missing age: %d\n", sum(is.na(age))))
plot_age <- bg_data %>%
  mutate(age = suppressWarnings(as.numeric(.data[[col_age]]))) %>%
  filter(!is.na(age)) %>%
  ggplot(aes(x = age)) +
  geom_histogram(binwidth = 2) +
  labs(title = "BG: Age distribution", x = "Age (years)", y = "Count") +
  theme_minimal()
save_plot(plot_age, "BG_age_hist.png")

# 2. GENDER
cat("\nGender:\n")
# Pass "col_gender" (the key). The function finds the real column "gender".
df_temp <- bg_data %>% transmute(val = get_label(., "col_gender"))
print(freq_table(df_temp, "val"))
save_plot(plot_bar_categorical(df_temp, "val", "BG: Gender", "Gender"), 
          "BG_gender_bar.png")

# 3. NATIONALITY
cat("\nNationality:\n")
df_temp <- bg_data %>% transmute(val = get_label(., "col_nat"))
print(freq_table(df_temp, "val"))
save_plot(plot_bar_categorical(df_temp, "val", "BG: Nationality", "Nationality"),
          "BG_nationality_bar.png", w = 10, h = 6)

# 4. ETHNICITY
cat("\nEthnicity:\n")
df_temp <- bg_data %>% transmute(val = get_label(., "col_etn"))
print(freq_table(df_temp, "val"))
save_plot(plot_bar_categorical(df_temp, "val", "BG: Ethnicity", "Ethnicity"),
          "BG_ethnicity_bar.png", w = 10, h = 6)

# 5. EDUCATION
cat("\nEducation:\n")
df_temp <- bg_data %>% transmute(val = get_label(., "col_edu"))
print(freq_table(df_temp, "val"))
save_plot(plot_bar_categorical(df_temp, "val", "BG: Education", "Education"),
          "BG_education_bar.png", w = 10, h = 6)

# 6. CHILDREN
cat("\nChildren (YN):\n")
df_temp <- bg_data %>% transmute(val = get_label(., "col_child"))
print(freq_table(df_temp, "val"))
save_plot(plot_bar_categorical(df_temp, "val", "BG: Children", "Children"),
          "BG_children_bar.png", w = 8, h = 5)

# 7. LIVING TOGETHER
cat("\nLiving together:\n")
df_temp <- bg_data %>% transmute(val = get_label(., "col_liv_tog"))
print(freq_table(df_temp, "val"))
save_plot(plot_bar_categorical(df_temp, "val", "BG: Living together", "Living together"),
          "BG_living_together_bar.png", w = 8, h = 5)

# 8. RELATIONSHIP DURATION (Numeric - months)
cat("\nRelationship duration (months):\n")
rel_dur <- suppressWarnings(as.numeric(bg_data[[col_rel_dur]]))
print(summary(rel_dur))
cat(sprintf("Missing relationship duration: %d\n", sum(is.na(rel_dur))))
plot_rel_dur <- bg_data %>%
  mutate(rel_dur = suppressWarnings(as.numeric(.data[[col_rel_dur]]))) %>%
  filter(!is.na(rel_dur)) %>%
  ggplot(aes(x = rel_dur)) +
  geom_histogram(binwidth = 6, fill = "steelblue", color = "white") +
  labs(title = "BG: Relationship Duration Distribution", 
       x = "Duration (Months)", 
       y = "Count") +
  theme_minimal()

save_plot(plot_rel_dur, "BG_rel_duration_hist.png")

# 9. MEDICATION
cat("\nMedication:\n")
# The NA fix is now safely hidden inside get_label
df_temp <- bg_data %>% transmute(val = get_label(., "col_med"))

print(freq_table(df_temp, "val"))
save_plot(plot_bar_categorical(df_temp, "val", "BG: Medication", "Medication Status"),
          "BG_medication_bar.png", w = 8, h = 5)

## ---- ```` B3. DCI DETAILED ANALYSIS (TOTAL & WE-NESS) -----------------------
## --------------------------------------------------------------------------- -
print_header("B3. DCI: Total Score, Reliability, & We-ness")

# 1. DEFINE ITEMS & SUBSCALES

# Load negative indices from Config:dci_neg_indices
dci_neg_items <- paste0("DCI", dci_neg_indices)

# Positive "We-ness" items (All items MINUS the negative ones)
dci_we_items  <- setdiff(scale_DCI, dci_neg_items)

# --- 2. CALCULATE TOTAL DCI (Including Flipped Negative Items) ---
# We need a temporary dataframe to handle the reverse coding safely# Ensure numeric

# Reverse Code the negative items (Scale 1-5 becomes 6-x)
dci_reversed <- bg_data %>%
  select(all_of(col_dyad), 
         all_of(col_person), 
         all_of(scale_DCI)) %>%
  mutate(across(all_of(scale_DCI), ~ as.numeric(.))) %>%
  mutate(across(all_of(dci_neg_items), ~ 6 - .))

# Calculate Total Score
dci_scores <- dci_reversed %>%
  mutate(
    DCI_Total_Score = rowSums(select(., all_of(scale_DCI)), na.rm = FALSE),
    We_Ness_Score   = rowSums(select(., all_of(dci_we_items)), na.rm = FALSE)
  )

# --- 3. RELIABILITY (Alpha & Omega) ---
  cat("\n=== RELIABILITY CHECK (Total DCI - 30 items) ===\n")
  
  # A. Cronbach's Alpha
  cat("\n--- Cronbach's Alpha ---\n")
  # We use the dataset where negative items are ALREADY flipped
  alpha_res <- alpha(dci_reversed %>% select(all_of(scale_DCI)))
  print(round(alpha_res$total, 3)) 
  
  # B. McDonald's Omega
  cat("\n--- McDonald's Omega ---\n")
  # Omega is computationally heavier; we suppress plot output
  # 'nfactors = 1' assumes we are checking a single global construct
  omega_res <- suppressMessages(omega(dci_reversed %>% select(all_of(scale_DCI)), 
                                             nfactors = 3, plot = FALSE))
  print(round(omega_res$omega.tot, 3)) 

# 4. VISUALIZE TOTAL DCI SCORES
plot_dci_total_hist <- dci_scores %>%
  filter(!is.na(DCI_Total_Score)) %>%
  ggplot(aes(x = DCI_Total_Score)) +
  geom_histogram(binwidth = 5, fill = "steelblue", color = "white") +
  labs(title = "Distribution of Total DCI Scores", 
       subtitle = "Sum of 30 items (Negative items reversed)",
       x = "Total Score", y = "Count") +
  theme_minimal()

save_plot(plot_dci_total_hist, "BG_DCI_Total_Hist.png")

# 5. DYADIC CORRELATION (TOTAL SCORE)
# Reshape to wide format
dci_dyadic <- dci_scores %>%
  group_by(.data[[col_dyad]]) %>%
  filter(n() == 2) %>% # Ensure complete dyads
  mutate(partner_num = rank(.data[[col_person]])) %>%
  select(all_of(col_dyad), partner_num, DCI_Total_Score, We_Ness_Score) %>%
  pivot_wider(
    names_from = partner_num, 
    values_from = c(DCI_Total_Score, We_Ness_Score),
    names_glue = "{.value}_P{partner_num}" # Creates DCI_Total_Score_P1, etc.
  )

# Calculate Correlation
cor_total <- cor(dci_dyadic$DCI_Total_Score_P1, dci_dyadic$DCI_Total_Score_P2, use = "complete.obs")
cat(sprintf("\nDyadic Correlation (Total DCI): r = %.3f\n", cor_total))

# Plot Scatter (Visualizing the correlation)
plot_dci_total_corr <- dci_dyadic %>%
  ggplot(aes(x = DCI_Total_Score_P1, y = DCI_Total_Score_P2)) +
  geom_point(alpha = 0.6) +
  geom_smooth(method = "lm", color = "blue", se = FALSE) +
  labs(title = "Dyadic Correlation: Total DCI",
       subtitle = paste0("Pearson r = ", round(cor_total, 3)),
       x = "Partner 1 Score", y = "Partner 2 Score") +
  theme_minimal()

save_plot(plot_dci_total_corr, "BG_DCI_Total_Scatter.png")

# 6. WE-NESS SCORE ANALYSIS
cat("\n=== WE-NESS SCORE ANALYSIS (Positive Items Only) ===\n")

# Histogram of Personal We-ness
plot_weness_hist <- dci_scores %>%
  filter(!is.na(We_Ness_Score)) %>%
  ggplot(aes(x = We_Ness_Score)) +
  geom_histogram(binwidth = 5, fill = "forestgreen", color = "white") +
  labs(title = "Distribution of 'We-ness' Scores", 
       subtitle = "Sum of Positive items only (No negative items)",
       x = "We-ness Score", y = "Count") +
  theme_minimal()

save_plot(plot_weness_hist, "BG_Weness_Hist.png")

# Dyadic Correlation We-ness
cor_weness <- cor(dci_dyadic$We_Ness_Score_P1, dci_dyadic$We_Ness_Score_P2, use = "complete.obs")
cat(sprintf("Dyadic Correlation (We-ness): r = %.3f\n", cor_weness))

# Plot Scatter We-ness
plot_weness_corr <- dci_dyadic %>%
  ggplot(aes(x = We_Ness_Score_P1, y = We_Ness_Score_P2)) +
  geom_point(alpha = 0.6, color = "darkgreen") +
  geom_smooth(method = "lm", color = "black", se = FALSE) +
  labs(title = "Dyadic Correlation: We-ness",
       subtitle = paste0("Pearson r = ", round(cor_weness, 3)),
       x = "Partner 1 We-ness", y = "Partner 2 We-ness") +
  theme_minimal()

save_plot(plot_weness_corr, "BG_Weness_Scatter.png")

# 7. PARTNER DIFFERENCES
cat("\n=== PARTNER DISCREPANCY ANALYSIS ===\n")

# Calculate Absolute Difference in We-ness
dci_dyadic <- dci_dyadic %>%
  mutate(
    Weness_Diff = abs(We_Ness_Score_P1 - We_Ness_Score_P2)
  )

cat("Summary of Absolute Differences in We-ness:\n")
summary(dci_dyadic$Weness_Diff) %>% print()

# Plot Histogram of Differences
plot_weness_diff <- dci_dyadic %>%
  filter(!is.na(Weness_Diff)) %>%
  ggplot(aes(x = Weness_Diff)) +
  geom_histogram(binwidth = 2, fill = "firebrick", color = "white") +
  labs(title = "Distribution of We-ness Discrepancies", 
       subtitle = "Absolute difference between Partner 1 and Partner 2",
       x = "Difference Score (|P1 - P2|)", y = "Count of Couples") +
  theme_minimal()

save_plot(plot_weness_diff, "BG_Weness_Diff_Hist.png")

# 8. HIERARCHICAL CHECK FOR WE-NESS (Validation)
  cat("\n=== HIERARCHICAL FACTOR ANALYSIS: WE-NESS (Positive Items Only) ===\n")
  cat("Checking if positive items form a stronger general factor than the full DCI...\n\n")
  
  # Select only the We-ness items
  weness_data <- bg_data %>%
    select(all_of(dci_we_items)) %>%
    mutate(across(everything(), as.numeric))
  
  # Run Omega with 3 factors (Theoretical: Own Provided Support, Perceived Partner Support, Stress Comm)
  save_base_plot({
    omega_weness <<- psych::omega(weness_data, nfactors = 3, plot = TRUE)
  }, filename = "BG_Weness_Omega_Structure.png")
  
  print(omega_weness)
  
  # specific print for the summary stats we care about
  cat(sprintf("\n--- KEY RESULTS ---\nOmega Total (Reliability): %.2f\nOmega Hierarchical (Unidimensionality): %.2f\n", 
              omega_weness$omega.tot, 
              omega_weness$omega_h))
  
  if(omega_weness$omega_h > 0.50) {
    cat("✅ RESULT: Good! The general 'We-ness' factor explains a majority of the variance.\n")
  } else {
    cat("ℹ️  NOTE: The subscales (Self vs Partner) are still very distinct even without negative items.\n")
  }

## ---- ```` BG CLEANUP --------------------------------------------------------
## --------------------------------------------------------------------------- -
clean_config("BG") # Remove BG-specific configuration variables

## ########################################################################### #
## ---- C. VMR DATA CHECKS -----------------------------------------------------
## ########################################################################### #

## ---- ```` VMR SETUP & VALIDATION ----------------------------------------
## --------------------------------------------------------------------------- -
print_header("C. VMR Data Checks", level = 1)

load_config("VMR")
validate_variables("VMR", vmr_data)

## ---- ```` VMR CLEANUP -------------------------------------------------------
## --------------------------------------------------------------------------- -
clean_config("VMR") # Remove VMR-specific configuration variables

## ########################################################################### #
## ---- D. POST DATA CHECKS ----------------------------------------------------
## ########################################################################### #

## ---- ```` POST SETUP & VALIDATION -------------------------------------------
## --------------------------------------------------------------------------- -
print_header("D. Post Interaction Questionnaire Data Checks", level = 1)

load_config("POST")
validate_variables("POST", post_data)

## ---- ```` POST CLEANUP -------------------------------------------------------
## --------------------------------------------------------------------------- -
clean_config("POST") # Remove POST-specific configuration variables

## ########################################################################### #
## ---- E. CROSS-DATASET CHECKS ------------------------------------------------
## ########################################################################### #

## ---- ```` CROSS-CHECK SETUP --------------------------------------------------
## --------------------------------------------------------------------------- -
# Load configs into local objects (no global environment conflicts)
print_header("E. Cross-Dataset Data Checks", level = 1)

# cfg_esm  <- load_config("ESM",  to_global = FALSE)
# cfg_bg   <- load_config("BG",   to_global = FALSE)
# cfg_vmr  <- load_config("VMR",  to_global = FALSE)
# cfg_post <- load_config("POST", to_global = FALSE)


## ---- ```` E1. PARTICIPANT ID CONSISTENCY -----------------------------------------
## --------------------------------------------------------------------------- -
print_header("Checking Participant ID Consistency across Datasets")

# 1. Extract PpIDs using the specific config map for each dataset
ids_esm  <- unique(esm_data[[CONFIG_ESM$cols$col_person]])
ids_bg   <- unique(bg_data[[CONFIG_BG$cols$col_person]])
ids_vmr  <- unique(vmr_data[[CONFIG_VMR$cols$col_person]])
ids_post <- unique(post_data[[CONFIG_POST$cols$col_person]])

# 3. Run the comparisons
if(!is.null(ids_esm) && !is.null(ids_bg))
  {check_data_participant_overlap(ids_esm, ids_bg, "ESM Data", "Background Data")}
if(!is.null(ids_vmr) && !is.null(ids_bg))   
  {check_data_participant_overlap(ids_vmr, ids_bg,"VMR Data", "Background Data")}
if(!is.null(ids_esm) && !is.null(ids_vmr))  
  {check_data_participant_overlap(ids_esm, ids_vmr,"ESM Data", "VMR Data")}
if(!is.null(ids_vmr) && !is.null(ids_post)) 
  {check_data_participant_overlap(ids_vmr, ids_post,"VMR Data", "Post-Interaction Data")}

## ---- ```` CROSS-CHECK CLEANUP ---------------------------------------------
## --------------------------------------------------------------------------- -
# Remove the local helper variables to keep environment clean
rm(ids_esm, ids_bg, ids_vmr, ids_post)
cat("\n✅ Cross-check environment cleaned.\n")

## ########################################################################### #
# ---- END ---------------------------------------------------------------------
## ########################################################################### #
print_header("End of Data Check Report", level = 1)

message(paste("Output log saved to:", log_file))
sink()