############################################################################# #
# 04_functions.R
#
# Purpose:
#   Define user functions to be used across scripts
#
# Usage:
#.  Run source("R/04_functions.R") to source these functions.
#   Sourcing is included in R/00_setup.R together with R/01_paths.R, 
#   R/02_packages.R, and R/03_data_config.R
#
############################################################################## #

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
    cat("\n===", text, "\n")
  }
}

load_config <- function(config, to_global = TRUE) {
  # 1. Select the config list
  cfg <- switch(config,
                "ESM"  = CONFIG_ESM,
                "BG"   = CONFIG_BG,
                "VMR"  = CONFIG_VMR,
                "POST" = CONFIG_POST)
  
  if(is.null(cfg)) stop(paste("Configuration not found for:", config))
  # 2. Unpack sublists to Global Environment except if to_global = FALSE
  if(to_global) {
    sublists_to_unpack <- names(cfg)
    for (sublist in sublists_to_unpack) {
      list2env(cfg[[sublist]], envir = .GlobalEnv)
    }
    cat(sprintf("✅ %s config unpacked to Global Env (Sublists: %s).\n", 
                config, paste(sublists_to_unpack, collapse=", ")))  }
  list2env(list(cols = cfg$cols, vars = cfg$vars, ranges = cfg$ranges,
                scales = cfg$scales), envir = .GlobalEnv)
  # 3. Return the config object invisibly
  invisible(cfg)
}

clean_config <- function(config) {
  # 1. Get load_config to know WHAT to remove, to_global = FALSE to not unpack
  cfg <- load_config(config, to_global = FALSE) 
  # 2. Collect all variable names
  vars_to_remove <- c()
  sublists_to_remove <- names(cfg)
  for (sublist in sublists_to_remove) {
    vars_to_remove <- c(vars_to_remove, names(cfg[[sublist]]))
  }
  # 3. Add containers
  containers <- c("cols", "vars", "ranges", "scales")
  vars_to_remove <- c(vars_to_remove, containers)
  # 4. Limit to what exists in GlobalEnv to avoid warnings
  vars_to_remove <- vars_to_remove[sapply(vars_to_remove, exists, envir = .GlobalEnv)]
  vars_to_remove <- unique(vars_to_remove) # avoid attempting to remove twice
  # 5. Remove them from GlobalEnv
  if(length(vars_to_remove) > 0) {
    rm(list = vars_to_remove, envir = .GlobalEnv)
    cat(sprintf("🧹 %s vars removed from Global Env.\n", config))
  } 
}

# Validation function to check if if columns/vars mapped in the CONFIG exist in the datset
# used during development
validate_config <- function(config, dataset) {
  # 1. Get the config locally (not to global env)
  cfg <- load_config(config, to_global = FALSE)
  # 2. Gather all expected column names (in GLOBAL_SETTINGS config_sublists_with_variables)
  vars_required <- c()
  config_sublists_with_variables = c("cols", "vars", "scales")
  sublists_to_check <- intersect(names(cfg), config_sublists_with_variables)
  for (sublist in sublists_to_check) {
    vars_required <- c(vars_required, unlist(cfg[[sublist]]))
  }
  # 3. Compare against the actual dataframe
  vars_missing <- setdiff(vars_required, names(dataset))
  # 4. Stop if any are missing
  if(length(vars_missing) > 0) {
    cat(sprintf("\n\n!!! ERROR: The '%s' dataset is missing these variables:\n%s\n", 
                config, 
                paste(vars_missing, collapse = ", ")))
  } else {
    cat(sprintf("✅ %s dataset validated: All %d required variables found (checked: %s).\n", 
                config, length(vars_required), paste(sublists_to_check, collapse=", ")))
  }
}

check_basic_structure <- function(data, label = "DATA") {
  # 1. Structure overview
  header(sprintf("%s dimensions and variables", label))
  str(data,
      list.len     = ncol(data),      # show ALL columns
      strict.width = "cut",           # force single line (no wrapping)
      give.attr    = FALSE)           # remove attributes at the bottom
  cat(sprintf("\nUnique Persons: %d\n", n_distinct(data[[person]])))
  cat(sprintf("Unique Dyads:   %d\n", n_distinct(data[[dyad]])))
  cat(sprintf("Total Rows:     %d\n", nrow(data)))
  cat(sprintf("Total Columns:  %d\n", ncol(data)))
  # 2. Dyad integrity check
  header(sprintf("%s Dyad Integrity", label))
  problem_dyads <- data %>%
    group_by(.data[[dyad]]) %>%
    summarise(n_persons = n_distinct(.data[[person]])) %>%
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
    distinct(.data[[dyad]], .data[[person]]) %>%
    group_by(.data[[dyad]]) %>%
    summarise(
      has_lt_700 = any(.data[[person]] < 700, na.rm = TRUE),
      has_gt_700 = any(.data[[person]] > 700, na.rm = TRUE)
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
    n_persons        = n_distinct(data[[person]]),
    n_dyads          = n_distinct(data[[dyad]]),
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
    select(all_of(person), all_of(beep), all_of(var)) %>%
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
    select(all_of(person), all_of(columns_present)) %>%
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

get_label <- function(data, name) {
  # 1. Retrieve the column name and the label map
  var_name <- CONFIG_BG$cols[[name]]
  lbls     <- CONFIG_BG$value_labels[[name]]
  # 2. Extract the data vector for var_name
  vec <- trimws(as.character(data[[var_name]]))
  # 3. Fix: If this is the medication column, treat NA as 0
  if (name == "med") {
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

select_and_rename <- function (data, map) {
  old <- unname(map)
  new <- names(map)
  data <- data %>%     
    select(all_of(old)) %>%    # keep only mapped columns
    setNames(new)                # rename old -> new
  return(data)
}