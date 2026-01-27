############################################################################# #
# 02_structure_checks.R
#
# Purpose:
# Data checks on the 4 imported datasets
#
# Usage:
# Run source("R/02_structure_checks.R") to see the report without code echoing.
# Assumes data is located in dir_data, afer running 01_data_import.R at least once
#       * data/imported/esm_raw.rds
#       * data/imported/esm_bg.rds
#       * data/imported/esm_vmr.rds
#       * data/imported/esm_post.rds
# Assumes that the output directories exist (e.g., via git clone)
# If not, these will as fallback be created during 00_setup.R
#       * outputs/plots (in dir_plots)
#       * outputs/logs (in dir_logs)
#
############################################################################## #

## ########################################################################### #
## ---- GLOBAL SETUP -----------------------------------------------------------
## ########################################################################### #

# 1. Load packages, paths and data configurations
source(here::here("R", "00_setup.R"))

# 2. Load datasets
esm_data <- readRDS(file.path(dir_data, "esm_raw.rds"))
bg_data <- readRDS(file.path(dir_data, "bg_raw.rds"))
vmr_data <- readRDS(file.path(dir_data, "vmr_raw.rds"))
post_data <- readRDS(file.path(dir_data, "post_raw.rds"))

# 3. Parameters
# ---- Global
log_file  = file.path(dir_logs, "02_data_checks_log.txt")
config_sublists_with_variables = c("cols", "vars", "scales")
plot_counter <- 1 # initialize start of plot numbering
# ---- ESM
min_compliance = 30
expected_beeps = 90 #    Expected = (10*5) + (4*10) = 90 beeps
# ---- VMR
expected_segments_per_topic = 16
expected_topics = c("positive", "negative")

# 4. Start logging
sink(file=log_file, append = FALSE, split = TRUE) # for cat and print
cat("============================================================\n")
cat("02_data_checks.R log\n")
cat("Log generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n", sep = "")
cat("Project root:  ", here::here(), "\n", sep = "")
cat("============================================================\n")

## ########################################################################### #
## ---- HELPER FUNCTIONS -------------------------------------------------------
## ########################################################################### #

header <- function(text, level = 3) {
    if (level == 1) {
    cat("\n")
    cat(paste0(rep("=", 60), collapse = ""), "\n")
    cat(paste("  ", toupper(text)), "\n")
    cat(paste0(rep("=", 60), collapse = ""), "\n")
  }
  if (level == 2) {
    cat("\n--- ", text, " ---\n")
    cat(paste0(rep("-", 60), collapse = ""), "\n")
  }
  if (level == 3) {
    cat("\n***", text, "\n")
  }
}

check_basic_structure <- function(data, label = "DATA") {
  # 1. Structure overview
  header(sprintf("%s dimensions and variables", label))
  str(data,
      list.len     = ncol(data),      # show ALL columns
      strict.width = "cut",           # force single line (no wrapping)
      give.attr    = FALSE)           # remove attributes at the bottom
  cat(sprintf("\nUnique Persons: %d\n", n_distinct(data[[col_person]])))
  cat(sprintf("Unique Dyads:   %d\n", n_distinct(data[[col_dyad]])))
  cat(sprintf("Total Rows:     %d\n", nrow(data)))
  cat(sprintf("Total Columns:  %d\n", ncol(data)))
  # 2. Dyad integrity check
  header(sprintf("%s Dyad Integrity", label))
  problem_dyads <- data %>%
    group_by(.data[[col_dyad]]) %>%
    summarise(n_persons = n_distinct(.data[[col_person]])) %>%
    filter(n_persons != 2)
  if (nrow(problem_dyads) == 0) {
    cat(sprintf("✅ %s: All dyads contain exactly 2 unique persons.\n", label))
  } else {
    cat(sprintf("⚠️ WARNING: %s: %d dyads do not have exactly 2 persons (showing first 10):\n",
                label, nrow(problem_dyads)))
    print(head(problem_dyads, 10))
  }
  # 3. Participant ID logic within dyad (<700 & >700)
  header(sprintf("%s Participant ID numbering logic within dyad", label))
  id_pattern <- data %>%
      distinct(.data[[col_dyad]], .data[[col_person]]) %>%
      group_by(.data[[col_dyad]]) %>%
      summarise(
        has_lt_700 = any(.data[[col_person]] < 700, na.rm = TRUE),
        has_gt_700 = any(.data[[col_person]] > 700, na.rm = TRUE)
      ) %>%
      filter(!(has_lt_700 & has_gt_700))
    
    if (nrow(id_pattern) == 0) {
      cat(sprintf("✅ %s: All dyads show the expected (<700 & >700) participant code pattern.\n", label))
    } else {
      cat(sprintf("⚠️ WARNING: %s: %d dyads do NOT show the expected (<700 & >700) pattern (showing first 10):\n",
                  label, nrow(id_pattern)))
      print(head(id_pattern, 10))
    }
  # Return diagnostics invisibly
  invisible(list(
    n_persons        = n_distinct(data[[col_person]]),
    n_dyads          = n_distinct(data[[col_dyad]]),
    n_rows           = nrow(data),
    n_cols           = ncol(data),
    problem_dyads    = problem_dyads
  ))
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

check_mc_consistency <- function(var,no_resp, not_no_resp) {
  header(sprintf("Logical Consistency of '%s' (Mutually Exclusive MC Answers)", var))
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
  # rows where gate is closed but data exists in conditional items in vars_conditional
  leaking_rows <- esm_data %>%
    # NOTE: We use %in% TRUE to handle NAs safely:
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
      pivot_longer(everything(), names_to = "Variable", values_to = "Irregular_Entries") %>%
      filter(Irregular_Entries > 0) %>%
      print()
  } else {cat("✅ Conditional" , label,  "logic is consistent.\n")
  }
}

save_plot <- function(plot_obj, filename, w=10, h=8) {
  # 1. Create prefix (e.g., "01_", "02_")
  prefix <- sprintf("%02d_", plot_counter) 
  # 2. Update filename
  new_filename <- paste0(prefix, filename)
  full_path <- file.path(dir_plots, new_filename)
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
  full_path <- file.path(dir_plots, new_filename)
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

check_range <- function(data, columns, min_v, max_v, name) {
  # check which columns exist in the data
  columns_present <- intersect(columns, names(data))
  columns_missing <- setdiff(columns, names(data))
  if(length(columns_present) == 0) {
    cat(sprintf("ℹ️  Note: No variables found for %s.\n", name))
    return(NULL)
  }
  # Find values outside range (ignoring NA) for columns/variables that are present
  out_of_bounds <- data %>%
    select(all_of(col_person), all_of(columns_present)) %>%
    filter(if_any(all_of(columns_present), ~ . < min_v | . > max_v))
  if(nrow(out_of_bounds) > 0) {
    cat(sprintf("⚠️  %s: %d rows have values outside range [%d, %d].\n", 
                name, nrow(out_of_bounds), min_v, max_v))
    cat(sprintf("    Printing 10 first:")) 
    print(head(out_of_bounds, 25))
  } else {
    if(length(columns_missing) == 0) {
      # Perfect: All items found + All valid
      cat(sprintf("✅ %s: All items found and values within codebook range [%d, %d]\n", 
                  name, min_v, max_v))
    } else {
      # Partial Success: Found items are valid, but some are missing
      cat(sprintf("⚠️ %s: Existing items valid [%d, %d], but %d items missing (%s)\n", 
                  name, min_v, max_v, length(columns_missing), 
                  paste(columns_missing, collapse=", ")))
    }
  }
}

check_missingness <- function (data) {
  # 1. General missingness
  header(sprintf("General dataset missingness: %.2f%%", pct_miss(data)))
  cat("Top 10 variables missingness\n")
  print(miss_var_summary(data) %>% head(10))
    # 2. Key identifier missingness
  header("Missing values in key identifiers (PpID, CoupleID):")
  key_na <- data %>%
    summarise(
      across(
        any_of(c("PpID", "CoupleID", "topic", "timepoint")),
        ~ sum(is.na(.x)),
        .names = "na_{.col}"
      )
    )
  print(key_na)
  if(all(key_na == 0)) {
    cat("✅ No missing values in key identifiers.\n")
  } else {
    cat("⚠️ WARNING: Missing values found in key identifiers.\n")
  }
  # 3. Total core (wrt present research) data missingness
  pct_core <- data %>%
    select(all_of(vars_core)) %>%
    pct_miss()
  header(sprintf("Total core dataset missingness: %.2f%%", pct_core))
  cat("Top 10 core variables missingness\n")
  subset_core <- data %>% select(all_of(vars_core))
  print(miss_var_summary(subset_core) %>% head(10))
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
header("A. ESM Data Checks", level = 1)

load_config("ESM")
validate_config("ESM", esm_data)

## ---- ```` A1. ESM STRUCTURAL CHECKS -----------------------------------------
## --------------------------------------------------------------------------- -
header("A1. ESM Dataset Overview & Structure", level = 2)

# 1. Basic structure and dyad integrity
check_basic_structure(esm_data, "ESM")

# 2. Check beep counts
header(sprintf("Beeps per Person (should be %d)", expected_beeps))
beeps_per_person <- esm_data %>% count(.data[[col_person]], name = "n_beeps")
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

header("Distribution of Beeps (How many people have X beeps?)")
beeps_per_person %>% count(n_beeps, name = "n_participants") %>% print()

header("Missing Beeps: Which beep numbers are missing?")
beep_counts <- esm_data %>%
  count(.data[[col_beep]], name = "count_present") %>%
  mutate(missing_count = n_distinct(esm_data[[col_person]]) - count_present) %>%
  filter(missing_count != 0) %>%
  arrange(desc(missing_count)) %>%
  print()

# 4. Check total beeps
outliers <- beeps_per_person %>% filter(n_beeps != expected_beeps)

if(nrow(outliers) > 0) {
  cat("\n\nBeep Count Anomalies (Expected", expected_beeps,")\n")
  print(head(outliers, 10))
} else {
  cat("\n\n✅ Total Beep Check: All participants have exactly" , expected_beeps, "beeps.\n")
}

# 5. Check for duplicate beep numbers within persons
header("Are beep numbers unique within persons?")
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
header("Responses Timestamp Distribution")

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
header("Timestamp Logic (Scheduled < Sent < Start < Stop)")

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
check_mc_consistency(var_part_cont, "1", "[234]")

#    presence_others 7 (Nobody) should be mutually exclusive from 1-6
check_mc_consistency(var_pres_oth, "7", "[123456]")

#    contact_others 7 (Nobody) should be mutually exclusive from 1-6
check_mc_consistency(var_cont_oth, "7", "[123456]")

## ---- ```` A2. ESM ITEM RANGE CHECKS -----------------------------------------
## --------------------------------------------------------------------------- -
header("A2. ESM Item Range Checks", level = 2)

# vars to check
var_names <- names(vars) 
for(name in var_names) {
  # Get the items from the config
  items <- vars[[name]]
  # Find the matching limit
  limit_name <- sub("var_", "limits_", name)
  limits     <- ranges[[limit_name]]
  # Run check
  check_range(esm_data, items, limits[1], limits[2], name)
}

## ---- ```` A3. ESM CONDITIONAL ITEM CHECKS -----------------------------------
## --------------------------------------------------------------------------- -
header("A3. ESM Conditional Item Checks", level = 2)

# 1. Orphaned 'partner_contact' check
#    'partner_contact' can only have data if 'partner_presence' == 0 (=no)
header(sprintf("Check 1: Does '%s' have data while '%s' is 'yes' or missing?",
               var_part_cont, var_part_pres ))

invalid_contact <- esm_data %>%
  filter(
    !is.na(.data[[var_part_cont]]) &       # partner_contact has data...
      ! (.data[[var_part_pres]] %in% 0)    # ...but presence is NOT 0 (covers 1 and NA)
  )

if(nrow(invalid_contact) > 0) {
  cat(sprintf("⚠️ WARNING: %d rows have %s data while %s is 'yes' or missing.\n", 
              nrow(invalid_contact), var_part_cont, var_part_pres))
  print(head(invalid_contact))
} else {
  cat("✅ No invalid or orphaned partner_contact data found.\n")
}

# 2. Partner branch leakage check
#    The variables in vars_branch_partner are asked ONLY IF
#    partner is present or if there was contact since last beep.
header("Check 2: 'Partner Branch' variables present without valid trigger?")
cat("   (Trigger: partner_presence=1 OR partner_contact contains 2,3, or 4)\n")

#    is_*_gate_open is logical vector (an element per beep) containing if the
#    participant was allowed to answer the branched items
#    NOTE: 'partner_contact' is multiple choice (e.g., "24" = texted and saw each other).
#         We check if specific digits appear in the string using regex (grepl).
is_partner_gate_open <- (esm_data[[var_part_pres]] == 1) | 
  grepl("[234]", as.character(esm_data[[var_part_cont]]))

check_branch_consistency(is_partner_gate_open, vars_branch_partner, 
                         "'Partner Branch'")

# 3. No-partner branch leakage check
#    The variables in vars_branch_no_partner are asked ONLY IF 
#    (Partner Present == 0 = no) AND (Contact since last beep == 1 "No").
#    Error: A conditional item has data, but the gate conditions are NOT met.
header("Check 3: 'No-partner Branch' variables present without valid trigger?")
cat("   (Trigger: partner_presence=0 AND partner_contact=1)\n")

is_general_gate_open <- (esm_data[[var_part_pres]] == 0) & 
  grepl("1", as.character(esm_data[[var_part_cont]]))

check_branch_consistency(is_general_gate_open, vars_branch_no_partner, 
                         "'No-partner Branch'")

## ---- ```` A4. ESM SCHEDULE CHECKS -------------------------------------------
## --------------------------------------------------------------------------- -
header("A4. ESM Protocol Schedule Compliance", level = 2)

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
header("Schedule Adherence Patterns")
cat("Expected: 10 valid weekdays + 4 valid weekend days (0 invalid, 14 total)\n\n")

schedule_patterns <- schedule_compliance %>%
  count(n_valid_weekdays, n_valid_weekends, n_invalid_days, total_days, name = "n_participants") %>%
  arrange(desc(n_participants)) %>%
  relocate(n_participants, .before = 1)
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

## ---- ```` A5. ESM MISSINGNESS ANALYSIS --------------------------------------
## --------------------------------------------------------------------------- -
header("A5. ESM Missingness", level = 2)

# 1. Generaland core (wrt present research) missingness
check_missingness(esm_data)

# 2. Beep completion
header("Beep completion stats")
completion_stats <- esm_data %>%
  summarise(
    Total_Rows = n(),
    Started = sum(.data[[col_start]] == 1, na.rm = TRUE),
    Completed = sum(.data[[col_end]] == 1, na.rm = TRUE),
    Started_But_Incomplete = sum(.data[[col_start]] == 1 & .data[[col_end]] == 0, na.rm = TRUE)
  )
print(completion_stats)
header(sprintf("Percentage of started beeps that were NOT completed:\n %.2f%%", 
            (completion_stats$Started_But_Incomplete / completion_stats$Started) * 100))

# 3. Missingness Map (saved as plot)
header("Missingness Heatmap")
plot_miss <- naniar::vis_miss(esm_data, warn_large_data = FALSE) +
  theme(axis.text.x = element_text(angle = 90)) +
  labs(title = "Missingness Map (Black = Missing)")
save_plot(plot_miss, "ESM_missingness_map.png")

## ---- ```` A6. ESM COMPLIANCE ANALYSIS ---------------------------------------
## --------------------------------------------------------------------------- -
header("A6. ESM Compliance Analysis", level = 2)

# 1. Calculate Compliance per Person (as Percentage 0-100)
person_compliance <- esm_data %>%
  group_by(.data[[col_person]]) %>%
  summarise(
    n_total   = n(),
    comp_rate = mean(.data[[col_compl]], na.rm = TRUE) * 100, 
    .groups   = "drop"
  )

# 2. Summary statistics
header("Summary statistics for Participant Compliance Rates (%)")
summary(person_compliance$comp_rate) %>% print()

# 3. Compliance frequency table
thresholds <- seq(10, 100, by = 5)

counts_pass <- sapply(thresholds, function(x) {
  sum(person_compliance$comp_rate <= x)
})   # Calculate counts for each threshold

cumulative_table <- as.data.frame(t(counts_pass))
colnames(cumulative_table) <- c(paste0(" ≤", thresholds, "%"))
header("Participant Cumulative Distribution of Compliance Rates")
print(cumulative_table) # Create and print 1-row summary table

# 4. Identify low compliers
low_compliers <- person_compliance %>% 
  filter(comp_rate < min_compliance) %>%
  arrange(comp_rate) # Participants below minimim compliance

header(sprintf("⚠️ Participants with < %d%% compliance (Total: %d)",
            min_compliance, nrow(low_compliers)))
if(nrow(low_compliers) > 0) {
  print(head(low_compliers))
}

# 5. Compliance heatmap (saved as plot)
header("Compliance Heatmap")

plot_comp_heatmap <- daily_counts %>%  # Uses object created in Section A3
  ggplot(aes(x = date_val, y = as.factor(.data[[col_person]]), fill = n_beeps)) +
  geom_tile(color = "white") +
  scale_fill_gradient(low = "red", high = "green", na.value = "grey90") +
  labs(title = "Daily Compliance Heatmap",
       x = "Study Date", y = "Participant ID", fill = "Beeps/Day") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 6)) 

save_plot(plot_comp_heatmap, "ESM_compliance_heatmap.png")

# 6. Normalized compliance heatmap (saved as plot)
header("Normalized Compliance Heatmap")

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
header("Fatigue Heatmap")

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

## ---- ```` A7. ESM PARTNER BEEP SYNCHRONIZATION ------------------------------
## --------------------------------------------------------------------------- -
header("A7. ESM Dyadic Beep Synchronization", level = 2)

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

header("Summary of time difference between partners starting the SAME beep (mins)")
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

header("Cumulative count of dyadic beeps started within X minutes")
print(sync_table)

# 3. Calculate Cumulative Percentages (<=1, <=2, ... <=15) and >15
n_total <- nrow(dyadic_sync) # Total valid dyadic pairs

sync_table_pct <- round((sync_table/n_total)*100,1)
colnames(sync_table_pct) <- c(paste0("≤", thresholds, "m"), ">15m")

header(sprintf("Cumulative percentage of dyadic beeps started within X minutes (N=%d)", n_total))
print(sync_table_pct)

## ---- ```` ESM CLEANUP ------------------------------------------------------
## --------------------------------------------------------------------------- -
clean_config("ESM") # Remove ESM-specific configuration variables

## ########################################################################### #
## ---- B. BG DATA CHECKS ------------------------------------------------------
## ########################################################################### #

## ---- ```` BG SETUP & VALIDATION ---------------------------------------------
## --------------------------------------------------------------------------- -
header("B. Background Questionnaires Data Checks", level = 1)

load_config("BG")
validate_config("BG", bg_data)

## ---- ```` B1. BG STRUCTURAL CHECKS ------------------------------------------
## --------------------------------------------------------------------------- -
header("B1. BG Dataset Overview & Structure", level = 2)

# Basic structure and dyad integrity
check_basic_structure(bg_data, "BG")

## ---- ```` B2. BG ITEM RANGE CHECKS ------------------------------------------
## --------------------------------------------------------------------------- -
header("B2. BG Item Range Checks", level = 2)

scale_names <- names(scales)
for(name in scale_names) {
  # Get the items from the config
  items <- scales[[name]]
  # Find the matching limit
  limit_name <- sub("scale_", "limits_", name)
  limits     <- ranges[[limit_name]]
  # Run check
  check_range(bg_data, items, limits[1], limits[2], name)
}

## ---- ```` B3. BG MISSINGNESS ------------------------------------------------
## --------------------------------------------------------------------------- -
header("B3. BG Missingness")

# 1. General and core (wrt the present research) missingness
check_missingness(bg_data)

## ---- ```` B4. BG DESCRIPTIVES (DEMOGRAPHICS) -------------------------------
## --------------------------------------------------------------------------- -
header("B4. BG Descriptive statistics (demographics)", level = 2)

# 1. AGE (numeric)
header("Age (years)")
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
header("Gender")
# Pass "col_gender" (the key). The function finds the real column "gender".
df_temp <- bg_data %>% transmute(val = get_label(., "col_gender"))
print(freq_table(df_temp, "val"))
save_plot(plot_bar_categorical(df_temp, "val", "BG: Gender", "Gender"), 
          "BG_gender_bar.png")

# 3. NATIONALITY
header("Nationality")
df_temp <- bg_data %>% transmute(val = get_label(., "col_nat"))
print(freq_table(df_temp, "val"))
save_plot(plot_bar_categorical(df_temp, "val", "BG: Nationality", "Nationality"),
          "BG_nationality_bar.png", w = 10, h = 6)

# 4. ETHNICITY
header("Ethnicity")
df_temp <- bg_data %>% transmute(val = get_label(., "col_etn"))
print(freq_table(df_temp, "val"))
save_plot(plot_bar_categorical(df_temp, "val", "BG: Ethnicity", "Ethnicity"),
          "BG_ethnicity_bar.png", w = 10, h = 6)

# 5. EDUCATION
header("Education")
df_temp <- bg_data %>% transmute(val = get_label(., "col_edu"))
print(freq_table(df_temp, "val"))
save_plot(plot_bar_categorical(df_temp, "val", "BG: Education", "Education"),
          "BG_education_bar.png", w = 10, h = 6)

# 6. CHILDREN
header("Children (YN)")
df_temp <- bg_data %>% transmute(val = get_label(., "col_child"))
print(freq_table(df_temp, "val"))
save_plot(plot_bar_categorical(df_temp, "val", "BG: Children", "Children"),
          "BG_children_bar.png", w = 8, h = 5)

# 7. LIVING TOGETHER
header("Living together")
df_temp <- bg_data %>% transmute(val = get_label(., "col_liv_tog"))
print(freq_table(df_temp, "val"))
save_plot(plot_bar_categorical(df_temp, "val", "BG: Living together", "Living together"),
          "BG_living_together_bar.png", w = 8, h = 5)

# 8. RELATIONSHIP DURATION (Numeric - months)
header("Relationship duration (months)")
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
header("Medication")
df_temp <- bg_data %>% transmute(val = get_label(., "col_med"))
print(freq_table(df_temp, "val"))
save_plot(plot_bar_categorical(df_temp, "val", "BG: Medication", "Medication Status"),
          "BG_medication_bar.png", w = 8, h = 5)

## ---- ```` B5. DCI DETAILED ANALYSIS (TOTAL & WE-NESS) -----------------------
## --------------------------------------------------------------------------- -
header("B5. BG: DCI Total Score, Reliability, & We-ness")

# 1. DEFINE ITEMS & SUBSCALES

# Load negative indices from Config:DCI_reverse_items
dci_neg_items <- paste0("DCI", DCI_reverse_items)

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
    DCI_Total_Score = rowSums(select(., all_of(scale_DCI)), na.rm = FALSE),  # check if na.rm = FALSE has an effect, are there missing values?
    We_Ness_Score   = rowMeans(select(., all_of(dci_we_items)), na.rm = TRUE)
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
  geom_histogram(binwidth = 0.1, fill = "forestgreen", color = "white") +
  labs(title = "Distribution of 'We-ness' Scores", 
       subtitle = "Average of 22 Positive items (No negative items)",
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
cat("\n=== PARTNER DIFFERENCE ANALYSIS ===\n")

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
  geom_histogram(binwidth = 0.1, fill = "firebrick", color = "white") +
  labs(title = "Distribution of We-ness Differences", 
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
header("C. VMR Data Checks", level = 1)

load_config("VMR")
validate_config("VMR", vmr_data)

## ---- ```` C1. VMR STRUCTURAL CHECKS -----------------------------------------
## --------------------------------------------------------------------------- -
header("C1. VMR Dataset Overview & Structure", level = 2)

# 1. Basic structure and dyad integrity
check_basic_structure(vmr_data, "VMR")

# 2. Topics present (expected: 2 topics per participant, positive/negative)
header("Topic distribution")
vmr_data %>%
  count(topic, name = "n_rows", sort = TRUE) %>%
  print()

header("Topics per participant (should be 2)")
topics_per_person <- vmr_data %>%
  distinct(.data[[col_person]], .data[[col_topic]]) %>%
  count(.data[[col_person]], name = "n_topics")
summary(topics_per_person$n_topics) %>% print()

if (all(topics_per_person$n_topics == 2)) {
  cat("✅ VMR: All participants have 2 topics.\n")
} else {
  cat("⚠️ WARNING: Some participants don't have 2 topics.\n")
  topics_per_person %>% 
    filter(n_topics != 2) %>% 
    arrange(desc(n_topics)) %>% 
    head(20) %>% 
    print()
}

# 3. Segment Count
header(sprintf("Segment Completeness (Expected %d per person x topic)", 
               expected_segments_per_topic)) # 16 expected
counts_pt <- vmr_data %>%
  group_by(.data[[col_person]], .data[[col_topic]]) %>%
  summarise(n_segments = n(), .groups = "drop")
summary(counts_pt$n_segments) %>% print()

incomplete_pt <- counts_pt %>%
  filter(n_segments != expected_segments_per_topic) %>%
  arrange(.data[[col_person]], .data[[col_topic]])

if(nrow(incomplete_pt) == 0) {
  cat("✅ VMR: All (PpID x topic) combinations have exactly 16 segments.\n")
} else {
  cat(sprintf("⚠️ WARNING: %d (PpID x topic) combinations deviate from %d segments.\n",
              nrow(incomplete_pt), expected_segments_per_topic))
  print(incomplete_pt)
}

# 4. Per participant, total rows should typically be 32 (2 topics x 16 segments)
rows_per_person <- vmr_data %>%
  count(.data[[col_person]], name = "n_rows") %>%
  arrange(n_rows)

header(sprintf("Total rows per participant (%d expected)", 
               expected_segments_per_topic * 2))
summary(rows_per_person$n_rows) %>% print()

if(all(rows_per_person$n_rows == 2 * expected_segments_per_topic)) {
  cat(sprintf("✅ VVMR: Participant row totals are %d (consistent with 2 topics).", 
              expected_segments_per_topic * 2))
} else {
  cat("⚠️ WARNING: Some participants have unexpected total row counts (showing first 20):\n")
  print(head(rows_per_person %>% filter(!n_rows %in% c(16, 32)), 20))
}

# 5. Segment should run 1..16 for each (PpID x topic)
header("Check: segment range and coverage (expected 1..16 per PpID x topic)")
tp_range <- vmr_data %>%
  group_by(.data[[col_person]], .data[[col_topic]]) %>%
  summarise(tp_min = min(.data[[col_segment]], na.rm = TRUE),
            tp_max = max(.data[[col_segment]], na.rm = TRUE),
            n_tp  = n_distinct(.data[[col_segment]]),
            .groups = "drop")

tp_bad <- tp_range %>%
  filter(tp_min != 1 | tp_max != 16 | n_tp != 16)

if(nrow(tp_bad) == 0) {
  cat("✅ VMR: tsegmentcoverage is complete (1..16, 16 unique) for all (PpID x topic).\n")
} else {
  cat(sprintf("⚠️ WARNING: %d (PpID x topic) combinations show incomplete/irregulars segments.\n",
              nrow(tp_bad)))
  print(tp_bad)
}

# 6. Participant and dyad number relation checks
header("Participant and couple ID relation checks")
print(summary(vmr_data[[col_person]]))
print(summary(vmr_data[[col_dyad]]))

# If CoupleID is unexpectedly large, it may indicate a coding/offset issue
if(max(vmr_data[[col_dyad]], na.rm = TRUE) > 899) {
  cat("⚠️ WARNING: Max CoupleID is unusually large.\n")
} else {
  cat("✅ VMR: CoupleID range appears plausible.\n")
}

# Check consistency: for PpID>700, CoupleID should equal PpID-700
vmr_id_logic <- vmr_data %>%
  distinct(.data[[col_person]], .data[[col_dyad]]) %>%
  mutate(
    expected = if_else(.data[[col_person]] > 700, 
                       .data[[col_person]] - 700, .data[[col_person]]),
    matches_expected  = (.data[[col_dyad]] == expected)
  )

n_mismatch <- sum(!vmr_id_logic$matches_expected, na.rm = TRUE)
if(n_mismatch == 0) {
  cat("✅ VMR: CoupleID matches the expected transformation from PpID.\n")
} else {
  cat(sprintf("⚠️ WARNING: %d (PpID, CoupleID) pairs do not match the expected 
              relation (first 10 shown).\n",
              n_mismatch))
  print(head(vmr_id_logic %>% filter(!matches_expected), 10))
}

# 7. VMR duplicate (PpID x topic x segment) combination
header("VMR Duplicate Key Checks")

dup_keys <- vmr_data %>%
  group_by(.data[[col_person]], .data[[col_topic]], .data[[col_segment]]) %>%
  tally(name = "n") %>%
  filter(n > 1) %>%
  arrange(desc(n))

if(nrow(dup_keys) == 0) {
  cat("✅ VMR: No duplicate rows found for the key (PpID x topic x segment.\n")
} else {
  cat(sprintf("⚠️ WARNING: %d duplicate key combinations found (showing first 10):\n",
              nrow(dup_keys)))
  print(head(dup_keys, 10))
}

# 8. 2 persons expected in each (CoupleID x topic x segment) combination
header("VMR: 2 rows per CoupleID x topic x segment?")

pair_check <- vmr_data %>%
  group_by(.data[[col_dyad]], .data[[col_topic]], .data[[col_segment]]) %>%
  summarise(n_rows = n(), n_persons = n_distinct(.data[[col_person]]), .groups = "drop") %>%
  filter(n_rows != 2 | n_persons != 2) %>%
  arrange(desc(n_rows), .data[[col_dyad]], .data[[col_topic]], .data[[col_segment]])

if(nrow(pair_check) == 0) {
  cat("✅ VMR: All (CoupleID x topic x segment) combinations contain exactly 2
      rows (2 partners).\n")
} else {
  cat(sprintf("⚠️ WARNING: %d (CoupleID x topic x segment) combinations do not have 
              exactly 2 partner rows (first 10 shown).\n",
              nrow(pair_check)))
  print(head(pair_check, 10))
}

# 9. Row coverage table to spot holes in the segment grid across topics
header("Coverage table: number of rows per (topic x timepoint)")

grid_check <- vmr_data %>%
  count(.data[[col_topic]], .data[[col_segment]], name = "n_rows") %>%
  arrange(.data[[col_topic]], .data[[col_segment]])

print(grid_check, n = Inf)

## ---- ```` C2. VMR RANGE CHECKS ----------------------------------------------
## --------------------------------------------------------------------------- -
header("C2. VMR Range Checks (0–100 sliders; -3..3 agency/communion)", level = 2)

# vars to check
var_names <- names(vars) 
for(name in var_names) {
  # Get the items from the config
  items <- vars[[name]]
  # Find the matching limit
  limit_name <- sub("var_", "limits_", name)
  limits     <- ranges[[limit_name]]
  # Run check
  check_range(vmr_data, items, limits[1], limits[2], name)
}

## ---- ```` C3. VMR MISSINGNESS -----------------------------------------------
## --------------------------------------------------------------------------- -
header("C3. VMR Missingness", level = 2)

# 1. General and core (wrt the present research) missingness
check_missingness(vmr_data)

## ---- ```` C4. VMR DURATION CHECKS -------------------------------------------
## --------------------------------------------------------------------------- -
header("C4. VMR Completion Duration Checks", level = 2)

header("Summary of VMR completion duration (minutes)")
summary(vmr_data[[col_duration]]) %>% print()

# One duration per participant x topic expected (duration repeated across 16 segments)
duration_unique <- vmr_data %>%
  distinct(.data[[col_person]], .data[[col_topic]], .data[[col_duration]])

header("Number of unique durations per (PpID x topic) should be 1")
duration_mult <- duration_unique %>%
  count(.data[[col_person]], .data[[col_topic]], name = "n_durations") %>%
  filter(n_durations != 1)

if(nrow(duration_mult) == 0) {
  cat("✅ VMR: duration_minutes is constant within each (PpID x topic).\n")
} else {
  cat(sprintf("⚠️ WARNING: duration_minutes varies within some (PpID x topic) (showing first 20):\n"))
  print(head(duration_mult, 20))
}

# Sanity bounds (conservative): should be >0, and not extremely large
header("Implausible durations (<=0 or >60 minutes)?")
dur_bad <- duration_unique %>%
  filter(.data[[col_duration]] <= 0 | .data[[col_duration]] > 60)

if(nrow(dur_bad) == 0) {
  cat("✅ VMR: No implausible duration values found.\n")
} else {
  cat(sprintf("⚠️ WARNING: %d (PpID x topic) have implausible durations (showing first 20):\n",
              nrow(dur_bad)))
  print(head(dur_bad, 20))
}

## ---- ```` VMR CLEANUP -------------------------------------------------------
## --------------------------------------------------------------------------- -
clean_config("VMR") # Remove VMR-specific configuration variables

## ########################################################################### #
## ---- D. POST DATA CHECKS ----------------------------------------------------
## ########################################################################### #

## ---- ```` POST SETUP & VALIDATION -------------------------------------------
## --------------------------------------------------------------------------- -
header("D. Post Interaction Questionnaire Data Checks", level = 1)

load_config("POST")
validate_config("POST", post_data)

## ---- ```` D1. POST STRUCTURAL CHECKS ----------------------------------------
## --------------------------------------------------------------------------- -
header("D1. POST Dataset Overview & Structure", level = 2)

# Basic structure and dyad integrity
check_basic_structure(post_data, "POST")

## ---- ```` D2. POST ITEM RANGE CHECKS ----------------------------------------
## --------------------------------------------------------------------------- -
header("D2. POST Item Range Checks", level = 2)

# vars to check
var_names <- names(vars) 
for(name in var_names) {
  # Get the items from the config
  items <- vars[[name]]
  # Find the matching limit
  limit_name <- sub("var_", "limits_", name)
  limits     <- ranges[[limit_name]]
  # Run check
  check_range(post_data, items, limits[1], limits[2], name)
}

## ---- ```` D3. POST MISSINGNESS -----------------------------------------------
## --------------------------------------------------------------------------- -
header("D3. POST Missingness")

# 1. General and core (wrt present research) missingness
check_missingness(post_data)

## ---- ```` POST CLEANUP -------------------------------------------------------
## --------------------------------------------------------------------------- -
clean_config("POST") # Remove POST-specific configuration variables

## ########################################################################### #
## ---- E. CROSS-DATASET CHECKS ------------------------------------------------
## ########################################################################### #

## ---- ```` CROSS-CHECK SETUP --------------------------------------------------
## --------------------------------------------------------------------------- -
# Load configs into local objects (no global environment conflicts)
header("E. Cross-Dataset Data Checks", level = 1)

# cfg_esm  <- load_config("ESM",  to_global = FALSE)
# cfg_bg   <- load_config("BG",   to_global = FALSE)
# cfg_vmr  <- load_config("VMR",  to_global = FALSE)
# cfg_post <- load_config("POST", to_global = FALSE)


## ---- ```` E1. PARTICIPANT ID CONSISTENCY -----------------------------------------
## --------------------------------------------------------------------------- -
header("Checking Participant ID Consistency across Datasets")

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
header("End of Data Check Report", level = 1)
cat("Log saved to: ", log_file, "\n", sep = "")

message(paste("Output log saved to:", log_file))
sink()