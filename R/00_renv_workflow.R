# ============================================================
# 00_renv_workflow.R
#
# Purpose:
#   Document how we manage packages in this project using renv.
#   This file is NOT run automatically. It is a reference.
#
# Key idea:
#   - renv::init() sets up a project-specific library (run once)
#   - install.packages() installs into the project library
#   - renv::snapshot() updates renv.lock (commit this file)
#   - renv::restore() installs the locked versions on a new machine
# ============================================================

# ---- Run once (project setup) ------------------------------
# renv::init()

# ---- Daily work --------------------------------------------
# Install packages as needed while working in the project:


# After adding/removing packages you ACTUALLY use,
# update the lockfile and commit it:
# renv::snapshot()

# ---- New machine / fresh clone -----------------------------
# After pulling the repo:
# renv::restore()

# ---- Useful checks -----------------------------------------
# See whether renv is active:
# renv::status()

# See library paths currently used (should include project/renv/library):
# .libPaths()
