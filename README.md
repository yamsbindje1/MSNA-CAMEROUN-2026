# MSNA Cameroun 2026 – analysis pipeline

R scripts of the MSNA Cameroun 2026 analysis pipeline (IMPACT Initiatives / REACH, project CMR2601).
From the clean dataset, the pipeline computes the sector indicators, the composites and the MSNI, runs the
weighted analysis and writes the frequency tables and the bulletin inputs. Everything is started from `run.R`.

> **This repository holds the scripts only.** The dataset, the Kobo tool, the sampling frame and all outputs are
> kept out of it (see `.gitignore`). To run the pipeline, put the input files in `inputs/` (section 3).
>

Prepared by Yams Bindje, Data Specialist (IMPACT). Pipeline harmonised with Niger and Mali (October 2026).

---

## 1. Folder structure

| Path | Content |
|---|---|
| `run.R` | Entry point: all settings and the list of steps |
| `src/01_…` to `src/10_…` | Pipeline steps, numbered in execution order (07, 08 and 11, InDesign, not included) |
| `src/functions/` | Functions and indicator scripts used by the steps |
| `src/functions/composite_indicators/` | Sector indicators (sourced by `00_run_all.R`) |
| `src/functions/hesper/` | HESPER functions (`hesper_apply.R` applies them) |
| `src/functions/msni_scores.R` | Cameroun MSNI rules (sector composites + MSNI) |
| `src/functions/indicators_from_dictionary.R` | New indicators described in the tag dictionary (called by 10) |
| `src/functions/edu_analysis_tool_indicators.R` | Education indicators of the EduAnalysisTool (called by 05) |
| `src/tools/export_gis_map_values.R` | GIS map values (national, Admin 1, Admin 2), run separately after a run |
| `inputs/` | *Not versioned* – input files (section 3) |
| `Output/Cameroun/` | *Not versioned* – results created by the pipeline |

## 2. Packages and how to run

1. Open the RStudio project at the root of the folder (the project root is used by `here()`).
2. Put the input files in `inputs/` and check section 1 of `run.R`.
3. Run `source("run.R")`.

R ≥ 4.3 recommended. The dataset is large: plan for at least 16 GB of RAM.

`src/01_packages.R` installs the missing packages:

- **GitHub**: humind (validated with version 2026.4.1), analysistools, presentresults, phrindicators, hypegrammaR, composr,
  impactR.utils
- **GitLab**: robotoolbox
- **CRAN**: readxl, writexl, lubridate, stringr, dplyr, data.table, tidyverse, openxlsx, sjstats, here, remotes,
  devtools, knitr

The package load order in `01` is kept on purpose: it decides which function is used when two packages export the
same name.

## 3. Input files (`inputs/`, not versioned)

File names are set in `run.R`, section "Input files".

| File | Content / requirements |
|---|---|
| Clean dataset | Sheets listed in `dataset_sheets`: `hh_clean_data`, `roster_clean_data`, `nut_ind_clean_data`, `wgss_indiv_clean_data`, `health_ind_clean_data`, `edu_ind_clean_data`, `prot_ind_clean_data`. This file has no cleaning log sheet: the changes are listed in separate journals. |
| Sampling frame | Sheet `sampling_frame_sheet`, columns `strata`, `population` and `representativity_level` (`Admin3` / `Admin2`); stratum = pcode – population group. The weights are recalculated from this file at every run: a stratum of the data that is not in the frame gets no weight. |
| Kobo analysis tool | Sheets `survey` and `choices`. The `survey` sheet also holds the analysis metadata (`theme`, `module`, `indicator`, `theme_IDD`, `analysis_var_denominator`). A variable missing from `survey` is not analysed. |
| `dictionnaire_balises_Cameroun.xlsx` | Tag dictionary (`dictionary_file_name`). In this repository it is read by step 10: rule of the new indicators (`statut_R = READY_FOR_R`). |
| `UNESCO ISCED Mappings_MSNAcountries_consolidated.xlsx` | School structure (levels, grades, official ages) used by the education indicators of 05; copy of the EduAnalysisTool resource file. |
| `exported_datasets.xlsx` | Written by 03 and read back by 04 at every run: do not edit it, do not keep it open in Excel during a run. |

## 4. Settings to check in `run.R` before a run

- `country_name`, `Admin_code`
- File names: dataset, Kobo tool, sampling frame
- `sampling_frame_sheet` and `dataset_sheets` (sheet names of the dataset)
- `population_column` (column renamed `Pol`: here `hoh_dis`)
- Weights: `weights_column` (`weight_admin2`), `weights_column_admin3` (`weight_admin3`) and `admin3_disaggregations` (levels that use the Admin 3 weight); both weights are recalculated in 02 at every run
- Analysis options: `name_or_label_headers`, `label_column`, `separator`, `values_to_NA`
- Disaggregation levels: one TRUE/FALSE flag per level; a new level must also be created as a column of
  `main_dataset` in `02_load_data.R`
- `run_bulletin` (step 09)
- `dictionary_file_name`: tag dictionary (step 10)
- `edu_isced_country` and `edu_school_year_start_month`: education indicators (05)
- `fiche_texte_na` and `fiche_seuil_n`: only used by the InDesign step (11, not included)

Output folders are dated with `Sys.Date()`: a second run on the same day overwrites the files of that day.

## Related repositories

The same harmonised pipeline is used for the other MSNA 2026 countries:

- [MSNA-MALI-2026](https://github.com/yamsbindje1/MSNA-MALI-2026)
- [MSNA-NIGER-2026](https://github.com/yamsbindje1/MSNA-NIGER-2026)
