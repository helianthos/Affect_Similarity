# Package management using renv

renv_workflow.md documents how packages in this project are managed using renv.

### Key idea:

-   `renv::init()` sets up a project-specific library (run once)

-   `install.packages()` installs into the project library

-   `renv::snapshot()` updates renv.lock (commit this file)

-   `renv::restore()` installs the locked versions on a new machine

### Run once (project setup)

`renv::init()`

### Daily work

Install packages as needed while working in the project. After adding/removing packages ACTUALLY used, update the lockfile and commit it: `renv::snapshot()`

### New machine / fresh clone

After pulling the repo, do `renv::restore()`

### Useful commands

-   See whether renv is active: `renv::status()`

-   See library paths currently used (should include project/renv/library): `.libPaths()`
