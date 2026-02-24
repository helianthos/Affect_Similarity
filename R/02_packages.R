# ============================================================
# R/02_packages.R
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
#   Source this file to load all packages:  source(here::here("R", "02_packages.R"))
#   Sourcing is included in R/00_setup.R together with R/01_paths.R, 
#   R/03_data_config.R, and R/04_functions.R
#
# Reproducibility:
#   - Required package versions are recorded in renv.lock.
#   - On a new machine, run renv::restore() before sourcing this file.
# ============================================================

library(tidyverse)
library(here)
library(naniar)
library(psych)
library(rmcorr)
library(glmmTMB) # for beta regression
library(lme4)
library(lmerTest) # load after lme4 to avoid any conflicts in summary()
library(performance)
library(GPArotation)
library(gt)
library(plotly)
library(vioplot)
library(nlme) # for corAR1 in lme models; not in renv.lock because in R's default installed packages
library(car)
library(patchwork)