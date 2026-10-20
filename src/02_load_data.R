# 02 - Load data
# Kobo tool, sampling frame, datasets, disaggregation columns and the two weights.

## ---- Output folders ------------------------------------------------------------

for (category in c("Tables frequences", "InDiSign", "Dataset used and dictionnaire_indi")) {
  dir.create(file.path(output_root, category, run_date), recursive = TRUE, showWarnings = FALSE)
}

out_path <- function(category, filename) file.path(output_root, category, run_date, filename)

## ---- Kobo tool ---------------------------------------------------------------

tool.survey <- readxl::read_excel(kobo_tool, sheet = "survey")
tool.choices <- readxl::read_excel(kobo_tool, sheet = "choices") %>% dplyr::select(list_name, name, label)

## ---- Sampling frame -----------------------------------------------------------

sampling_frame_raw <- readxl::read_excel(sampling_frame_file, sheet = sampling_frame_sheet)

# Strata representative at Admin 3
sampling_frame_admin3 <- sampling_frame_raw %>%
  dplyr::filter(representativity_level == "Admin3", !is.na(strata), !is.na(population), population > 0) %>%
  dplyr::select(strata, population) %>%
  dplyr::distinct()

# Strata representative at Admin 2
sampling_frame_admin2 <- sampling_frame_raw %>%
  dplyr::filter(representativity_level == "Admin2", !is.na(strata), !is.na(population), population > 0) %>%
  dplyr::select(strata, population) %>%
  dplyr::distinct()

## ---- Household dataset -----------------------------------------------------------
# Every disaggregation level listed in run.R must be a column built here.

main_dataset <- readxl::read_xlsx(path = file_name_dataset, sheet = dataset_sheets[["household"]]) %>%
  dplyr::rename(
    Admin_1 = admin1, Admin_1_nom = admin1_name,
    Admin_2 = admin2, Admin_2_nom = admin2_name,
    Admin_3 = admin3, Admin_3_nom = admin3_name,
    Admin_4 = admin4,
    Pol = dplyr::all_of(population_column)
  )

main_dataset <- main_dataset %>%
  dplyr::mutate(
    country = country_name,

    # Disaggregation levels (names x population group)
    admin1_pop = paste(Admin_1, Pol, sep = "_"),
    admin2_pop = paste(Admin_2, Pol, sep = "_"),
    admin3_pop = paste(Admin_3, Pol, sep = "_"),
    country_pop = paste(country, Pol, sep = "_"),

    # Weighting strata (pcode x population group)
    strate_admin3 = paste(Admin_3, Pol, sep = "-"),
    strate_admin2 = paste(Admin_2, Pol, sep = "-")
  )

## ---- Weights ----
# two weights; main_dataset is never filtered (NA weight where it cannot be estimated)

df_weight_admin3 <- main_dataset %>%
  dplyr::filter(
    strate_admin3 %in% sampling_frame_admin3$strata
  ) %>%
  analysistools::add_weights(
    sampling_frame_admin3,
    strata_column_dataset = "strate_admin3",
    strata_column_sample = "strata",
    population_column = "population"
  ) %>%
  dplyr::select(
    uuid,
    weights
  ) %>%
  dplyr::rename(
    weight_admin3 = weights
  )

df_weight_admin2 <- main_dataset %>%
  dplyr::filter(
    strate_admin2 %in% sampling_frame_admin2$strata
  ) %>%
  analysistools::add_weights(
    sampling_frame_admin2,
    strata_column_dataset = "strate_admin2",
    strata_column_sample = "strata",
    population_column = "population"
  ) %>%
  dplyr::select(
    uuid,
    weights
  ) %>%
  dplyr::rename(
    weight_admin2 = weights
  )

main_dataset <- main_dataset %>%
  dplyr::left_join(
    df_weight_admin3,
    by = "uuid"
  ) %>%
  dplyr::left_join(
    df_weight_admin2,
    by = "uuid"
  )

main_dataset <- main_dataset %>%
  dplyr::mutate(
    representativity_level = dplyr::case_when(
      !is.na(weight_admin3) & !is.na(weight_admin2) ~ "Admin2 + Admin1 + Admin0",
      is.na(weight_admin3) & !is.na(weight_admin2) ~ "Admin3 only",
      TRUE ~ "Not estimable"
    )
  )

## ---- Weight checks (printed to the console) --------------------------------------

main_dataset %>% dplyr::count(representativity_level, is.na(weight_admin3), is.na(weight_admin2))
main_dataset %>% dplyr::filter(is.na(weight_admin2)) %>% dplyr::count(strate_admin2, sort = TRUE)
main_dataset %>% dplyr::filter(is.na(weight_admin3)) %>% dplyr::count(strate_admin3, sort = TRUE)

## ---- Household variables joined to the individual datasets ------------------------

hh_variables <- main_dataset %>%
  dplyr::select(
    uuid, Pol,
    Admin_1, Admin_1_nom,
    Admin_2, Admin_2_nom,
    Admin_3, Admin_3_nom,
    Admin_4,
    country,
    chef_team,
    admin1_pop, admin2_pop, admin3_pop, country_pop,
    strate_admin2, strate_admin3,
    representativity_level,
    weight_admin2, weight_admin3
  )

## ---- Individual datasets -------------------------------------------------------

roster <- readxl::read_xlsx(file_name_dataset, sheet = dataset_sheets[["roster"]]) %>%
  dplyr::mutate(uuid_personne = person_id) %>%
  dplyr::left_join(hh_variables, by = "uuid") %>%
  dplyr::filter(!is.na(country))

nut_ind <- readxl::read_xlsx(file_name_dataset, sheet = dataset_sheets[["nut"]]) %>%
  dplyr::mutate(uuid_personne = nut_person_id) %>%
  dplyr::left_join(hh_variables, by = "uuid") %>%
  dplyr::filter(!is.na(country))

wgss_indiv <- readxl::read_xlsx(file_name_dataset, sheet = dataset_sheets[["wgss"]]) %>%
  dplyr::mutate(uuid_personne = wgss_person_id) %>%
  dplyr::left_join(hh_variables, by = "uuid") %>%
  dplyr::filter(!is.na(country))

health_ind <- readxl::read_xlsx(file_name_dataset, sheet = dataset_sheets[["health"]]) %>%
  dplyr::mutate(uuid_personne = health_person_id) %>%
  dplyr::left_join(hh_variables, by = "uuid") %>%
  dplyr::filter(!is.na(country))

edu_ind <- readxl::read_xlsx(file_name_dataset, sheet = dataset_sheets[["edu"]]) %>%
  dplyr::mutate(uuid_personne = edu_person_id) %>%
  dplyr::left_join(hh_variables, by = "uuid") %>%
  dplyr::filter(!is.na(country))

prot_ind <- readxl::read_xlsx(file_name_dataset, sheet = dataset_sheets[["prot"]]) %>%
  dplyr::mutate(uuid_personne = prot_person_id) %>%
  dplyr::left_join(hh_variables, by = "uuid") %>%
  dplyr::filter(!is.na(country))

## ---- Column name helper ------------------------------------------------------------

clean_column_names <- function(df) {
  names(df) <- gsub("/", ".", names(df))
  df
}



modalites <- c(
  "own_production", "purchase_cash", "purchase_credit",
  "hunting", "gathering", "exchange", "borrow", "gift",
  "begging", "assistance_in_kind", "assistance_cva",
  "other", "dnk", "pnta"
)

reponses <- trimws(as.character(main_dataset$fsl_source_food_ranked))
choix <- strsplit(reponses, "\\s+")

for (modalite in modalites) {
  main_dataset[[paste0("fsl_source_food_ranked.", modalite)]] <-
    ifelse(
      is.na(reponses) | reponses == "",
      NA_integer_,
      as.integer(vapply(
        choix,
        function(x) modalite %in% x,
        logical(1)
      ))
    )
}

main_dataset <- main_dataset |>
  dplyr::relocate(
    dplyr::all_of(paste0("fsl_source_food_ranked.", modalites)),
    .after = fsl_source_food_ranked
  )

