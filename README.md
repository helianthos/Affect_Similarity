# Feeling the Same, Seeing the Same

Reproducible analysis code accompanying the OSF preregistration for the internship project “Feeling the Same, Seeing the Same” in the context of the program *Master in Psychology: Theory and Research*.

**Author:** Geert Van Dingenen

**Supervisor:** Prof. Peter Kuppens

**Affiliation:**\
KU Leuven – Faculty of Psychology and Educational Sciences\
Research Unit Quantitative Psychology and Individual Differences

**Preregistration:**\
Open Science Framework (OSF):\
<https://doi.org/10.17605/OSF.IO/V7T9F>

**Contact:**\
geert.vandingenen\@student.kuleuven.be

**Last updated:**\
2026-01-27

## Project overview

This repository contains the analysis code to investigate actual and perceived affect similarity in romantic couples across daily life and laboratory interaction contexts. The primary aim is to examine how affect similarity between partners relates to relational outcomes (e.g., love, closeness), how this association depends on perceived similarity, and how it is moderated by contextual and person-level factors.

The study hypotheses, operationalizations, methodology, and analysis plan were preregistered on the Open Science Framework (OSF). All confirmatory analyses in this repository are implemented in accordance with the preregistration. Any deviations or additional exploratory analyses are explicitly labeled as such in the corresponding analysis scripts or reports.

## Reproducibility

This project uses: - **R** for all data processing and analyses, - **renv** for reproducible package management, and - **Git/GitHub** for version control.

Raw data files are stored locally (e.g., via OneDrive) and are not tracked in this repository. Analysis-ready datasets are generated reproducibly from the raw data using the scripts in this project.

### How to set up and run the project

#### *1. Obtain the code*

You can either:

-   clone this repository from GitHub, or

-   download the final project archive (ZIP) from OSF and extract it.

#### *2. Open the project*

Open the RStudio project file `Internship.Rproj`.

This will automatically activate the project-specific R environment via **renv** by auto-running .Rprofile.

#### *3. Restore the R package environment*

In the R console, run `renv::restore()`

This installs the exact package versions specified in `renv.lock`.

#### *4. Provide access to the raw data (csv)*

Raw data files are **not included** in this repository. Request the raw CSV files and create a machine-specific path configuration file (it will not be tracked by git):

1.  Copy the template: `config/local_raw_data_path_TEMPLATE.R` → `config/local_raw_data_path.R`
2.  Open `config/local_raw_data_path.R` and set `RAW_DATA_DIR` to the folder that contains the raw CSV files on your machine.
3.  Restart R (Session → Restart R) or re-source the paths or setup script.

The project will read raw data from `RAW_DATA_DIR`.

#### *5. Import raw data in R*

Run the import script to generate analysis-ready datasets: `source("scripts/01_data_import.R")`

Imported data files will be written to `data/imported/`.

These files are generated locally and are not tracked by git.

#### *6. Run analyses*

Analyses and reports are implemented in the `analysis/` folder using R Markdown files (e.g., `01_descriptives.Rmd`, `02_models.Rmd`).

Confirmatory analyses follow the preregistered analysis plan. Any exploratory analyses are explicitly labeled as such.

## Project structure

``` text
project/
│
├── README.md
│   └── Project overview, setup instructions, and folder structure
│
├── renv_workflow.md
│   └── Documentation of the renv workflow
│       (for info, project management information)
│
├── project.Rproj
│   └── RStudio project file
│
├── .gitignore
│   └── Git ignore rules (derived data, outputs, RStudio files, etc.)
│
├── renv.lock
│   └── Locks exact package versions used in this project (reproducibility)
│
├── .Rprofile
│   └── Automatically activates renv when the project is opened
│
├── config/
│   ├── local_raw_data_path_TEMPLATE.R
│   │   └── Template to copy to local_raw_data_path.R and updated by user
│   └── local_raw_data_path.R
│       └── created locally by user from TEMPLATE with updated raw data directory
│           (git ignored)
│
├── renv/
│   ├── activate.R
│   │   └── renv bootstrap script (auto-runs; do not edit manually)
│   └── .gitignore
│       └── Ignores renv internal folders (library/, sandbox/, etc.)
│
├── R/
│   ├── 00_setup.R
│   │   └── Setup script to load libraries, define file paths, load dataset
│   │       structures and user defined functions
│   │       (uses 01_paths, 02_packages.R, 03_data_config.R, and 04_functions.R)
│   │
│   ├── 01_paths.R
│   │   └── Defines file paths used across scripts. Machine-specific raw data path
│   │       is read from config/local_raw_data_path.R
│   │
│   ├── 02_packages.R
│   │   └── Loads all libraries required by the project
│   │       (no installation; assumes renv::restore() has been run)
│   │
│   ├── 03_data_config.R
│   │   └── Central dataset structure/variable mappings for the 4 imported datasets
│   │
│   └── 04_functions.R
│       └── User-defined helper functions reused across scripts and analyses
│           (e.g., checks, transformations, similarity computations)
│
├── scripts/
│   ├── 01_data_import.R
│   │   └── Reads raw CSV files and saves derived .rds files
│   │
│   ├── 02_data_checks.R
│   │   └── Checks on the imported .rds files
│   │
│   └── 03_construct.R
│       └── Constructs scales, similarity indices, and derived variables
│
├── analysis/
│   ├── 01_descriptives.Rmd
│   │   └── Descriptive statistics and exploratory plots
│   │
│   └── 02_models.Rmd
│       └── Main preregistered statistical models and reporting
│
├── data/
│   └── imported/
│       └── .gitkeep
│           └── Placeholder so the folder exists after cloning
│               (contents are regenerated locally and ignored by Git)
│
└── outputs/
    ├── plots/
    │   └── Saved plots (not tracked by default)
    ├── tables/
        └── Saved tables (not tracked by default)
    └── log/
         └── Saved log outputs (not tracked by default)
        
```
