############################################################################# #
# 02_structure_checks.R
#
# Purpose:
# Data checks on the imported datasets
#
# Usage:
# Run source("R/02_structure_checks.R") to see
# the report without code echoing.
# Assumes data is located in data/derived/esm_raw.rds
#
############################################################################## #

## ---- SETUP ------------------------------------------------------------------
## --------------------------------------------------------------------------- -

suppressPackageStartupMessages(source("R/02_packages.R"))

# ---- LOAD DATA ---------------------------------------------------------------
## --------------------------------------------------------------------------- -

if(!exists("esm_data")) {esm_data <- readRDS("data/derived/esm_raw.rds")}

# # ---- CONFIGURATION ---------------------------------------------------------
# # -------------------------------------------------------------------------- -

# 1. Centralized configuration list
CONFIG <- list(
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
                      "timeStampScheduled", "timeStampSent", "timeStampStart", "timeStampStop", 
                      "started", "complete", "compliance"),
    
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
    expected_beeps = 90, #    Expected = (10*5) + (4*10) = 90 beeps
    plots_dir      = here("outputs", "plots"),
    log_file       = here("outputs", "logs", "02_data_checks_log_txt")
  )
)

# 2. Unpack variables and vectors to global environment
list2env(CONFIG$cols, envir = .GlobalEnv)
list2env(CONFIG$vars, envir = .GlobalEnv)
list2env(CONFIG$settings, envir = .GlobalEnv)

## ---- VALIDATION -------------------------------------------------------------
## --------------------------------------------------------------------------- -

# 1. Ensure variables exist
vars_required <- c(unlist(CONFIG$cols), unlist(CONFIG$vars))
vars_missing  <- setdiff(vars_required, names(esm_data))

if(length(vars_missing) > 0) {
  stop("\n\n!!! ERROR: Check script, the following variables are not in the dataset:\n", 
       paste(vars_missing, collapse = ", "))
}

# 2. Ensure output directory exists 
if(!dir.exists(plots_dir)) {
  stop("\n\n!!! ERROR: Output directory does not exist.\n")
}

# ---- START LOGGING -----------------------------------------------------------
## --------------------------------------------------------------------------- -
sink(file=log_file, append = FALSE, split = TRUE)
cat(paste0("Log Generated: ", Sys.time(), "\n\n"))

## ---- 0. HELPER FUNCTIONS ----------------------------------------------------
## --------------------------------------------------------------------------- -

print_header <- function(text) {
  cat("\n")
  cat(paste0(rep("=", 60), collapse = ""), "\n")
  cat(paste("  ", toupper(text)), "\n")
  cat(paste0(rep("=", 60), collapse = ""), "\n")
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
  full_path <- file.path(plots_dir, filename)
  ggsave(full_path, plot_obj, width = w, height = h, bg = "white")
  cat(sprintf("✅ Saved: %s\n   Location: %s\n", filename, full_path))
}

## ---- 1. STRUCTURAL CHECKS ---------------------------------------------------
## --------------------------------------------------------------------------- -
print_header("1. Dataset Overview & Structure")

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

if(n_distinct(beeps_per_person$n_beeps) == 1) {
  cat("\n✅ All participants have" , expected_beeps, "arows/beeps.\n")
} else {
  cat("\n⚠️ WARNING: Number of beeps VARIES between participants.\n")
  
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
}

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

save_plot(plot_time, "01_ESM_response_time_dist.png")

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

## ---- 2. CONDITIONAL ITEM CHECKS ---------------------------------------------
## --------------------------------------------------------------------------- -
print_header("2. Conditional Item Checks")

# 1. Orphaned 'partner_contact' check
#    'partner_contact' can only have date if 'partner_presence' == 0 (=no)
cat(paste0("\nCheck 1: Does '", col_part_cont, "' have data while '",
           col_part_pres, "' is 'yes' or missing?\n"))

invalid_contact <- esm_data %>%
  filter(
    !is.na(.data[[col_part_cont]]) &       # Contact has data...
      ! (.data[[col_part_pres]] %in% 0)      # ...but Presence is NOT 0 (covers 1 and NA)
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

## ---- 3. SCHEDULE CHECKS -----------------------------------------------------
## --------------------------------------------------------------------------- -
print_header("3. Protocol Schedule Compliance")

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

cat("\n--- Schedule Adherence Patterns ---\n")
cat("Target: 10 valid weekdays + 4 valid weekend days (0 invalid, 14 total)\n\n")
print(schedule_patterns)

# 4. Identify deviations
#    Filter for anyone who is NOT perfectly following the protocol
deviants <- schedule_compliance %>%
  filter(n_invalid_days > 0 | total_days != 14) %>%
  select(all_of(col_person), all_of(col_dyad), n_invalid_days, total_days) %>%
  arrange(desc(n_invalid_days))

if(nrow(deviants) > 0) {
  cat("\n\n--- ⚠️  Participants with Schedule Deviations ---\n")
  cat("Listing PpIDs with Invalid Days != 0 OR Total Days != 14:\n\n")
  print(deviants, n = Inf) 
} else {
  cat("\n\n✅ No deviations found. All participants follow the 14-day schedule perfectly.\n")
}

## ---- 4. MISSINGNESS ANALYSIS ------------------------------------------------
## --------------------------------------------------------------------------- -
print_header("4. Missingness")

# 1. General missingness
cat(sprintf("\nGeneral dataset missingness: %.2f%%\n", pct_miss(esm_data)))
cat("\n--- Top 10 general variables missingness ---\n")
print(miss_var_summary(esm_data) %>% head(10))

# 2. Total core variables data missingness
pct_core <- esm_data %>%
  select(all_of(vars_affect)) %>%
  pct_miss()
cat(sprintf("\nTotal core dataset missingness: %.2f%%\n", pct_core))
cat("\n--- Top 10 core variables missingness ---\n")
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

save_plot(plot_miss, "02_ESM_missingness_map.png")


## ---- 5. COMPLIANCE ANALYSIS -------------------------------------------------
## --------------------------------------------------------------------------- -
print_header("5. Compliance Analysis")

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

save_plot(plot_comp_heatmap, "03_ESM_compliance_heatmap.png")

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

save_plot(plot_norm_comp_heatmap, "04_ESM_compliance_heatmap_normalized.png")

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
  geom_text(aes(label = round(pct_complete, 0),
                color = "black"),
            size = 3) +
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

save_plot(plot_fatigue_avg, "05_ESM_fatigue_map.png")

## ---- 6. PARTNER BEEP SYNCHRONIZATION ----------------------------------------
## --------------------------------------------------------------------------- -

print_header("6. Dyadic Beep Synchronization")

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

# ---- END ---------------------------------------------------------------------
## --------------------------------------------------------------------------- -
print_header("End of Data Check Report")

# ---- STOP LOGGING ------------------------------------------------------------
## --------------------------------------------------------------------------- -
sink()
message(paste("Output log saved to:", log_file))