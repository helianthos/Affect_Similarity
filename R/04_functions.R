############################################################################# #
# 04_functions.R
#
# Purpose:
#   Define reusable helper functions used across scripts in this project.
#
# Usage:
#   Run source("R/04_functions.R") to source these functions.
#   Sourcing is included in R/00_setup.R together with R/01_paths.R, 
#   R/02_packages.R, and R/03_data_config.R
#
############################################################################## #


# ============================================================================ #
# GENERAL UTILITIES
# Used across multiple pipeline scripts (01-04) and analysis files (06, 07)
# ============================================================================ #

# Read a CSV file with suppressed column type messages and progress bar
read_csv_quiet <- function(path, ...) {
  message("Reading: ", basename(path))
  readr::read_csv(
    path,
    show_col_types = FALSE,
    progress = FALSE,
    ...
  )
}

# Print a formatted section header to the console (levels 1-3)
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


# ============================================================================ #
# DATA CONFIGURATION MANAGEMENT
# Used in pipeline scripts (01-04) for loading/cleaning CONFIG objects
# ============================================================================ #

# Unpack a named configuration list (CONFIG_ESM, CONFIG_BG, etc.) to the
# global environment, making its sublists available as individual objects
load_config <- function(config, to_global = TRUE) {
  cfg <- switch(config,
                "ESM"  = CONFIG_ESM,
                "BG"   = CONFIG_BG,
                "VMR"  = CONFIG_VMR,
                "POST" = CONFIG_POST)
  
  if(is.null(cfg)) stop(paste("Configuration not found for:", config))
  if(to_global) {
    sublists_to_unpack <- names(cfg)
    sublists_to_unpack <- setdiff(names(cfg), "value_labels")
    for (sublist in sublists_to_unpack) {
      list2env(cfg[[sublist]], envir = .GlobalEnv)
    }
    cat(sprintf("✅ %s config unpacked to Global Env (Sublists: %s).\n", 
                config, paste(sublists_to_unpack, collapse=", ")))  }
  list2env(list(cols = cfg$cols, vars = cfg$vars, ranges = cfg$ranges,
                scales = cfg$scales), envir = .GlobalEnv)
  invisible(cfg)
}

# Remove all variables unpacked by load_config() from the global environment
clean_config <- function(config) {
  cfg <- load_config(config, to_global = FALSE) 
  vars_to_remove <- c()
  sublists_to_remove <- names(cfg)
  for (sublist in sublists_to_remove) {
    vars_to_remove <- c(vars_to_remove, names(cfg[[sublist]]))
  }
  containers <- c("cols", "vars", "ranges", "scales")
  vars_to_remove <- c(vars_to_remove, containers)
  vars_to_remove <- vars_to_remove[sapply(vars_to_remove, exists, envir = .GlobalEnv)]
  vars_to_remove <- unique(vars_to_remove)
  if(length(vars_to_remove) > 0) {
    rm(list = vars_to_remove, envir = .GlobalEnv)
    cat(sprintf("\n🧹 %s vars removed from Global Env.\n", config))
  } 
}

# Check whether all column names specified in a CONFIG exist in the dataset
validate_config <- function(config, dataset) {
  cfg <- load_config(config, to_global = FALSE)
  vars_required <- c()
  config_sublists_with_variables = c("cols", "vars", "scales")
  sublists_to_check <- intersect(names(cfg), config_sublists_with_variables)
  for (sublist in sublists_to_check) {
    vars_required <- c(vars_required, unlist(cfg[[sublist]]))
  }
  vars_missing <- setdiff(vars_required, names(dataset))
  if(length(vars_missing) > 0) {
    cat(sprintf("\n\n!!! ERROR: The '%s' dataset is missing these variables:\n%s\n", 
                config, 
                paste(vars_missing, collapse = ", ")))
  } else {
    cat(sprintf("✅ %s dataset validated: All %d required variables found (checked: %s).\n", 
                config, length(vars_required), paste(sublists_to_check, collapse=", ")))
  }
}


# ============================================================================ #
# DATA QUALITY CHECKS
# Used in pipeline scripts (01-04) during data import and cleaning
# ============================================================================ #

# Print basic structure info and check dyad integrity (2 persons per dyad,
# participant ID numbering logic with <700 and >700 within each dyad)
check_basic_structure <- function(data, label = "DATA") {
  header(sprintf("%s dimensions and variables", label))
  str(data,
      list.len     = ncol(data),
      strict.width = "cut",
      give.attr    = FALSE)
  cat(sprintf("\nUnique Persons: %d\n", n_distinct(data[[person]])))
  cat(sprintf("Unique Dyads:   %d\n", n_distinct(data[[dyad]])))
  cat(sprintf("Total Rows:     %d\n", nrow(data)))
  cat(sprintf("Total Columns:  %d\n", ncol(data)))
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
  invisible(list(
    n_persons        = n_distinct(data[[person]]),
    n_dyads          = n_distinct(data[[dyad]]),
    n_rows           = nrow(data),
    n_cols           = ncol(data),
    problem_dyads    = problem_dyads
  ))
}

# Compare participant IDs across two datasets and report mismatches
check_data_participant_overlap <- function(data1_ids, data2_ids, data1_label, data2_label) {
  missing <- setdiff(data1_ids, data2_ids)
  extra   <- setdiff(data2_ids, data1_ids)
  cat(sprintf("\nComparing %s (N=%d) vs %s (N=%d):\n", 
              data1_label, length(data1_ids), data2_label, length(data2_ids)))
  if(length(missing) == 0 && length(extra) == 0) {
    cat(sprintf("✅ All %s participants match %s participants.\n",data1_label, data2_label))
  } else {
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

# Check that mutually exclusive multiple choice answers are not both selected
check_mc_consistency <- function(var, no_resp, not_no_resp) {
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

# Check that conditional (branched) questionnaire items have no data when
# the gating condition is not met
check_branch_consistency <- function(is_gate_open, vars_conditional, label) {
  leaking_rows <- esm_data %>%
    filter(! (is_gate_open %in% TRUE)) %>%
    filter(if_any(all_of(vars_conditional), ~ !is.na(.)))
  if(nrow(leaking_rows) > 0) {
    cat(sprintf("⚠️ WARNING: %d rows contain '%s' data despite closed gate.\n",
                nrow(leaking_rows), label))
    cat("   Violating variables found in these rows:\n")  
    leaking_rows %>%
      select(all_of(vars_conditional)) %>%
      summarise(across(everything(), ~sum(!is.na(.)))) %>%
      pivot_longer(everything(), names_to = "Variable", values_to = "Irregular_Entries") %>%
      filter(Irregular_Entries > 0) %>%
      print()
  } else {
    cat(sprintf("✅ Conditional %s logic is consistent.\n", label))
  }
}

# Check whether values in specified columns fall within expected range
check_range <- function(data, columns, min_v, max_v, name) {
  columns_present <- intersect(columns, names(data))
  columns_missing <- setdiff(columns, names(data))
  if(length(columns_present) == 0) {
    cat(sprintf("ℹ️  Note: No variables found for %s.\n", name))
    return(NULL)
  }
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
      cat(sprintf("✅ %s: All items found and values within codebook range [%d, %d]\n", 
                  name, min_v, max_v))
    } else {
      cat(sprintf("⚠️ %s: Existing items valid [%d, %d], but %d items missing (%s)\n", 
                  name, min_v, max_v, length(columns_missing), 
                  paste(columns_missing, collapse=", ")))
    }
  }
}

# Report overall missingness, key identifier missingness, and core variable
# missingness for a dataset
check_missingness <- function(data) {
  header(sprintf("General dataset missingness: %.2f%%", pct_miss(data)))
  cat("Top 10 variables missingness\n")
  print(miss_var_summary(data) %>% head(10))
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
  pct_core <- data %>%
    select(all_of(vars_core)) %>%
    pct_miss()
  header(sprintf("Total core dataset missingness: %.2f%%", pct_core))
  cat("Top 10 core variables missingness\n")
  subset_core <- data %>% select(all_of(vars_core))
  print(miss_var_summary(subset_core) %>% head(10))
}


# ============================================================================ #
# PLOTTING AND VISUALIZATION HELPERS
# Used in pipeline scripts (02) for data exploration and diagnostics
# ============================================================================ #

# Save a ggplot object to the project plots directory
save_plot <- function(plot_obj, filename, w = 10, h = 8) {
  full_path <- file.path(dir_plots, filename)
  ggsave(full_path, plot_obj, width = w, height = h, bg = "white")
  cat(sprintf("✅ Saved: %s\n   Location: %s\n", filename, dirname(full_path)))
}

# Save a base R plot (plot code passed as expression) to the project plots directory
save_base_plot <- function(plot_code, filename, w = 10, h = 8) {
  full_path <- file.path(dir_plots, filename)
  png(filename = full_path, width = w, height = h, units = "in", res = 300)
  force(plot_code)
  dev.off()
  cat(sprintf("✅ Saved: %s\n   Location: %s\n", filename, dirname(full_path)))
}

# Map numeric codes to text labels using value_labels from CONFIG_BG
get_label <- function(data, var_name) {
  lbls <- CONFIG_BG$value_labels[[var_name]]
  vec <- as.character(data[[var_name]])
  factor(vec, levels = names(lbls), labels = lbls)
}

# Create a frequency table (count and percentage) from a vector
freq_table <- function(vector, sort_desc = TRUE) {
  tibble(value = vector) %>%
    count(value, name = "n", sort = sort_desc) %>%
    mutate(pct = round(100 * n / sum(n), 1))
}

# Plot a histogram for a numeric variable
plot_hist_numeric <- function(data, var, title, xlab, binwidth = NULL) {
  df <- data %>%
    transmute(value = suppressWarnings(as.numeric(.data[[var]]))) %>%
    filter(!is.na(value))
  ggplot(df, aes(x = value)) +
    geom_histogram(binwidth = binwidth) +
    labs(title = title, x = xlab, y = "Count") +
    theme_minimal()
}

# Plot a horizontal bar chart for a categorical variable
plot_bar_categorical <- function(vector, title, xlab) {
  tibble(val = vector) %>%
    mutate(val = val %>%
             fct_na_value_to_level("(Missing)") %>%
             fct_infreq() %>%
             fct_rev()) %>%
    ggplot(aes(x = val)) +
    geom_bar() +
    coord_flip() +
    labs(title = title, x = xlab, y = "Count") +
    theme_minimal()
}

# Plot individual trajectories for selected persons across beeps
plot_trajectory <- function(data, variable, person_ids) {
  plot_data <- data %>%
    filter(person %in% person_ids)
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

# Plot a correlation heatmap with numeric labels from raw data
plot_correlation_heatmap <- function(data, vars, title = "Correlation Heatmap") {
  cor_matrix <- cor(data %>% select(all_of(vars)), use = "pairwise.complete.obs")
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

# Plot a correlation heatmap from a pre-computed correlation matrix
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

# Create a title string for a repeated measures correlation (rmcorr) plot
create_rmc_plot_title <- function(rmc, label = "") {
  r_val <- round(rmc$r, 2)
  p_val <- ifelse(rmc$p < 0.001, "< .001", sprintf("= %.3f", rmc$p))
  df_val <- rmc$df
  plot_title <<- sprintf("%s Rmcorr: r = %s, p %s (df = %d)", label, r_val, p_val, df_val)
}

# Add a 3D scatter layer to a plotly object (used in exploratory 3D plots)
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

# Select and rename columns in a data frame using a named mapping vector
select_and_rename <- function(data, map) {
  old <- unname(map)
  new <- names(map)
  data <- data %>%
    select(all_of(old)) %>%
    setNames(new)
  return(data)
}


# ============================================================================ #
# DESCRIPTIVES HELPERS (SIMILARITY SURFACE & VIOLINS)
# Used in 05_descriptives.qmd for the theoretical similarity surface and for
# violin plots comparing similarity distributions across affect / perception
# ============================================================================ #

# Theoretical similarity index: elevation minus mismatch. Used with outer()
# to build the reference similarity surface over a (X, Y) affect grid.
similarity <- function(X, Y) {
  elevation <- (X + Y) / 2
  mismatch  <- abs(X - Y)
  elevation - mismatch
}

# Draw a 4-panel vioplot of the similarity columns (actual/perceived × PA/NA)
# for a given dataset (esm_data or vmr_data). The default `cols` match the
# column naming convention used throughout the pipeline.
draw_sim_violin_plot <- function(data,
                                 cols = c("PA_similarity_act", "NA_similarity_act",
                                          "PA_similarity_perc", "NA_similarity_perc")) {
  vioplot(data[, cols],
          main      = "Range and Distribution of Affect Similarity",
          col       = c("#A6CEE3", "#FB9A99", "#A6CEE3", "#FB9A99"),
          names     = c("PA\nActual", "NA\nActual", "PA\nPerceived", "NA\nPerceived"),
          areaEqual = FALSE,
          rectCol   = "gray30",
          lineCol   = "gray30",
          border    = "gray30")
  title(ylab = "Similarity (S = M - D)", line = 2)
  abline(h = 0, col = "black", lty = 2, lwd = 1.5)
}


# ============================================================================ #
# SCALE DIAGNOSTICS
# Used in pipeline scripts for reliability analysis
# ============================================================================ #

# Compute Cronbach's alpha for a set of items, returning a one-row data frame
compute_alpha <- function(data, items, scale_name) {
  alpha_result <- psych::alpha(data %>% select(all_of(items)), check.keys = TRUE)
  data.frame(
    Scale = scale_name,
    Raw_Alpha = round(alpha_result$total$raw_alpha, 3),
    Std_Alpha = round(alpha_result$total$std.alpha, 3),
    N_items   = length(items)
  )
}


# ============================================================================ #
# MODEL OUTPUT AND DIAGNOSTICS
# Used in 06_study_component_1.qmd and 07_study_component_2.qmd
# ============================================================================ #

# Summarize how many predicted values fall outside the 0-100 outcome scale
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

# Produce diagnostic plots for an nlme::lme model: residuals vs. fitted,
# QQ-plot of normalized residuals. ACF plot is computed but not displayed.
lme_diagnostics <- function(model, max_lag = 10) {
  
  diag_data <- getData(model) %>%
    as_tibble() %>%
    mutate(
      .fitted     = fitted(model),
      .resid_norm = resid(model, type = "normalized")
    )
  
  p1 <- ggplot(diag_data, aes(x = .fitted, y = .resid_norm)) +
    geom_point(alpha = 0.5) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
    geom_smooth(method = "loess", se = FALSE, color = "blue") +
    labs(title = "Normalized Residuals vs. Fitted Values",
         subtitle = "Check for linearity (loess) and homoscedasticity",
         x = "Fitted Values",
         y = "Normalized Residuals") +
    theme_minimal()
  
  p2 <- ggplot(diag_data, aes(sample = .resid_norm)) +
    stat_qq(alpha = 0.5) +
    stat_qq_line(linewidth = 1) +
    labs(title = "Normal QQ-plot (normalized residuals)",
         x = "Theoretical Quantiles",
         y = "Sample Quantiles") +
    theme_minimal()
  
  acf_df <- as.data.frame(ACF(model, resType = "normalized", maxLag = max_lag))
  ci <- qnorm(1 - 0.05 / 2) / sqrt(nrow(diag_data))
  
  p3 <- ggplot(acf_df, aes(x = lag, y = ACF)) +
    geom_hline(aes(yintercept = 0)) +
    geom_segment(aes(xend = lag, yend = 0)) +
    geom_hline(yintercept = c(-ci, ci), linetype = "dashed", color = "blue") +
    labs(title = "ACF of Normalized Residuals") +
    theme_minimal()
  
  print(wrap_plots(p1, p2, ncol = 1))
  
  invisible(diag_data)
}

# Print a comprehensive summary of an nlme::lme model: fixed effects with
# p-values, 95% confidence intervals, and variance components
model_output <- function(model) {
  cat(paste(capture.output({ 
    print(summary(model))
    cat("\n---------------\n\n")
    print(intervals(model, which = "fixed"))
    cat("\n---------------\n\n")
    print(VarCorr(model))
  }), collapse = "\n"))
}


# ============================================================================ #
# MONTE CARLO MEDIATION
# Used in 06_study_component_1.qmd and 07_study_component_2.qmd (Step 2)
# ============================================================================ #

# Compute the indirect effect (a*b) and its 95% Monte Carlo confidence
# interval from a vector of simulated a*b products. Returns point estimate,
# CI bounds, and a two-tailed p-value.
mc_ci <- function(sim_vector, a_est, b_est, label) {
  point  <- a_est * b_est
  ci_low <- quantile(sim_vector, 0.025)
  ci_hi  <- quantile(sim_vector, 0.975)
  p_val  <- 2 * min(mean(sim_vector > 0), mean(sim_vector < 0))
  invisible(list(point = point, ci_low = ci_low, ci_hi = ci_hi, p = p_val, sim = sim_vector))
}


# ============================================================================ #
# SIMPLE SLOPE TABLE HELPER
# Used in 06_study_component_1.qmd (Step 3a/3b) for formatting probing tables
# ============================================================================ #

# Format emtrends output into a publication-ready data frame with a grouping
# column for the predictor label. Supports responsiveness and event valence
# as moderators.
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

# Format emtrends output into a simple-slopes row set for a continuous
# exploratory moderator (cC_expl). Compared with make_rows(), this version
# does not rename moderator columns and uses fixed "Event valence level" /
# "cC_expl" headers. Used in 06_study_component_1.qmd (exploratory h3.3).
make_rows_expl <- function(df, trend_col, predictor_label, mod_col) {
  data.frame(
    `Predictor`           = predictor_label,
    `Event valence level` = c("Low (−1 SD)", "Average", "High (+1 SD)"),
    `cC_expl`             = sprintf("%.2f", df[[mod_col]]),
    `Simple slope`        = sprintf("%.4f", df[[trend_col]]),
    `SE`                  = sprintf("%.4f", df$SE),
    `95% CI`              = sprintf("[%.4f, %.4f]", df$lower.CL, df$upper.CL),
    `t`                   = sprintf("%.3f", df$t.ratio),
    `p`                   = ifelse(df$p.value < .001, "< .001",
                                   sprintf("%.3f", df$p.value)),
    check.names = FALSE
  )
}

# Format emtrends output into a simple-slopes row set for a 0/1 dummy
# moderator (negative event occurrence). Two rows per predictor. Used in
# 06_study_component_1.qmd (exploratory h3.3 with D_neg).
make_rows_dummy <- function(df, trend_col, predictor_label) {
  data.frame(
    `Predictor`      = predictor_label,
    `Negative event` = c("No (0)", "Yes (1)"),
    `Simple slope`   = sprintf("%.4f", df[[trend_col]]),
    `SE`             = sprintf("%.4f", df$SE),
    `95% CI`         = sprintf("[%.4f, %.4f]", df$lower.CL, df$upper.CL),
    `t`              = sprintf("%.3f", df$t.ratio),
    `p`              = ifelse(df$p.value < .001, "< .001",
                              sprintf("%.3f", df$p.value)),
    check.names = FALSE
  )
}


# ============================================================================ #
# MEDIATION DIAGRAM HELPERS
# Used in 07_study_component_2.qmd (Step 2) for tidySEM mediation path diagrams
# ============================================================================ #

# Format a path coefficient with CI and significance stars for diagram labels
fmt <- function(est, ci_low, ci_up, p) {
  stars <- ifelse(p < .001, "***", ifelse(p < .01, "**", ifelse(p < .05, "*", " (ns)")))
  sprintf("%.3f%s [%.3f, %.3f]", est, stars, ci_low, ci_up)
}

# Return black for significant paths, grey for non-significant paths
# (used for both arrow colour and label colour in diagrams)
sig_col <- function(p) ifelse(p < .05, "black", "grey75")

# Look up a node's (x, y) coordinates in a tidySEM node data frame. `nd`
# should be the data frame returned by tidySEM::nodes(p_mod); `name` is the
# node name (e.g. "X", "M", "Y", "W"). Used throughout 06_study_component_1.qmd
# (and 07) when placing annotations relative to tidySEM path diagrams.
get_node <- function(nd, name) nd[nd$name == name, c("x", "y")]


# ============================================================================ #
# SUMMARY TABLE HELPERS
# Used in 07_study_component_2.qmd for kableExtra summary tables
# ============================================================================ #

# Extract a fixed effect from an nlme::lme model and format it with
# significance stars and HTML bold tags for use in kable summary tables
fmt_cell <- function(model, param) {
  tt <- summary(model)$tTable
  if (!(param %in% rownames(tt))) return("")
  est <- tt[param, "Value"]
  p   <- tt[param, "p-value"]
  stars <- ifelse(p < .001, "***", ifelse(p < .01, "**", ifelse(p < .05, "*", "")))
  txt <- sprintf("%.3f%s", est, stars)
  if (p < .05) txt <- paste0("<b>", txt, "</b>")
  txt
}

# Format a Monte Carlo indirect effect result for use in kable summary tables
# (takes the list returned by mc_ci as input)
fmt_mc <- function(res) {
  p <- res$p
  stars <- ifelse(p < .001, "***", ifelse(p < .01, "**", ifelse(p < .05, "*", "")))
  txt <- sprintf("%.3f%s", res$point, stars)
  if (p < .05) txt <- paste0("<b>", txt, "</b>")
  txt
}

# Extract a one-row summary for an exploratory perceived-PA model: intercept,
# slope on PA_sim_perc, and the dyad-level ICC. Used in 07_study_component_2.qmd
# for the perceived PA similarity summary table.
extract_row <- function(mod, outcome, context) {
  vc   <- as.numeric(nlme::VarCorr(mod)[, "Variance"])
  tau2 <- vc[1]
  sig2 <- vc[2]
  icc  <- tau2 / (tau2 + sig2)
  data.frame(
    Outcome = outcome,
    Context = context,
    b0      = fmt_cell(mod, "(Intercept)"),
    b1      = fmt_cell(mod, "PA_sim_perc"),
    ICC     = sprintf("%.3f", icc)
  )
}

# Same as extract_row() but reads the NA_sim_perc slope. Used in
# 07_study_component_2.qmd for the perceived NA similarity summary table.
extract_row_na <- function(mod, outcome, context) {
  vc   <- as.numeric(nlme::VarCorr(mod)[, "Variance"])
  tau2 <- vc[1]
  sig2 <- vc[2]
  icc  <- tau2 / (tau2 + sig2)
  data.frame(
    Outcome = outcome,
    Context = context,
    b0      = fmt_cell(mod, "(Intercept)"),
    b1      = fmt_cell(mod, "NA_sim_perc"),
    ICC     = sprintf("%.3f", icc)
  )
}


# ============================================================================ #
# RESPONSE SURFACE ANALYSIS (RSA)
# Used in 08_response_surface_analysis.qmd to compute RSA surface parameters
# (a1–a5) from polynomial lme fits and to render 3D / 2D response surfaces
# ============================================================================ #

# Compute the five RSA surface parameters (a1–a5) and their standard errors
# from an lme model with fixed effects ordered as:
#   intercept, b1 (X), b2 (Y), b3 (X^2), b4 (XY), b5 (Y^2)
# Returns a data.frame with Estimate, SE, z, p, and significance stars.
rsa_params <- function(model) {
  b  <- fixef(model)
  b1 <- b[2]; b2 <- b[3]; b3 <- b[4]; b4 <- b[5]; b5 <- b[6]

  a1 <- b1 + b2       # LOC slope
  a2 <- b3 + b4 + b5  # LOC curvature
  a3 <- b1 - b2       # LOIC slope
  a4 <- b3 - b4 + b5  # LOIC curvature
  a5 <- b3 - b5       # FPA = LOC condition

  # Standard errors via delta method (variance of linear combos)
  V <- vcov(model)
  se_a1 <- sqrt(V[2,2] + V[3,3] + 2*V[2,3])
  se_a2 <- sqrt(V[4,4] + V[5,5] + V[6,6] + 2*V[4,5] + 2*V[4,6] + 2*V[5,6])
  se_a3 <- sqrt(V[2,2] + V[3,3] - 2*V[2,3])
  se_a4 <- sqrt(V[4,4] + V[5,5] + V[6,6] - 2*V[4,5] + 2*V[4,6] - 2*V[5,6])
  se_a5 <- sqrt(V[4,4] + V[6,6] - 2*V[4,6])

  params <- data.frame(
    Parameter = c("a1 (LOC slope)", "a2 (LOC curvature)",
                  "a3 (LOIC slope)", "a4 (LOIC curvature)",
                  "a5 (FPA = LOC)"),
    Meaning   = c("Slope along X = Y at origin",
                  "Curvature along X = Y",
                  "Slope along X = −Y at origin",
                  "Curvature along X = −Y",
                  "Ridge displacement from LOC"),
    Estimate = c(a1, a2, a3, a4, a5),
    SE       = c(se_a1, se_a2, se_a3, se_a4, se_a5),
    stringsAsFactors = FALSE
  )
  params$z   <- params$Estimate / params$SE
  params$p   <- 2 * pnorm(-abs(params$z))
  params$sig <- ifelse(params$p < .001, "***",
                ifelse(params$p < .01,  "**",
                ifelse(params$p < .05,  "*", "")))
  params
}

# 3D response surface plot (plotly mesh3d) overlaid with observed data
# points. The surface is coloured on a diverging blue–white–red scale
# anchored to z_lim (fixed across models for visual comparability); the
# LOC (X = Y) is painted solid black and the LOIC (X = −Y) as a black
# dashed pattern. A hidden scatter3d trace carries the colorbar legend.
plot_rsa_surface <- function(model, data, x_var, y_var,
                             x_lab  = "Actor affect (centered)",
                             y_lab  = "Partner affect (centered)",
                             title  = "Response Surface",
                             z_lab  = "Momentary love",
                             z_lim  = c(0, 100),
                             x_range = c(-95, 95),
                             y_range = c(-95, 95)) {

  # ---- fixed effects: intercept, x, y, x^2, x:y, y^2 ----
  b <- as.numeric(nlme::fixef(model))
  if (length(b) < 6) {
    stop("fixef(model) must return at least 6 coefficients ordered as: intercept, x, y, x^2, x:y, y^2")
  }
  b <- b[1:6]

  poly_fun <- function(x, y) {
    b[1] + b[2] * x + b[3] * y + b[4] * x^2 + b[5] * x * y + b[6] * y^2
  }

  # ---- plotting ranges ----
  x_range <- x_range
  y_range <- y_range

  n_grid <- 150L
  x_seq  <- seq(x_range[1], x_range[2], length.out = n_grid)
  y_seq  <- seq(y_range[1], y_range[2], length.out = n_grid)

  Xmat <- outer(x_seq, y_seq, function(x, y) x)
  Ymat <- outer(x_seq, y_seq, function(x, y) y)
  Zmat <- poly_fun(Xmat, Ymat)

  vx <- as.vector(Xmat)
  vy <- as.vector(Ymat)
  vz <- as.vector(Zmat)

  vid <- function(ix, iy) ix + (iy - 1L) * n_grid

  # ---- diverging palette (fixed to love's natural scale, not per-plot z-range) ----
  # Using z_lim as the colour anchor means all four response surfaces share a
  # comparable colour mapping — a blue patch on one plot represents the same
  # predicted love as a blue patch on another.
  ramp_lo <- grDevices::colorRamp(c("#2166ac", "#f7f7f7"))
  ramp_hi <- grDevices::colorRamp(c("#f7f7f7", "#b2182b"))

  z_to_col <- function(z) {
    u <- (z - z_lim[1]) / (z_lim[2] - z_lim[1])
    u <- pmin(pmax(u, 0), 1)

    out <- character(length(u))
    lo  <- u <= 0.5
    hi  <- !lo

    if (any(lo)) {
      rgb_lo <- ramp_lo(u[lo] / 0.5)
      out[lo] <- grDevices::rgb(rgb_lo[, 1], rgb_lo[, 2], rgb_lo[, 3],
                                maxColorValue = 255)
    }
    if (any(hi)) {
      rgb_hi <- ramp_hi((u[hi] - 0.5) / 0.5)
      out[hi] <- grDevices::rgb(rgb_hi[, 1], rgb_hi[, 2], rgb_hi[, 3],
                                maxColorValue = 255)
    }
    out
  }

  # ---- explicit triangulation ----
  n_faces <- 2L * (n_grid - 1L) * (n_grid - 1L)
  ii <- integer(n_faces); jj <- integer(n_faces); kk <- integer(n_faces)
  face_x <- numeric(n_faces); face_y <- numeric(n_faces); face_z <- numeric(n_faces)
  loc_hit  <- logical(n_faces)
  loic_hit <- logical(n_faces)

  pos <- 1L
  for (iy in 1:(n_grid - 1L)) {
    for (ix in 1:(n_grid - 1L)) {
      v00 <- vid(ix, iy)
      v10 <- vid(ix + 1L, iy)
      v11 <- vid(ix + 1L, iy + 1L)
      v01 <- vid(ix, iy + 1L)

      # triangle 1: (v00, v10, v11)
      tri1 <- c(v00, v10, v11)
      x1 <- vx[tri1]; y1 <- vy[tri1]; z1 <- vz[tri1]
      ii[pos] <- tri1[1] - 1L; jj[pos] <- tri1[2] - 1L; kk[pos] <- tri1[3] - 1L
      face_x[pos] <- mean(x1); face_y[pos] <- mean(y1); face_z[pos] <- mean(z1)
      loc_hit[pos]  <- (min(x1 - y1) <= 0) && (max(x1 - y1) >= 0)
      loic_hit[pos] <- (min(x1 + y1) <= 0) && (max(x1 + y1) >= 0)
      pos <- pos + 1L

      # triangle 2: (v00, v11, v01)
      tri2 <- c(v00, v11, v01)
      x2 <- vx[tri2]; y2 <- vy[tri2]; z2 <- vz[tri2]
      ii[pos] <- tri2[1] - 1L; jj[pos] <- tri2[2] - 1L; kk[pos] <- tri2[3] - 1L
      face_x[pos] <- mean(x2); face_y[pos] <- mean(y2); face_z[pos] <- mean(z2)
      loc_hit[pos]  <- (min(x2 - y2) <= 0) && (max(x2 - y2) >= 0)
      loic_hit[pos] <- (min(x2 + y2) <= 0) && (max(x2 + y2) >= 0)
      pos <- pos + 1L
    }
  }

  face_col <- z_to_col(face_z)

  # ---- LOIC dashed pattern ----
  loic_tmin <- max(x_range[1], -y_range[2])
  loic_tmax <- min(x_range[2], -y_range[1])
  loic_span <- loic_tmax - loic_tmin

  if (is.finite(loic_span) && loic_span > 0) {
    t_loic   <- (face_x - face_y) / 2
    dash_len <- loic_span / 30
    gap_len  <- dash_len * 0.4
    phase    <- (t_loic - loic_tmin) %% (dash_len + gap_len)
    loic_on  <- loic_hit & (phase <= dash_len)
  } else {
    loic_on <- rep(FALSE, length(face_col))
  }

  # paint LOC/LOIC into the face colour vector
  face_col[loic_on] <- "#000000"
  face_col[loc_hit] <- "#000000"

  # ---- observed data points (subsample for rendering speed) ----
  obs <- data %>%
    dplyr::select(x = dplyr::all_of(x_var),
                  y = dplyr::all_of(y_var),
                  z = love) %>%
    dplyr::filter(stats::complete.cases(.)) %>%
    dplyr::filter(x >= x_range[1], x <= x_range[2],
                  y >= y_range[1], y <= y_range[2])
  if (nrow(obs) > 2000) obs <- obs %>% dplyr::slice_sample(n = 2000)

  # ---- colorbar trace: invisible scatter3d carrying the colour scale ----
  # mesh3d with facecolor can't display a colorbar, so we attach one to a
  # hidden marker trace placed off-screen. The colorscale here must match the
  # z_to_col() mapping above so the legend reflects what the surface shows.
  cbar_scale <- list(
    c(0.0, "#2166ac"),
    c(0.5, "#f7f7f7"),
    c(1.0, "#b2182b")
  )

  plotly::plot_ly() %>%
    # main surface
    plotly::add_trace(
      type = "mesh3d",
      x = vx, y = vy, z = vz,
      i = ii, j = jj, k = kk,
      facecolor = I(face_col),
      flatshading = FALSE,
      opacity = 0.65,
      lighting = list(
        ambient = 0.85, diffuse = 0.7, specular = 0.03,
        roughness = 0.9, fresnel = 0.02
      ),
      lightposition = list(x = 100, y = 200, z = 0),
      name = "Surface",
      showlegend = FALSE
    ) %>%
    # observed data points
    plotly::add_markers(
      x = obs$x, y = obs$y, z = obs$z,
      marker = list(size = 1.5, color = "black", opacity = 0.25),
      name = "Observed",
      showlegend = FALSE
    ) %>%
    # hidden colorbar trace
    plotly::add_trace(
      type = "scatter3d",
      mode = "markers",
      x = c(x_range[1], x_range[1]),
      y = c(y_range[1], y_range[1]),
      z = z_lim,
      marker = list(
        size = 0.1,
        color = z_lim,
        colorscale = cbar_scale,
        cmin = z_lim[1],
        cmax = z_lim[2],
        showscale = TRUE,
        colorbar = list(
          title = list(text = "Predicted\nlove"),
          len = 0.7
        )
      ),
      hoverinfo = "skip",
      showlegend = FALSE
    ) %>%
    plotly::layout(
      title = list(text = title),
      scene = list(
        xaxis = list(title = x_lab),
        yaxis = list(title = y_lab),
        zaxis = list(title = z_lab, range = z_lim),
        camera = list(eye = list(x = 1.5, y = -1.5, z = 1.2))
      ),
      annotations = list(
        list(
          x = 0.01, y = 0.99, xref = "paper", yref = "paper",
          text = "<b>LOC</b>: solid black&nbsp;&nbsp;&nbsp;<b>LOIC</b>: dashed",
          showarrow = FALSE, xanchor = "left", yanchor = "top",
          bgcolor = "rgba(255,255,255,0.75)",
          bordercolor = "rgba(0,0,0,0.15)",
          borderwidth = 1
        )
      )
    ) %>%
    plotly::partial_bundle("gl3d")
}

# 2D static alternative to plot_rsa_surface(): filled contour plot of the
# fitted polynomial surface over a fixed (-50, 50) window, with the LOC
# (solid) and LOIC (dashed) lines annotated.
plot_rsa_contour <- function(model, data, x_var, y_var,
                             x_lab = "Actor affect (centered)",
                             y_lab = "Partner affect (centered)",
                             title = "Response Surface (contour)") {

  b <- fixef(model)

  x_range <- c(-50, 50)
  y_range <- c(-50, 50)

  grid <- expand.grid(
    X = seq(x_range[1], x_range[2], length.out = 100),
    Y = seq(y_range[1], y_range[2], length.out = 100)
  )

  grid$Z <- b[1] + b[2]*grid$X + b[3]*grid$Y +
            b[4]*grid$X^2 + b[5]*grid$X*grid$Y + b[6]*grid$Y^2

  ggplot(grid, aes(x = X, y = Y, z = Z)) +
    geom_contour_filled(alpha = 0.8) +
    geom_abline(intercept = 0, slope = 1, linetype = "solid", colour = "black") +
    geom_abline(intercept = 0, slope = -1, linetype = "dashed", colour = "black") +
    annotate("text", x = x_range[2]*0.85, y = x_range[2]*0.85,
             label = "LOC (X = Y)", angle = 45, size = 3, colour = "black") +
    annotate("text", x = x_range[2]*0.85, y = -x_range[2]*0.85,
             label = "LOIC (X = −Y)", angle = -45, size = 3, colour = "black") +
    labs(x = x_lab, y = y_lab, fill = "Predicted\nlove", title = title) +
    coord_fixed() +
    theme_minimal()
}
