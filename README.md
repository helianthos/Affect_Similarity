# Feeling the Same, Seeing the Same

Reproducible analysis and reporting code accompanying the OSF preregistration for the internship project “Feeling the Same, Seeing the Same”, in the context of the program *Master in Psychology: Theory and Research*.

**Author:** Geert Van Dingenen

**Supervisor:** Prof. Peter Kuppens

**Affiliation:**\
KU Leuven – Faculty of Psychology and Educational Sciences\
Research Unit Quantitative Psychology and Individual Differences

**Preregistration:**\
Open Science Framework (OSF):\
<https://doi.org/10.17605/OSF.IO/E5SZ2>

**Contact:**\
geert.vandingenen\@student.kuleuven.be / geert.vandingenen\@gmail.com

**Last updated:**\
2026-04-17

## Project overview

This repository contains the analysis and reporting code to investigate actual and perceived affect similarity in romantic couples across daily life and laboratory interaction contexts. The primary aim is to examine how affect similarity between partners relates to relational outcomes (e.g., love, closeness), how this association depends on perceived similarity, and how it is moderated by contextual and person-level factors.

The study hypotheses, operationalizations, methodology, and analysis plan were preregistered on the Open Science Framework (OSF). All confirmatory analyses in this repository are implemented in accordance with the preregistration. Any deviations or additional exploratory analyses are explicitly labeled as such in the corresponding analysis scripts or reports.

In addition to the reproducible source files, the repository also contains a `docs/` folder with pre-rendered HTML reports and an `index.html` landing page intended for public browsing via GitHub Pages (https://helianthos.github.io/Affect_Similarity/).

## Reproducibility

This project uses:

- **R** for all data processing and analyses,

- **renv** for reproducible package management, and

- **git/GitHub** for version control.

Raw data files are stored locally (e.g., via OneDrive) and are not tracked in this repository. Analysis-ready datasets are generated reproducible from the raw data using the scripts in this project.

### Recommended setup

For most users, the recommended way to work with this project is to use **RStudio Desktop** together with **Quarto**.

1.  Install **R**
2.  Install the latest **RStudio Desktop**: <https://posit.co/downloads/>
3.  Install **Quarto**: <https://quarto.org/docs/download/>
4.  Open `Affect_Similarity.Rproj` in RStudio

A recent version of RStudio is recommended, because Quarto support for `.qmd` files depends on the IDE version. For the analyses in this project, we mainly used **RStudio version 2026.01.0+392**.

Once Quarto is installed, RStudio will recognize the `.qmd` files in `scripts/` and provide the usual **Render** workflow for the analysis reports.

You can also work with this repository in **VS Code** or another IDE/editor that supports R. In that case, open the repository folder itself (`Affect_Similarity/`) as your workspace/project root and start R from that root so that `.Rprofile` is loaded and project-relative paths resolve correctly.

### How to set up and run the project

#### *1. Obtain the code*

You can either:

- clone this repository from GitHub, or

- download the final project archive (ZIP) from OSF and extract it.

#### *2. Open the project*

If you are using **RStudio** (recommended), open `Affect_Similarity.Rproj`.

If you are using **VS Code** or another IDE/editor, open the repository folder itself (`Affect_Similarity/`) as your workspace/project root.

In both cases, the project root should be the working directory so that `.Rprofile` is loaded and project-relative paths resolve correctly.

When opened from the project root, the project-specific R environment will be activated via `.Rprofile`.

#### *3. Restore the R package environment*

In the R console, run `renv::restore()`.

This installs the exact package versions specified in `renv.lock`, to make sure the code does not break because packages get updated.

#### *4. Provide access to the raw data (csv)*

Raw data files are **not included** in this repository. Request the raw CSV files and create a computer-specific path configuration file so the scripts know where to find the data:

The raw-data folder may contain other `.csv` files, but the import script requires at least the following files to be present under these exact filenames:

- `CCS_BGQuestionnaireV2_with_screener.csv`
- `CCS_ESMbeeps_individual.csv`
- `CCS_VMR_preprocessed.csv`
- `CCS_Preprocessed_PostInteractionQ.csv`

These are the preprocessed raw-data exports used as inputs for this project's reproducible pipeline.

1.  Copy the template: `config/local_raw_data_path_TEMPLATE.R` and rename it to `config/local_raw_data_path.R`
2.  Open `config/local_raw_data_path.R` and set `RAW_DATA_DIR` to the folder that contains the raw CSV files on your machine.
3.  Restart R (Session → Restart R). The first script for the data processing (see below) will read in the csv files.

This is the only path that is computer/user dependent and needs to be provided.

#### *5. Data processing*

In the `scripts/` folder, there are 4 R scripts to go from the raw csv data files to processed R datasets that are ready for analysis:

1.  `scripts/01_data_import.R`

    Imported data files will be written to `data/imported/*`.

2.  `scripts/02_data_checks.R`

    Performs various checks on the imported data.

3.  `scripts/03_data_reduction.R`

    Reducing datasets to variables of interest for the present research. Correcting data (with documentation of why). Reduced and corrected datasets will be written to `data/reduced/*`.

4.  `scripts/04_data_construct.R`

    Extends datasets by adding centered variables, similarity measures (actual and perceived), and the "we-ness" construct. Analysis-ready datasets will be written to `data/analysis/*`.

These scripts should be run in that order (for example using `source("scripts/xyz.R")`) to generate the datasets for analysis. For every script, a log file will be generated in `outputs/logs/`.

#### *6. Analyses*

Descriptives and analyses can be found in the `scripts/` folder as Quarto `.qmd` files. Rendering these files creates HTML reports and saves them to `outputs/scripts/*`:

If you are working in **RStudio** (recommended), open a `.qmd` file and click **Render** to generate the corresponding HTML report.

If you are working from another IDE or from the command line, you can render an individual report with:

`quarto render scripts/05_descriptives.qmd`

or render the full project from the project root with:

`quarto render`

1.  `scripts/05_descriptives.qmd`

2.  `scripts/06_study_component_1.qmd`

3.  `scripts/07_study_component_2.qmd`

4.  `scripts/08_response_surface_analysis.qmd`

Confirmatory analyses follow the preregistered analysis plan. Any exploratory analyses are explicitly labeled as such.

#### *7. Public HTML website (GitHub Pages)*

The repository can additionally serve a public-facing website through GitHub Pages using the `docs/` folder.

This folder contains: - `docs/index.html`: a landing page linking to the rendered reports - pre-rendered HTML copies of selected reports for direct online viewing

Typical contents of `docs/`:

- `docs/index.html`
- `docs/05_descriptives.html`
- `docs/06_study_component_1.html`
- `docs/07_study_component_2.html`
- `docs/08_response_surface_analysis.html`

This setup makes it possible to:

- keep the repository fully reproducible from source,

- preserve rendered outputs in `outputs/scripts/`, and

- provide a browsable public website through GitHub Pages.

## Project structure

``` text
project/
│
├── README.md
│   └── This file, with project overview, setup instructions, and folder structure
│
├── Affect_Similarity.Rproj
│   └── RStudio project file
│
├── renv_workflow.md
│   └── Documentation of the renv workflow
│
├── renv.lock
│   └── Locks exact package versions used in this project (reproducibility)
│
├── .Rprofile
│   └── Automatically activates renv when the project is opened
│
├── _quarto.yml
│   └── Global project-wide Quarto report settings
│
├── project.css
│   └── Custom CSS styling for rendered Quarto HTML reports
│
├── affectlogo.png
│   └── Logo image used in the rendered Quarto report layout
│
├── references.bib
│   └── Citation data for the rendered Quarto reports 
│
├── apa.csl
│   └── Citation style for the rendered Quarto reports (APA 7)
│
├── .gitignore
│   └── Git ignore rules (derived data, outputs, RStudio files, etc.)
│
├── config/
│   ├── local_raw_data_path_TEMPLATE.R
│   │   └── Template to copy to local_raw_data_path.R
│   └── local_raw_data_path.R
│       └── Created and updated locally by user from TEMPLATE
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
│   │       structures, and source user-defined functions
│   │       (uses 01_paths.R, 02_packages.R, 03_data_config.R, and 04_functions.R)
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
│   │   └── Central dataset structure/variable mappings for the imported datasets
│   │
│   └── 04_functions.R
│       └── User-defined helper functions reused across scripts and analyses
│           (e.g., checks, transformations, similarity computations)
│
├── scripts/
│   ├── 01_data_import.R
│   │   └── Reads raw CSV files and saves imported .rds files
│   │
│   ├── 02_data_checks.R
│   │   └── Performs various checks on the imported data.
│   │
│   ├── 03_data_reduction.R
│   │   └── Data correction and reduction to variables of interest
│   │
│   ├── 04_data_construct.R
│   │   └── Constructs scales, similarity indices, and derived variables
│   │
│   ├── 05_descriptives.qmd
│   │   └── Descriptive analyses (demographics, correlations, etc.)
│   │
│   ├── 06_study_component_1.qmd
│   │   └── Analyses for the research questions from component 1
│   │
│   ├── 07_study_component_2.qmd
│   │   └── Analyses for the research questions from component 2
│   │
│   │
│   ├── 08_response_surface_analysis.qmd
│   │   └── Response surface analyses
│   │
│   └── _extensions/mcanouil/collapse-output/
│       └── Quarto extension to collapse long output in rendered HTML files
│
├── docs/
│   ├── index.html
│   │   └── Landing page for public browsing via GitHub Pages
│   ├── 05_descriptives.html
│   ├── 06_study_component_1.html
│   ├── 07_study_component_2.html
│   └── 08_response_surface_analysis.html
│
├── data/          (folder .gitkeep but contents generated locally)
│   ├── imported/
│   │   └── Data imported from raw preprocessing files
│   │
│   ├── reduced/
│   │   └── Data reduced to variables of interest
│   │
│   └── analysis/
│       └── Analysis-ready datasets
│
└── outputs/       (folder .gitkeep but contents generated locally)
    ├── plots/
    │   └── Saved plots
    │
    ├── logs/
    │   └── Saved log outputs
    │     
    └── scripts/
        └── Rendered Quarto HTML reports generated from source
        
```