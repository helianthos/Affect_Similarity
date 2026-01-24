
# ---- Activate renv ----
source("renv/activate.R")

# ---- Check renv status and remind to restore if needed ----
local({
  # Only proceed if renv is installed
  if (!requireNamespace("renv", quietly = TRUE)) return()
  
  # Run status quietly; it prints a report to the console
  status <- try(renv::status(), silent = TRUE)
  if (inherits(status, "try-error")) return()
})
