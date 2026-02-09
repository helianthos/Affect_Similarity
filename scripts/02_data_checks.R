############################################################################# #
# 02_data_checks.R
#
# Purpose:
#   Data checks on and some descriptives of the 4 imported datasets
#
# Usage:
#   Run source("R/02_structure_checks.R")
#
# Input:
#   Assumes data is located in data/imported (in variable dir_data_imp),
#   after running 01_data_import.R at least once
#       * data/imported/esm_raw.rds
#       * data/imported/esm_bg.rds
#       * data/imported/esm_vmr.rds
#       * data/imported/esm_post.rds
#
# Output:
#   Plots and log file. Assumes that the output directories exist (e.g., via git clone)
#   If not, these will as fallback be created during 00_setup.R
#       * outputs/plots (in dir_plots)
#       * outputs/logs (in dir_logs)
#
############################################################################## #

## ########################################################################### #
## ---- GLOBAL SETUP -----------------------------------------------------------
## ########################################################################### #

# 1. Load packages, paths, data configurations, and functions
source(here::here("R", "00_setup.R"))

# 2. Load datasets
esm_data <- readRDS(file.path(dir_data_imp, "esm_raw.rds"))
bg_data <- readRDS(file.path(dir_data_imp, "bg_raw.rds"))
vmr_data <- readRDS(file.path(dir_data_imp, "vmr_raw.rds"))
post_data <- readRDS(file.path(dir_data_imp, "post_raw.rds"))

# 3. Parameters
# ---- Global
log_file  = file.path(dir_logs, "02_data_checks_log.txt")
plot_counter <- 1 # initialize start of plot numbering
# ---- ESM
min_compliance = 30  #   Minimum compliance (see preregistration)
expected_beeps = 90 #    Expected = (10*5) + (4*10) = 90 beeps
# ---- VMR
expected_segments_per_topic = 16
expected_topics = c("positive", "negative")
# ---- plot initialisation
plot_counter <- 1
prefix <- "Data_Checks"

# 4. Start logging
sink(file=log_file, append = FALSE, split = TRUE) # for cat and print
cat("============================================================\n")
cat("02_data_checks.R log\n")
cat("Log generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n", sep = "")
cat("Project root:  ", here::here(), "\n", sep = "")
cat("============================================================\n")

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
beeps_per_person <- esm_data %>% count(.data[[person]], name = "n_beeps")
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
  count(.data[[beep]], name = "count_present") %>%
  mutate(missing_count = n_distinct(esm_data[[person]]) - count_present) %>%
  filter(missing_count != 0) %>%
  arrange(desc(missing_count)) %>%
  print()

# 4. Check total beeps
outliers <- beeps_per_person %>% filter(n_beeps != expected_beeps)

header("Beep Counts")
if(nrow(outliers) > 0) {
  cat("Beep Count Anomalies (Expected", expected_beeps,")\n")
  print(head(outliers, 10))
} else {
  cat("✅ Total Beep Check: All participants have exactly" , expected_beeps, "beeps.\n")
}

# 5. Check for duplicate beep numbers within persons
header("Are beep numbers unique within persons?")
duplicates <- esm_data %>%
  group_by(.data[[person]], .data[[beep]]) %>%
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
  filter(.data[[start]] == 1) %>%
  mutate(
    hour_decimal = lubridate::hour(.data[[ts_start]]) + 
      (lubridate::minute(.data[[ts_start]]) / 60)
  ) %>%
  ggplot(aes(x = hour_decimal)) +
  geom_histogram(binwidth = 0.5, fill = "steelblue", color = "white") +
  scale_x_continuous(breaks = seq(0, 24, 1)) +
  coord_cartesian(xlim = c(0, 24)) +
  labs(title = "Distribution of Responses by Time of Day (Half Hour Buckets)",
       x = "Hour of Day (0-24)", y = "Count of Beeps") +
  theme_minimal()

plot_name <- sprintf("%s_%d_ESM_response_time_dist.png", prefix, plot_counter)
save_plot(plot_time, plot_name)
plot_counter <- plot_counter + 1

# 7. Timestamp Order Check 
header("Timestamp Logic (Scheduled < Sent < Start < Stop)")

logic_failures <- esm_data %>%
  filter(.data[[end]] == 1) %>% # Only check completed beeps
  filter(
    (.data[[ts_sent]] < .data[[ts_sched]]) |
      (.data[[ts_start]] < .data[[ts_sent]]) | 
      (.data[[ts_stop]] < .data[[ts_start]])
  ) %>%
  select(all_of(person), all_of(beep), all_of(vars_time))

if(nrow(logic_failures) == 0) {
  cat("✅ SUCCESS: All completed beeps follow logical timestamp order.\n")
} else {
  cat(sprintf("⚠️ WARNING: %d beeps have illogical timestamps:\n", nrow(logic_failures)))
  print(logic_failures)
}

# 8. Multiple choice consistency check

#    partner_contact 1 (No) should be mutually exclusive from 2-4 (Yes contact).
check_mc_consistency(part_cont, "1", "[234]")

#    presence_others 7 (Nobody) should be mutually exclusive from 1-6
check_mc_consistency(pres_oth, "7", "[123456]")

#    contact_others 7 (Nobody) should be mutually exclusive from 1-6
check_mc_consistency(cont_oth, "7", "[123456]")

## ---- ```` A2. ESM ITEM RANGE CHECKS -----------------------------------------
## --------------------------------------------------------------------------- -
header("A2. ESM Item Range Checks", level = 2)

# vars to check
names <- names(vars) 
for(name in names) {
  # Get the items from the config
  items <- vars[[name]]
  # Find the matching limit
  limit_name <- sub("", "limits_", name)
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
               part_cont, part_pres ))

invalid_contact <- esm_data %>%
  filter(
    !is.na(.data[[part_cont]]) &       # partner_contact has data...
      ! (.data[[part_pres]] %in% 0)    # ...but presence is NOT 0 (covers 1 and NA)
  )

if(nrow(invalid_contact) > 0) {
  cat(sprintf("⚠️ WARNING: %d rows have %s data while %s is 'yes' or missing.\n", 
              nrow(invalid_contact), part_cont, part_pres))
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
is_partner_gate_open <- (esm_data[[part_pres]] == 1) | 
  grepl("[234]", as.character(esm_data[[part_cont]]))

check_branch_consistency(is_partner_gate_open, vars_branch_partner, 
                         "'Partner Branch'")

# 3. No-partner branch leakage check
#    The variables in vars_branch_no_partner are asked ONLY IF 
#    (Partner Present == 0 = no) AND (Contact since last beep == 1 "No").
#    Error: A conditional item has data, but the gate conditions are NOT met.
header("Check 3: 'No-partner Branch' variables present without valid trigger?")
cat("   (Trigger: partner_presence=0 AND partner_contact=1)\n")

is_general_gate_open <- (esm_data[[part_pres]] == 0) & 
  grepl("1", as.character(esm_data[[part_cont]]))

check_branch_consistency(is_general_gate_open, vars_branch_no_partner, 
                         "'No-partner Branch'")

## ---- ```` A4. ESM SCHEDULE CHECKS -------------------------------------------
## --------------------------------------------------------------------------- -
header("A4. ESM Protocol Schedule Compliance", level = 2)

# 1. Calculate beeps per day and determine day type
daily_counts <- esm_data %>% 
  mutate(
    date_val = as.Date(.data[[ts_sent]]),
    # wday: 1=Sunday, 7=Saturday
    day_num  = lubridate::wday(date_val), 
    day_type = if_else(day_num %in% c(1, 7), "Weekend", "Weekday")
  ) %>%
  count(.data[[person]], .data[[dyad]], date_val, day_type, name = "n_beeps")

# 2. Check patterns per person
#    Expected: 10 Weekdays (with 5 beeps) and 4 Weekend days (with 10 beeps)
schedule_compliance <- daily_counts %>%
  group_by(.data[[person]], .data[[dyad]]) %>%
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
cat("Expected: 10 valid weekdays + 4 valid weekend days (0 invalid, 14 total)\n")

schedule_patterns <- schedule_compliance %>%
  count(n_valid_weekdays, n_valid_weekends, n_invalid_days, total_days, name = "n_participants") %>%
  arrange(desc(n_participants)) %>%
  relocate(n_participants, .before = 1)
print(schedule_patterns)

# 4. Identify deviations
#    Filter for anyone who is NOT perfectly following the protocol
deviants <- schedule_compliance %>%
  filter(n_invalid_days > 0 | total_days != 14) %>%
  select(all_of(person), all_of(dyad), n_invalid_days, total_days) %>%
  arrange(desc(n_invalid_days))

if(nrow(deviants) > 0) {
  cat("\n\n⚠️  Participants with Schedule Deviations\n")
  cat("Listing PpIDs with Invalid Days != 0 OR Total Days != 14:\n  ")
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
    Started = sum(.data[[start]] == 1, na.rm = TRUE),
    Completed = sum(.data[[end]] == 1, na.rm = TRUE),
    Started_But_Incomplete = sum(.data[[start]] == 1 & .data[[end]] == 0, na.rm = TRUE)
  )
print(completion_stats)
header(sprintf("Percentage of started beeps that were NOT completed:\n %.2f%%", 
            (completion_stats$Started_But_Incomplete / completion_stats$Started) * 100))

# 3. Missingness Map (saved as plot)
header("Missingness Heatmap")
plot_miss <- naniar::vis_miss(esm_data, warn_large_data = FALSE) +
  theme(axis.text.x = element_text(angle = 90)) +
  labs(title = "Missingness Map (Black = Missing)")

plot_name <- sprintf("%s_%d_ESM_missingness_map.png", prefix, plot_counter)
save_plot(plot_miss, plot_name)
plot_counter <- plot_counter + 1

## ---- ```` A6. ESM COMPLIANCE ANALYSIS ---------------------------------------
## --------------------------------------------------------------------------- -
header("A6. ESM Compliance Analysis", level = 2)

# 1. Calculate Compliance per Person (as Percentage 0-100)
person_compliance <- esm_data %>%
  group_by(.data[[person]]) %>%
  summarise(
    n_total   = n(),
    comp_rate = mean(.data[[compl]], na.rm = TRUE) * 100, 
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
  ggplot(aes(x = date_val, y = as.factor(.data[[person]]), fill = n_beeps)) +
  geom_tile(color = "white") +
  scale_fill_gradient(low = "red", high = "green", na.value = "grey90") +
  labs(title = "Daily Compliance Heatmap",
       x = "Study Date", y = "Participant ID", fill = "Beeps/Day") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 6)) 

plot_name <- sprintf("%s_%d_ESM_compliance_heatmap.png", prefix, plot_counter)
save_plot(plot_comp_heatmap, plot_name)
plot_counter <- plot_counter + 1

# 6. Normalized compliance heatmap (saved as plot)
header("Normalized Compliance Heatmap")

#   Normalize time so everyone starts at "Day 1"
esm_relative <- esm_data %>%
  arrange(.data[[person]], .data[[ts_sent]]) %>%
  group_by(.data[[person]]) %>%
  mutate(
    # 1. Study Day: Day 1 is the participant's first day
    start_date = min(as.Date(.data[[ts_sent]]), na.rm = TRUE),
    current_date = as.Date(.data[[ts_sent]]),
    study_day = as.numeric(difftime(current_date, start_date, units = "days")) + 1,
        # 2. Daily Beep Number: 1 to 10 (or 5) within that specific day
    beep_daily_num = ave(as.numeric(.data[[ts_sent]]), current_date, FUN = seq_along)
  ) %>%
  ungroup()

plot_norm_comp_heatmap <- esm_relative %>%
  # Summarize compliance per Study Day
  group_by(.data[[person]], study_day) %>%
  summarise(
    n_beeps = n(),
    n_complete = sum(.data[[end]] == 1, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  ggplot(aes(x = factor(study_day), y = factor(.data[[person]]), fill = n_complete)) +
  geom_tile(color = "white") +
  scale_fill_gradient(low = "red", high = "green", na.value = "grey95") +
  labs(title = "Normalized Compliance Heatmap",
       x = "Study Day (1 - 14+)", 
       y = "Participant ID", 
       fill = "Completed") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 5))

plot_name <- sprintf("%s_%d_ESM_compliance_heatmap_normalized.png", prefix, plot_counter)
save_plot(plot_norm_comp_heatmap, plot_name)
plot_counter <- plot_counter + 1

# 7. Fatigue heatmap
header("Fatigue Heatmap")

main_grid <- esm_relative %>%
  filter(study_day <= 14) %>% # exclude 1 couple's day 15 data
  group_by(study_day, beep_daily_num) %>%
  summarise(
    pct_complete = mean(.data[[end]], na.rm = TRUE) * 100,
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
avgs <- main_grid %>%
  group_by(beep_label) %>%
  summarise(pct_complete = mean(pct_complete), .groups = "drop") %>%
  mutate(day_label = "Beep Avg")

#  Calculate Grand Mean (corner cell)
grand_avg <- tibble(
  day_label = "Beep Avg",   # Matches the label used in avgs
  beep_label = "Day Avg",   # Matches the label used in row_avgs
  pct_complete = mean(main_grid$pct_complete, na.rm = TRUE)
)

# Plot
plot_data <- bind_rows(main_grid, row_avgs, avgs, grand_avg)

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

plot_name <- sprintf("%s_%d_ESM_fatigue_map.png", prefix, plot_counter)
save_plot(plot_fatigue_avg, plot_name)
plot_counter <- plot_counter + 1

## ---- ```` A7. ESM PARTNER BEEP SYNCHRONIZATION ------------------------------
## --------------------------------------------------------------------------- -
header("A7. ESM Dyadic Beep Synchronization", level = 2)

# 1. Create Dyadic Dataset (Self vs Partner) for timestamps
p1 <- esm_data %>% 
  filter(.data[[part_no]] == 1) %>% 
  select(all_of(dyad), all_of(beep), start_p1 = all_of(ts_start))

p2 <- esm_data %>% 
  filter(.data[[part_no]] == 2) %>% 
  select(all_of(dyad), all_of(beep), start_p2 = all_of(ts_start))

dyadic_sync <- inner_join(p1, p2, by = c(dyad, beep)) %>%
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
  distinct(.data[[person]], .data[[topic]]) %>%
  count(.data[[person]], name = "n_topics")
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
  group_by(.data[[person]], .data[[topic]]) %>%
  summarise(n_segments = n(), .groups = "drop")
summary(counts_pt$n_segments) %>% print()

incomplete_pt <- counts_pt %>%
  filter(n_segments != expected_segments_per_topic) %>%
  arrange(.data[[person]], .data[[topic]])

if(nrow(incomplete_pt) == 0) {
  cat("✅ VMR: All (PpID x topic) combinations have exactly 16 segments.\n")
} else {
  cat(sprintf("⚠️ WARNING: %d (PpID x topic) combinations deviate from %d segments.\n",
              nrow(incomplete_pt), expected_segments_per_topic))
  print(incomplete_pt)
}

# 4. Per participant, total rows should typically be 32 (2 topics x 16 segments)
rows_per_person <- vmr_data %>%
  count(.data[[person]], name = "n_rows") %>%
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
  group_by(.data[[person]], .data[[topic]]) %>%
  summarise(tp_min = min(.data[[segment]], na.rm = TRUE),
            tp_max = max(.data[[segment]], na.rm = TRUE),
            n_tp  = n_distinct(.data[[segment]]),
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
print(summary(vmr_data[[person]]))
print(summary(vmr_data[[dyad]]))

# If CoupleID is unexpectedly large, it may indicate a coding/offset issue
if(max(vmr_data[[dyad]], na.rm = TRUE) > 899) {
  cat("⚠️ WARNING: Max CoupleID is unusually large.\n")
} else {
  cat("✅ VMR: CoupleID range appears plausible.\n")
}

# Check consistency: for PpID>700, CoupleID should equal PpID-700
vmr_id_logic <- vmr_data %>%
  distinct(.data[[person]], .data[[dyad]]) %>%
  mutate(
    expected = if_else(.data[[person]] > 700, 
                       .data[[person]] - 700, .data[[person]]),
    matches_expected  = (.data[[dyad]] == expected)
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
  group_by(.data[[person]], .data[[topic]], .data[[segment]]) %>%
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
  group_by(.data[[dyad]], .data[[topic]], .data[[segment]]) %>%
  summarise(n_rows = n(), n_persons = n_distinct(.data[[person]]), .groups = "drop") %>%
  filter(n_rows != 2 | n_persons != 2) %>%
  arrange(desc(n_rows), .data[[dyad]], .data[[topic]], .data[[segment]])

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
header("Coverage table: number of rows per (topic x segment)")

grid_check <- vmr_data %>%
  count(.data[[topic]], .data[[segment]], name = "n_rows") %>%
  arrange(.data[[topic]], .data[[segment]])

print(grid_check, n = Inf)

## ---- ```` C2. VMR RANGE CHECKS ----------------------------------------------
## --------------------------------------------------------------------------- -
header("C2. VMR Range Checks (0–100 sliders; -3..3 agency/communion)", level = 2)

# vars to check
names <- names(vars) 
for(name in names) {
  # Get the items from the config
  items <- vars[[name]]
  # Find the matching limit
  limit_name <- sub("", "limits_", name)
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
summary(vmr_data[[duration]]) %>% print()

# One duration per participant x topic expected (duration repeated across 16 segments)
duration_unique <- vmr_data %>%
  distinct(.data[[person]], .data[[topic]], .data[[duration]])

header("Number of unique durations per (PpID x topic) should be 1")
duration_mult <- duration_unique %>%
  count(.data[[person]], .data[[topic]], name = "n_durations") %>%
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
  filter(.data[[duration]] <= 0 | .data[[duration]] > 60)

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
names <- names(vars) 
for(name in names) {
  # Get the items from the config
  items <- vars[[name]]
  # Find the matching limit
  limit_name <- sub("", "limits_", name)
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
ids_esm  <- unique(esm_data[[CONFIG_ESM$cols$person]])
ids_bg   <- unique(bg_data[[CONFIG_BG$cols$person]])
ids_vmr  <- unique(vmr_data[[CONFIG_VMR$cols$person]])
ids_post <- unique(post_data[[CONFIG_POST$cols$person]])

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