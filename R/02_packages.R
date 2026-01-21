# ============================================================
# 02_packages.R
#
# Purpose:
#   Load all R packages required for this project.
#
# Notes:
#   - This file ONLY loads packages using library().
#   - Package installation is managed via renv.
#   - Do NOT call install.packages() in this file.
#
# Usage:
#   Source this file at the top of scripts and R Markdown files:
#     source("R/02_packages.R")
#
# Reproducibility:
#   - Required package versions are recorded in renv.lock.
#   - On a new machine, run renv::restore() before sourcing this file.
# ============================================================

# Core
library(tidyverse)
library(here)
library(naniar)
library(psych)
