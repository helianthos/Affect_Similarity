############################################################################# #
# 04_functions.R
#
# Purpose:
#   Define user functions to be used across scripts
#
# Usage:
#   Run source("R/04_functions.R") to source these functions.
#   Sourcing is included in R/00_setup.R together with R/01_paths.R, 
#   R/02_packages.R, and R/03_data_config.R
#
############################################################################## #

read_csv_quiet <- function(path, ...) {
  message("Reading: ", basename(path))
  readr::read_csv(
    path,
    show_col_types = FALSE,
    progress = FALSE,
    ...
  )
}

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
    # fix: exclude "value_labels" in CONFIG_BG from unpacking
    sublists_to_unpack <- setdiff(names(cfg), "value_labels")
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
    cat(sprintf("\n🧹 %s vars removed from Global Env.\n", config))
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
  # 1. Create full path
  full_path <- file.path(dir_plots, filename)
  # 2. Save
  ggsave(full_path, plot_obj, width = w, height = h, bg = "white")
  cat(sprintf("✅ Saved: %s\n   Location: %s\n", filename, dirname(full_path)))
}

save_base_plot <- function(plot_code, filename, w=10, h=8) {
  full_path <- file.path(dir_plots, filename)
  # Open PNG device
  png(filename = full_path, width = w, height = h, units = "in", res = 300)
  # Execute the plotting code
  # use 'force()' to ensure the code block runs inside the device
  force(plot_code)
  # Close device
  dev.off()
  cat(sprintf("✅ Saved: %s\n   Location: %s\n", filename, dirname(full_path)))
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

get_label <- function(data, var_name) {
  lbls <- CONFIG_BG$value_labels[[var_name]]
  vec <- as.character(data[[var_name]])
  #    levels = the values in data (e.g., "1", "2")
  #    labels = the text (e.g., "Belgian", "Dutch")
  factor(vec, levels = names(lbls), labels = lbls)
}

freq_table <- function(vector, sort_desc = TRUE) {
  tibble(value = vector) %>%
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

plot_bar_categorical <- function(vector, title, xlab) {
  # 1. Convert the vector to a dataframe for ggplot
  tibble(val = vector) %>%
    mutate(val = val %>%
             fct_na_value_to_level("(Missing)") %>%  # From forcats
             fct_infreq() %>%                        # From forcats
             fct_rev()) %>%
    # 2. Plot
    ggplot(aes(x = val)) +
    geom_bar() +
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

plot_trajectory <- function(data, variable, person_ids) {
    # 1. Filter data for the specific people
  plot_data <- data %>%
    filter(person %in% person_ids)
    # 2. Create the plot
  ggplot(plot_data, aes(x = beep, y = .data[[variable]], color = as.factor(person))) +
    geom_line(na.rm = TRUE) +
    geom_point(na.rm = TRUE) +
    theme_minimal() +
    labs(
      title = sprintf("Trajectory of %s in %s", variable, deparse(substitute(data))),
      y = variable,
      x = "Beep Number",
      color = "Person ID"
    )
}

create_rmc_plot_title <- function(rmc, label = "") {
  r_val <- round(rmc$r, 2)
  p_val <- ifelse(rmc$p < 0.001, "< .001", sprintf("= %.3f", rmc_res$p))
  df_val <- rmc$df
  plot_title <<- sprintf("%s Rmcorr: r = %s, p %s (df = %d)", label, r_val, p_val, df_val)
}

add_layer <- function(base_plot, data, x_var, y_var, z_var, title, x_lab, y_lab, z_lab) {
  base_plot %>%
    add_markers(
      data = data,
      x = x_var,
      y = y_var,
      z = z_var,
      marker = list(size = 3, color = "black", opacity = 0.5),
      name = "Observed Data"
    ) %>%
    layout(
      title = list(text = title, y = 0.95),
      scene = list(
        xaxis = list(title = x_lab),
        yaxis = list(title = y_lab),
        zaxis = list(title = z_lab)
      )
    )
}

plot_corr_heatmap <- function(cor_matrix, title) {
  cor_matrix_long <- as.data.frame(cor_matrix) |>
    rownames_to_column("Var1") |>
    pivot_longer(cols = -Var1, names_to = "Var2", values_to = "value")
  
  ggplot(cor_matrix_long, aes(x = Var1, y = Var2, fill = value)) +
    geom_tile() +
    scale_fill_gradient2(low = "blue", high = "red", mid = "white",
                         midpoint = 0, limits = c(-1, 1),
                         name = "Pearson\nCorrelation") +
    coord_fixed() +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1)) +
    geom_text(aes(label = round(value, 2)), size = 3) +
    labs(title = title, x = "", y = "")
}

boundary_summary <- function(pred, upper = 100, lower = 0, name = "pred") {
  over  <- pred > upper
  under <- pred < lower
  data.frame(
    which = name,
    n = length(pred),
    n_over = sum(over, na.rm = TRUE),
    pct_over = 100 * mean(over, na.rm = TRUE),
    max_over = if (any(over, na.rm = TRUE)) max(pred[over], na.rm = TRUE) else NA_real_,
    n_under = sum(under, na.rm = TRUE),
    pct_under = 100 * mean(under, na.rm = TRUE),
    min_under = if (any(under, na.rm = TRUE)) min(pred[under], na.rm = TRUE) else NA_real_
  )
}

lme_diagnostics <- function(model, max_lag = 10) {
  
  diag_data <- getData(model) %>%
    as_tibble() %>%
    mutate(
      .fitted     = fitted(model),
      .resid_norm = resid(model, type = "normalized")
    )
  
  # Plot 1: Residuals vs fitted
  p1 <- ggplot(diag_data, aes(x = .fitted, y = .resid_norm)) +
    geom_point(alpha = 0.5) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
    geom_smooth(method = "loess", se = FALSE, color = "blue") +
    labs(title = "Normalized Residuals vs. Fitted Values",
         subtitle = "Check for linearity (loess) and homoscedasticity",
         x = "Fitted Values",
         y = "Normalized Residuals") +
    theme_minimal()
  
  # Plot 2: QQ-plot
  p2 <- ggplot(diag_data, aes(sample = .resid_norm)) +
    stat_qq(alpha = 0.5) +
    stat_qq_line(linewidth = 1) +
    labs(title = "Normal QQ-plot (normalized residuals)",
         x = "Theoretical Quantiles",
         y = "Sample Quantiles") +
    theme_minimal()
  
  # Plot 3: ACF
  acf_df <- as.data.frame(ACF(model, resType = "normalized", maxLag = max_lag))
  ci <- qnorm(1 - 0.05 / 2) / sqrt(nrow(diag_data))
  
  p3 <- ggplot(acf_df, aes(x = lag, y = ACF)) +
    geom_hline(aes(yintercept = 0)) +
    geom_segment(aes(xend = lag, yend = 0)) +
    geom_hline(yintercept = c(-ci, ci), linetype = "dashed", color = "blue") +
    labs(title = "ACF of Normalized Residuals") +
    theme_minimal()
  
  print(wrap_plots(p1, p2, ncol = 1))  # patchwork stacks, ommitted plot3 for now since it is not very informative
  
  invisible(diag_data)
}

model_output <- function(model) {
  cat(paste(capture.output({ 
    print(summary(model))
    cat("\n---------------\n\n")
    print(intervals(model, which = "fixed"))  # 95% CIs for fixed effects
    cat("\n---------------\n\n")
    print(VarCorr(model))
  }), collapse = "\n"))
}

mc_ci <- function(sim_vector, a_est, b_est, label) {
  point  <- a_est * b_est
  ci_low <- quantile(sim_vector, 0.025)
  ci_hi  <- quantile(sim_vector, 0.975)
  p_val  <- 2 * min(mean(sim_vector > 0), mean(sim_vector < 0))  # two-tailed MC p
  invisible(list(point = point, ci_low = ci_low, ci_hi = ci_hi, p = p_val, sim = sim_vector))
}

# Combine into single table with a grouping column
make_rows <- function(df, trend_col, predictor_label, moderator = "responsiveness") {
  if (moderator == "responsiveness") {
    level_col <- "Responsiveness level"
    value_col <- "Responsiveness value"
    value_var <- "cperc_resp"
  } else if (moderator == "event_valence") {
    level_col <- "Event valence level"
    value_col <- "Event valence (cC)"
    value_var <- "cC"
  }
  data.frame(
    `Predictor`            = predictor_label,
    ` `                    = c("Low (−1 SD)", "Average", "High (+1 SD)"),
    `  `                   = sprintf("%.2f", df[[value_var]]),
    `Simple slope`         = sprintf("%.4f", df[[trend_col]]),
    `SE`                   = sprintf("%.4f", df$SE),
    `95% CI`               = sprintf("[%.4f, %.4f]", df$lower.CL, df$upper.CL),
    `t`                    = sprintf("%.3f", df$t.ratio),
    `p`                    = ifelse(df$p.value < .001, "< .001",
                                   sprintf("%.3f", df$p.value)),
    check.names = FALSE
  ) %>%
    rename(!!level_col := ` `, !!value_col := `  `)
}

# mediation plots SC2 - Format label with CI and significance
fmt <- function(est, ci_low, ci_up, p) {
  stars <- ifelse(p < .001, "***", ifelse(p < .01, "**", ifelse(p < .05, "*", " (ns)")))
  sprintf("%.3f%s [%.3f, %.3f]", est, stars, ci_low, ci_up)
}

# mediation plots SC2 - Color edges/labels based on significance
sig_col <- function(p) ifelse(p < .05, "black", "grey75")
