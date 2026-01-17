###############################################
# 02_structure_checks.R
#
# Purpose:
# Structural integrity checks of the imported
# raw datasets (diagnostic only).
#
# Usage:
# Run source("R/02_structure_checks.R") to see
# the report without code echoing.
#
###############################################

# ---- Setup ----
# (suppress messages for cleaner report)
suppressPackageStartupMessages(source("R/02_packages.R"))

# --- CONFIGURATION: Define Column Names ---
col_person <- "PpID"
col_dyad   <- "CoupleID"
col_beep   <- "beepno"
col_compl  <- "compliance" 
col_start  <- "started"
col_end    <- "complete"

col_ts_sent   <- "timeStampSent"
col_ts_sched  <- "timeStampScheduled"
col_ts_start  <- "timeStampStart"
col_ts_stop   <- "timeStampStop"
# col_ts_orig   <- "originalTimeStampSent" # Optional, if used

col_part_no   <- "partner_no"      # Partner number (1 or 2)
col_neg_gen   <- "negevent_general"
col_pres_oth  <- "presence_others"
col_cont_oth  <- "contact_others"

col_part_pres <- "partner_presence" # 0=No, 1=Yes
col_part_cont <- "partner_contact"  # 1=No contact, 2-4=Types of contact

# List of specific variables for targeted missingness checks
vars_affect <- c('NA_own', 'PA_own', 'NA_partner', 'PA_partner', 
                 'loving', 'perc_respons', 'negevent_partner', 'posevent_partner')
time_vars <- c(col_ts_sched, col_ts_sent, col_ts_start, col_ts_stop)
non_core_variables <- c("GeneralComments", "ESMComments", time_vars, "started", "complete", "compliance")

# lists of variabless for conditional items checks
vars_branch_partner <- c(
  "negevent_partner", "posevent_partner", "reassurance_own", "extrinsicIER", 
  "expression_own", "dominance_own", "affiliation_own", "reassurance_partner", 
  "expression_partner", "dominance_partner", "affiliation_partner"
)

vars_branch_general <- c(
  "presence_others", "contact_others", "negevent_general", "posevent_general", 
  "lonely", "rumination", "posthoughts", "expression_desire", "affection_desire"
)

# ---- VALIDATION: Stop script if variables missing ----
required_vars <- c(col_person, col_dyad, col_beep, col_compl, col_start, col_end, 
                   vars_affect, non_core_variables, vars_branch_partner, vars_branch_general)
missing_vars  <- setdiff(required_vars, names(esm_raw))

if(length(missing_vars) > 0) {
  stop("\n\n!!! ERROR: Check script, the following variables are not in the dataset:\n", 
       paste(missing_vars, collapse = ", "), 
       "\n\nScript aborted.")
} 

# ---- Helper functions ----
print_header <- function(text) {
  cat("\n\n====================================================================\n")
  cat(toupper(text))
  cat("\n====================================================================\n")
}

# --- 1. GENERAL OVERVIEW & VARIABLES ------------------------------------------
print_header("1. Dataset Overview & Variable Types")

cat("Dimensions and variables (Glimpse):\n")
glimpse(esm_raw)

# --- 2. PARTICIPANTS AND DYADS STRUCTURE --------------------------------------
print_header("2. Structural Integrity: Persons & Dyads")

# Counts
n_persons <- n_distinct(esm_raw[[col_person]])
n_dyads   <- n_distinct(esm_raw[[col_dyad]])

cat(paste0("Total unique Persons: ", n_persons, "\n"))
cat(paste0("Total unique Dyads:   ", n_dyads, "\n"))

# Check: Do all dyads strictly contain 2 people?
cat("\nCheck: Persons per Dyad (Should be exactly 2 for all):\n")
persons_per_dyad <- esm_raw %>%
  group_by(.data[[col_dyad]]) %>%
  summarise(n_persons = n_distinct(.data[[col_person]])) 

problem_dyads <- persons_per_dyad %>% filter(n_persons != 2)

if(nrow(problem_dyads) == 0) {
  cat("✅ All dyads contain exactly 2 unique persons.\n")
} else {
  cat("⚠️ WARNING: The following dyads do not have exactly 2 persons:\n")
  print(problem_dyads)
}

# --- 3. BEEP STRUCTURE & FREQUENCY --------------------------------------------
print_header("3. Beep Frequency & Design Consistency")

# Calculate beeps per person
beeps_per_person <- esm_raw %>%
  count(.data[[col_person]], name = "n_beeps")

# Summary of beeps
cat("Summary of Total Beeps per Person:\n")
summary(beeps_per_person$n_beeps) %>% print()

# Check for equality
if(min(beeps_per_person$n_beeps) == max(beeps_per_person$n_beeps)) {
  cat("\n✅ All participants have an IDENTICAL number of rows/beeps.\n")
} else {
  cat("\n⚠️ WARNING: Number of beeps VARIES between participants.\n")
  
  cat("Distribution of Total Beeps (How many people have X beeps?):\n")
  beeps_per_person %>% 
    count(n_beeps, name = "n_participants") %>% 
    print()
  
  cat("\nInvestigating Missing Beeps: Which beep numbers are most frequently missing?\n")
  beep_counts <- esm_raw %>%
    count(.data[[col_beep]], name = "count_present") %>%
    mutate(missing_count = n_persons - count_present) %>%
    arrange(desc(missing_count))
  
  print(head(beep_counts, 15))
}

# Check for duplicate beep numbers within persons
cat("\nCheck: Are beep numbers unique within persons?\n")
duplicates <- esm_raw %>%
  group_by(.data[[col_person]], .data[[col_beep]]) %>%
  count() %>%
  filter(n > 1)

if(nrow(duplicates) == 0) {
  cat("✅ No duplicate beep numbers found within participants.\n")
} else {
  cat("⚠️ WARNING: Duplicate beep numbers found for specific persons (showing first 5):\n")
  print(head(duplicates, 5))
}

# --- 4. START VS COMPLETION ---------------------------------------------------
print_header("4. Beep Completion Status (Started vs Finished)")

# Summary table
completion_stats <- esm_raw %>%
  summarise(
    Total_Rows = n(),
    Started = sum(.data[[col_start]] == 1, na.rm = TRUE),
    Completed = sum(.data[[col_end]] == 1, na.rm = TRUE),
    Started_But_Incomplete = sum(.data[[col_start]] == 1 & .data[[col_end]] == 0, na.rm = TRUE)
  )

print(completion_stats)

pct_incomplete <- (completion_stats$Started_But_Incomplete / completion_stats$Started) * 100
cat(sprintf("\nPercentage of started beeps that were NOT completed: %.2f%%\n", pct_incomplete))


# --- 5. MISSINGNESS ANALYSIS --------------------------------------------------
print_header("5. Missing Data Patterns")

# 1. General missingness % (All data)
cat(sprintf("General dataset missingness: %.2f%%\n", pct_miss(esm_raw)))

# 2. Total core variables data missingness % 
pct_core <- esm_raw %>%
  select(all_of(vars_affect)) %>%
  pct_miss()
cat(sprintf("Total dataset missingness (excluding metadata): %.2f%%\n", pct_core))

# Top 10 general missingness using naniar
cat("\n--- Top 10 general variables missingness ---\n")
print(miss_var_summary(esm_raw) %>% head(10))

# Top 10 core variables missingness using naniar
cat("\n--- Top 10 core variables missingness ---\n")
subset_core <- esm_raw %>% select(all_of(vars_affect))
print(miss_var_summary(subset_core) %>% head(10))

# --- 6. COMPLIANCE ANALYSIS ---------------------------------------------------
print_header("6. Compliance / Response Analysis")

# 1. Calculate Compliance per Person (as Percentage 0-100)
person_compliance <- esm_raw %>%
  group_by(.data[[col_person]]) %>%
  summarise(
    n_total   = n(),
    comp_rate = mean(.data[[col_compl]], na.rm = TRUE) * 100, 
    .groups   = "drop"
  )

# 2. Summary Statistics
cat("Summary statistics for Participant Compliance Rates (%):\n")
summary(person_compliance$comp_rate) %>% print()

# 3. Compliance Frequency Table
thresholds <- seq(10, 100, by = 5)

# Calculate counts for each threshold
counts_pass <- sapply(thresholds, function(x) {
  sum(person_compliance$comp_rate <= x)
})

# Create the 1-row summary table
cumulative_table <- as.data.frame(t(counts_pass))
colnames(cumulative_table) <- c(paste0(" ≤", thresholds, "%"))

cat("\nParticipant Cumulative Distribution of Compliance Rates:\n")
print(cumulative_table)

# 4. Identify Low Compliers
#    Flag participants below 50%
low_cutoff <- 30
low_compliers <- person_compliance %>% 
  filter(comp_rate < low_cutoff) %>%
  arrange(comp_rate)

cat(sprintf("\n⚠️ Participants with < %d%% compliance (Total: %d):\n", low_cutoff, nrow(low_compliers)))

if(nrow(low_compliers) > 0) {
  print(head(low_compliers))
}

# --- 7. VISUALIZE SAMPLING COVERAGE -------------------------------------------
print_header("7. Sampling Coverage & Schedule Compliance")

# 1. Calculate beeps per day and determine day type
daily_counts <- esm_raw %>%
  mutate(
    date_val = as.Date(.data[[col_ts_sent]]),
    # wday: 1=Sunday, 7=Saturday
    day_num  = lubridate::wday(date_val), 
    day_type = if_else(day_num %in% c(1, 7), "Weekend", "Weekday")
  ) %>%
  count(.data[[col_person]], .data[[col_dyad]], date_val, day_type, name = "n_beeps")

# 2. Check compliance per person
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
#    Groups participants by their adherence pattern for the general overview
schedule_patterns <- schedule_compliance %>%
  count(n_valid_weekdays, n_valid_weekends, n_invalid_days, total_days, name = "n_participants") %>%
  arrange(desc(n_participants))

cat("\n--- Schedule Adherence Patterns ---\n")
cat("Target: 10 valid weekdays + 4 valid weekend days (0 invalid, 14 total)\n\n")
print(schedule_patterns)

# 4. Identify Specific Deviations (IDs)
#    Filter for anyone who is NOT perfectly following the protocol
deviants <- schedule_compliance %>%
  filter(n_invalid_days > 0 | total_days != 14) %>%
  select(all_of(col_person), all_of(col_dyad), n_invalid_days, total_days) %>%
  arrange(desc(n_invalid_days))

if(nrow(deviants) > 0) {
  cat("\n\n--- ⚠️  Participants with Schedule Deviations ---\n")
  cat("Listing IDs with Invalid Days != 0 OR Total Days != 14:\n\n")
  
  # Print the table of specific IDs
  print(deviants, n = Inf) 
} else {
  cat("\n\n✅ No deviations found. All participants follow the 14-day schedule perfectly.\n")
}

# 5. Check Total Beeps (sanity check on the sums)
#    Expected total = (10*5) + (4*10) = 90 beeps
total_beeps_check <- esm_raw %>% count(.data[[col_person]], name = "total_beeps")
outliers <- total_beeps_check %>% filter(total_beeps != 90)

if(nrow(outliers) > 0) {
  cat("\n\n--- Total Beep Count Anomalies (Expected 90) ---\n")
  print(head(outliers, 10))
} else {
  cat("\n\n✅ Total Beep Check: All participants have exactly 90 beeps.\n")
}

# --- 8. TIMESTAMP ORDER VERIFICATION ------------------------------------------
print_header("8. Timestamp Logic (Scheduled < Sent < Start < Stop)")

# Check for order violations using the defined column variables
logic_failures <- esm_raw %>%
  filter(.data[[col_end]] == 1) %>% # Only check completed beeps
  filter(
    (.data[[col_ts_sent]] < .data[[col_ts_sched]]) |
      (.data[[col_ts_start]] < .data[[col_ts_sent]]) | 
      (.data[[col_ts_stop]] < .data[[col_ts_start]])
  ) %>%
  select(all_of(col_person), all_of(col_beep), all_of(time_vars))

if(nrow(logic_failures) == 0) {
  cat("✅ SUCCESS: All completed beeps follow logical timestamp order.\n")
} else {
  cat(sprintf("⚠️ WARNING: %d beeps have illogical timestamps:\n", nrow(logic_failures)))
  print(logic_failures)
}

# --- 9. CONDITIONAL ITEM CHECKS --------------------------------------
print_header("9. Conditional Item Checks")

# Logic: Certain questions are only presented based on prior item responses.

# NOTE: We use %in% TRUE to handle NAs safely. 
# !(... %in% TRUE) means "The condition is either FALSE or NA" (i.e., not explicitly met).

# --- Check 1: Orphaned 'partner_contact' ---
# Logic: 'partner_contact' is only asked if 'partner_presence' was answered (specifically 0 = no).
# Error: 'partner_presence' is MISSING, but 'partner_contact' HAS DATA.
cat(paste0("\nCheck 1: Is '", col_part_cont, "' present while '", col_part_pres, "' is missing?\n"))

orphan_contact <- esm_raw %>%
  filter(is.na(.data[[col_part_pres]]) & !is.na(.data[[col_part_cont]]))

if(nrow(orphan_contact) > 0) {
  cat(sprintf("⚠️ WARNING: %d rows have %s data but are missing %s.\n", 
              nrow(orphan_contact), col_part_cont, col_part_pres))
  print(head(orphan_contact))
} else {
  cat("✅ No orphaned partner_contact data found.\n")
}

# --- Check 2: Partner Branch Leakage ---
# Logic: The variables in vars_branch_partner are asked ONLY IF (Partner Present == 1 = yes) OR (Contact since last beep IN 2,3,4).
# Error: A variable has data, but the gate conditions are NOT met (or are missing).
# NOTE: 'partner_contact' is multiple choice (e.g., "24" = texted and saw each other).
#         We check if specific digits appear in the string using regex (grepl).
cat("\nCheck 2: Partner Branch variables present without valid trigger?\n")
cat("   (Trigger: partner_presence=1 OR partner_contact=2,3,4)\n")

check_partner_branch <- esm_raw %>%
  mutate(
  # 1. Convert partner contact to character to safely search for digits "2", "3", "4"
    contact_str = as.character(.data[[col_part_cont]]),
  # 2. Define the 'Gate' (TRUE if the participant was allowed to see the branched questions)
    gate_partner_open = (.data[[col_part_pres]] == 1) | grepl("[234]", contact_str)
  ) %>%
  # 3. Filter for rows where Gate is CLOSED (or NA), but Data EXISTS
  filter(! (gate_partner_open %in% TRUE)) %>% 
  # 4. Check if any of the target variables are NOT NA
  filter(if_any(all_of(vars_branch_partner), ~ !is.na(.)))

if(nrow(check_partner_branch) > 0) {
  cat(sprintf("⚠️ WARNING: %d rows contain Partner Branch data despite closed/missing gate.\n", nrow(check_partner_branch)))
  # 5. Show which specific variables are leaking
  cat("   Violating variables found in these rows:\n")
  check_partner_branch %>%
    select(all_of(vars_branch_partner)) %>%
    summarise(across(everything(), ~sum(!is.na(.)))) %>%
    pivot_longer(everything(), names_to = "Variable", values_to = "N_Illegal_Values") %>%
    filter(N_Illegal_Values > 0) %>%
    print()
} else {
  cat("✅ All Partner Branch data corresponds to valid gate conditions.\n")
}

# --- Check 3: General/Alone Branch Leakage ---
# Logic: The variables in vars_branched_general are asked ONLY IF (Partner Present == 0 = no) AND (Contact since last beep == 1 "No").
# Error: A variable has data, but the Gate conditions are NOT met.
cat("\nCheck 3: General/Alone Branch variables present without valid trigger?\n")
cat("   (Trigger: partner_presence=0 AND partner_contact=1)\n")

check_general_branch <- esm_raw %>%
  mutate(
  # 1. Convert partner contact to character to safely search for digit "1"
    contact_str = as.character(.data[[col_part_cont]]),
  # 2. Gate is OPEN if: partner presence is 0 = no AND partner contact is 1 = no
    gate_general_open = (.data[[col_part_pres]] == 0) & grepl("1", contact_str)
  ) %>%
  # 3. Filter for rows where Gate is CLOSED (or NA), but Data EXISTS
  filter(! (gate_general_open %in% TRUE)) %>% 
  # 4. Check if any of the target variables are NOT NA
  filter(if_any(all_of(vars_branch_general), ~ !is.na(.)))

if(nrow(check_general_branch) > 0) {
  cat(sprintf("⚠️ WARNING: %d rows contain General/Alone Branch data despite closed/missing gate.\n", nrow(check_general_branch)))
  # 5. Show which specific variables are leaking
  cat("   Violating variables found in these rows:\n")  
  check_general_branch %>%
    select(all_of(vars_branch_general)) %>%
    summarise(across(everything(), ~sum(!is.na(.)))) %>%
    pivot_longer(everything(), names_to = "Variable", values_to = "N_Illegal_Values") %>%
    filter(N_Illegal_Values > 0) %>%
    print()
} else {
  cat("✅ All General Branch data corresponds to valid gate conditions.\n")
}

# --- Check 4: Logical Consistency of 'partner_contact' ---
# Logic: Option 1 ("No contact") should be mutually exclusive from 2, 3, 4 ("Yes contact").
# Error: 'partner_contact' contains "1" AND any of "2", "3", or "4" (e.g., "13", "41").
cat(paste0("\nCheck 4: Logical Consistency of '", col_part_cont, "' (Mutually Exclusive)\n"))

inconsistent_contact <- esm_raw %>%
  select(all_of(col_person), all_of(col_beep), all_of(col_part_cont)) %>%
  mutate(
    contact_str = as.character(.data[[col_part_cont]]),
    has_no_contact  = grepl("1", contact_str),
    has_yes_contact = grepl("[234]", contact_str)
  ) %>%
  filter(has_no_contact & has_yes_contact)

if(nrow(inconsistent_contact) > 0) {
  cat(sprintf("⚠️ WARNING: %d rows contain contradictory contact info (1 AND 2/3/4).\n", nrow(inconsistent_contact)))
  print(inconsistent_contact)
} else {
  cat("✅ All 'partner_contact' responses are logically consistent.\n")
}

# --- 10. DYADIC SYNCHRONIZATION -----------------------------------------------
print_header("10. Dyadic Synchronization (Response Timing)")

# 1. Create Dyadic Dataset (Self vs Partner) for timestamps
p1 <- esm_raw %>% 
  filter(.data[[col_part_no]] == 1) %>% 
  select(all_of(col_dyad), all_of(col_beep), start_p1 = .data[[col_ts_start]])

p2 <- esm_raw %>% 
  filter(.data[[col_part_no]] == 2) %>% 
  select(all_of(col_dyad), all_of(col_beep), start_p2 = .data[[col_ts_start]])

dyadic_sync <- inner_join(p1, p2, by = c(col_dyad, col_beep)) %>%
  mutate(
    diff_start_mins = abs(as.numeric(difftime(start_p1, start_p2, units = "mins")))
  ) %>%
  filter(!is.na(diff_start_mins))

cat("Summary of time difference between partners starting the SAME beep (mins):\n")
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

cat("Cumulative count of dyadic beeps started within X minutes:\n")
print(sync_table)

# 3. Calculate Cumulative Percentages (<=1, <=2, ... <=15) and >15
n_total <- nrow(dyadic_sync) # Total valid dyadic pairs

sync_table_pct <- round((sync_table/n_total)*100,1)
colnames(sync_table_pct) <- c(paste0("≤", thresholds, "m"), ">15m")

cat(sprintf("Cumulative percentage of dyadic beeps started within X minutes (N=%d):\n", n_total))
print(sync_table_pct)

# --- 11. VISUAL DIAGNOSTICS (SAVED TO FILE) -----------------------------------
print_header("11. Generating Diagnostic Plots")

# 1. Setup Output Directory
plot_dir <- here::here("outputs", "plots", "ESM data diagnostics")

cat(sprintf("Plots will be saved to: %s\n", plot_dir))

# --- Plot A: Missingness Map (requires 'naniar') ---
cat("\n... Generating Missingness Heatmap (this may take a moment) ...\n")

plot_miss <- naniar::vis_miss(esm_raw, warn_large_data = FALSE) +
  theme(axis.text.x = element_text(angle = 90)) +
  labs(title = "Missingness Map (Black = Missing)")

ggsave(file.path(plot_dir, "01_missingness_map.png"), plot_miss, width = 12, height = 8)
cat("✅ Saved: 01_missingness_map.png\n")

# --- Plot B: Response Time Distribution ---
cat("... Generating Response Timestamp Distribution ...\n")

plot_time <- esm_raw %>%
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

ggsave(file.path(plot_dir, "02_response_time_dist.png"), plot_time, width = 10, height = 6)
cat("✅ Saved: 02_response_time_dist.png\n")

# --- Plot C: Compliance Heatmap (Attrition Grid) ---
cat("... Generating Compliance Heatmap ...\n")

plot_attrition <- daily_counts %>%  # Uses object created in Section 7
  ggplot(aes(x = date_val, y = as.factor(.data[[col_person]]), fill = n_beeps)) +
  geom_tile(color = "white") +
  scale_fill_gradient(low = "red", high = "green", na.value = "grey90") +
  labs(title = "Daily Compliance Heatmap (Attrition Check)",
       subtitle = "Green = Good, Red = Low, Grey = Missing/No Data",
       x = "Study Date", y = "Participant ID", fill = "Beeps/Day") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 6)) 

ggsave(file.path(plot_dir, "03_compliance_grid.png"), plot_attrition, width = 10, height = 12)
cat("✅ Saved: 03_compliance_grid.png\n")

cat("\nDone. Check the output folder for images.\n")

# --- Plot D: Participant Compliance over Study Duration (Attrition) ---
# Goal: See if rows turn red/missing as they move right (from Day 1 to Day 14)
cat("... Generating Attrition Plot ...\n")

# --- PREPARATION: Calculate Relative 'Study Days' and 'Daily Beep Numbers' ---
# We need to normalize time so everyone starts at "Day 1"
esm_relative <- esm_raw %>%
  arrange(.data[[col_person]], .data[[col_ts_sent]]) %>%
  group_by(.data[[col_person]]) %>%
  mutate(
    # 1. Study Day: Day 1 is the participant's first day
    start_date = min(as.Date(.data[[col_ts_sent]]), na.rm = TRUE),
    current_date = as.Date(.data[[col_ts_sent]]),
    study_day = as.numeric(difftime(current_date, start_date, units = "days")) + 1,
    
    # 2. Daily Beep Number: 1 to 10 (or 5) within that specific day
    #    (Resets to 1 every new day)
    beep_daily_num = ave(as.numeric(.data[[col_ts_sent]]), current_date, FUN = seq_along)
  ) %>%
  ungroup()

plot_attrition_rel <- esm_relative %>%
  # Summarize compliance per Study Day
  group_by(.data[[col_person]], study_day) %>%
  summarise(
    n_beeps = n(),
    n_complete = sum(.data[[col_end]] == 1, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  # Filter to reasonably expected days (e.g., first 20 days) to keep plot readable
  filter(study_day <= 20) %>% 
  ggplot(aes(x = factor(study_day), y = factor(.data[[col_person]]), fill = n_complete)) +
  geom_tile(color = "white") +
  scale_fill_gradient(low = "red", high = "green", na.value = "grey95") +
  labs(title = "Attrition Check: Compliance by Study Day",
       subtitle = "Normalized: Everyone starts at Day 1. Red/Missing on right side = Dropouts.",
       x = "Study Day (1 - 14+)", 
       y = "Participant ID", 
       fill = "Completed") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 5)) # Small text for many IDs

ggsave(file.path(plot_dir, "04_attrition_relative.png"), plot_attrition_rel, width = 10, height = 12)
cat("✅ Saved: 04_attrition_relative.png\n")


# --- Plot E: Sample-Level Fatigue with MARGINAL AVERAGES ---
cat("... Generating Fatigue Heatmap with Averages ...\n")

# 1. Prepare the Main Data (Day 1-14)
main_grid <- esm_relative %>%
  filter(study_day <= 14) %>%
  group_by(study_day, beep_daily_num) %>%
  summarise(
    pct_complete = mean(.data[[col_end]], na.rm = TRUE) * 100,
    .groups = "drop"
  ) %>%
  mutate(
    day_label = as.character(study_day),
    beep_label = as.character(beep_daily_num)
  )

# 2. Calculate Row Averages (Avg compliance per Day)
row_avgs <- main_grid %>%
  group_by(day_label) %>%
  summarise(pct_complete = mean(pct_complete), .groups = "drop") %>%
  mutate(beep_label = "Day Avg") 

# 3. Calculate Column Averages (Avg compliance per Beep slot)
col_avgs <- main_grid %>%
  group_by(beep_label) %>%
  summarise(pct_complete = mean(pct_complete), .groups = "drop") %>%
  mutate(day_label = "Beep Avg") 

# 4. Bind everything together
plot_data <- bind_rows(main_grid, row_avgs, col_avgs)

# 5. Define Factor Levels
level_x <- c(as.character(1:10), "Day Avg")
level_y <- c(as.character(1:14), "Beep Avg")

# 6. Plot
plot_fatigue_avg <- plot_data %>%
  mutate(
    beep_label = factor(beep_label, levels = level_x),
    day_label = factor(day_label, levels = level_y)
  ) %>%
  ggplot(aes(x = beep_label, y = day_label, fill = pct_complete)) +
  geom_tile(color = "white") +
  geom_text(aes(label = round(pct_complete, 0),
                color = "black"), # ifelse(pct_complete < 50 | pct_complete > 90, "white", "black")),
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
  labs(title = "Fatigue Map with Marginal Averages",
     subtitle = "Numbers show daily/beep average compliance (%)",
     x = "Beep Sequence ( + Daily Avg)", 
     y = "Study Day ( + Beep Avg)", 
     fill = "% Compliance") +
  theme_minimal()

ggsave(file.path(plot_dir, "05_fatigue_map_avg.png"), plot_fatigue_avg, width = 11, height = 11)
cat("✅ Saved: 05_fatigue_map_avg.png\n")

print_header("End of Report")
