# 06 - Frequency tables (Excel) from tot_results


admin1_nom_pcode <- main_dataset %>% distinct(Admin_1_nom, Admin_1) %>% filter(!is.na(Admin_1_nom))
admin2_nom_pcode <- main_dataset %>% distinct(Admin_2_nom, Admin_2) %>% filter(!is.na(Admin_2_nom))
admin1_pop_pcode <- main_dataset %>% distinct(admin1_pop, Admin_1) %>% filter(!is.na(admin1_pop))
admin2_pop_pcode <- main_dataset %>% distinct(admin2_pop, Admin_2) %>% filter(!is.na(admin2_pop))

group_pcode <- function(group_var, group_var_value) {
  pcode <- rep(NA_character_, length(group_var))
  pcode[group_var == "Admin_1_nom"] <- admin1_nom_pcode$Admin_1[match(group_var_value[group_var == "Admin_1_nom"], admin1_nom_pcode$Admin_1_nom)]
  pcode[group_var == "Admin_2_nom"] <- admin2_nom_pcode$Admin_2[match(group_var_value[group_var == "Admin_2_nom"], admin2_nom_pcode$Admin_2_nom)]
  pcode[group_var == "admin1_pop"]  <- admin1_pop_pcode$Admin_1[match(group_var_value[group_var == "admin1_pop"], admin1_pop_pcode$admin1_pop)]
  pcode[group_var == "admin2_pop"]  <- admin2_pop_pcode$Admin_2[match(group_var_value[group_var == "admin2_pop"], admin2_pop_pcode$admin2_pop)]
  pcode[group_var == "admin3_pop"]  <- admin2_pop_pcode$Admin_2[match(group_var_value[group_var == "admin3_pop"], admin2_pop_pcode$admin2_pop)]
  pcode
}

## ---- theme_IDD -------------------------------------------------------------
# Same fallback as 07_indesign_exports.R: use theme_IDD_kobo_legacy if theme_IDD is missing.
ensure_theme_idd <- function(df, label) {
  if (!"theme_IDD" %in% names(df)) {
    if ("theme_IDD_kobo_legacy" %in% names(df)) {
      message(
        "06_frequency_tables.R: column 'theme_IDD' missing from ", label, " - ",
        "using 'theme_IDD_kobo_legacy' instead for the by-theme export."
      )
      df <- df %>% mutate(theme_IDD = theme_IDD_kobo_legacy)
    } else {
      stop(
        "06_frequency_tables.R: neither 'theme_IDD' nor 'theme_IDD_kobo_legacy' ",
        "in ", label, " - the by-theme export cannot be built. ",
        "Check indicator_metadata / the join in 05_analyses.R."
      )
    }
  }
  df
}

presentresults_table <- tot_results %>%
  mutate(
    analysis_type      = analysis_type,
    analysis_var        = analysis_var,
    analysis_var_value  = analysis_var_value,
    group_var            = group_var,
    group_var_value       = group_var_value,
    stat                  = suppressWarnings(as.numeric(stat)),
    n_unweighted          = suppressWarnings(as.numeric(n)),
    n_total_unweighted    = suppressWarnings(as.numeric(N))
  ) %>% mutate(
    group_var_value_pcode = group_pcode(group_var, group_var_value),
    group_var_value_disambig = ifelse(
      is.na(group_var_value_pcode),
      group_var_value,
      paste0(group_var_value, "_", group_var_value_pcode)
    ),
    analysis_key = ifelse(
      is.na(group_var) | group_var %in% c("none", "", NA),
      paste0(analysis_type, " @/@ ", analysis_var, " %/% ", analysis_var_value, " @/@ ", group_var, " %/% ", group_var_value),
      paste0(analysis_type, " @/@ ", analysis_var, " %/% ", analysis_var_value, " @/@ ", group_var, " %/% ", group_var_value,
             " -/- ", group_var, " %/% ", group_var_value_disambig)
    )
  ) %>%
  select(-group_var_value_pcode, -group_var_value_disambig)

presentresults_table <- ensure_theme_idd(presentresults_table, "presentresults_table")

presentresults_export_columns <- c(
  "group_var", "country", "Admin_1_nom", "Admin_2_nom","Admin_3_nom", "country_pop", "admin1_pop", "admin2_pop", "admin3_pop",
  "theme", "module", "indicator", "analysis_type", "question.label", "before_dot",
  "analysis_var", "analysis_var_value", "choice.label", "stat", "n", "N",
  "stat_upp", "stat_low", "MoE", "n_weighted", "n_w_total", "estimator",
  "weighted", "theme_IDD", "analysis_key"
)

presentresults_table_export <- presentresults_table %>%
  spread_group_var(groups = c(country = "country", Admin_1_nom = "Admin_1_nom", Admin_2_nom = "Admin_2_nom", Admin_3_nom = "Admin_3_nom",country_pop = "country_pop", admin1_pop = "admin1_pop", admin2_pop = "admin2_pop",admin3_pop = "admin3_pop")) %>%
  select(all_of(presentresults_export_columns))

writexl::write_xlsx(tot_results, out_path("Tables frequences", paste0("tot_results_", run_date, ".xlsx")))

## ---- Final "variable x group" table, by theme ------------------------------

# NA stays NA (nobody answered); options never chosen are already 0
my_results_table <- presentresults_table

# create_table_variable_x_group() pivots on analysis_key - check it's unique first
dup_keys <- my_results_table %>%
  dplyr::count(analysis_key, name = "n_occurrences") %>%
  dplyr::filter(n_occurrences > 1)

if (nrow(dup_keys) > 0) {
  dup_detail <- my_results_table %>%
    dplyr::filter(analysis_key %in% dup_keys$analysis_key) %>%
    dplyr::distinct(analysis_key, analysis_var) %>%
    dplyr::arrange(analysis_key)

  warning(
    nrow(dup_keys), " duplicate analysis_key(s) in my_results_table (",
    sum(dup_keys$n_occurrences), " rows affected). Usually means the same ",
    "variable exists in several datasets (household + loop) analysed at the ",
    "same disaggregation level. Preview: ",
    paste(utils::head(dup_keys$analysis_key, 5), collapse = " | ")
  )
  print(utils::head(dup_detail, 20))

  my_results_table <- my_results_table %>% dplyr::distinct(analysis_key, .keep_all = TRUE)
}

table_variable_x_group <- my_results_table %>%
  create_table_variable_x_group(analysis_key = "analysis_key", value_columns = "stat") %>%
  # drop the "0" modality, but only for select_multiple questions
  filter(!(analysis_type == "select_multiple" & analysis_var_value == "0")) %>%
  rename_with(~ sub("^.*%/% ", "", .x), .cols = matches("%/%")) %>%
  # split variable and modality apart for select_multiple questions
  mutate(
    analysis_var_value = if_else(analysis_type == "select_multiple", sub("^[^.]*\\.", "", analysis_var), analysis_var_value),
    analysis_var        = if_else(analysis_type == "select_multiple", sub("\\..*", "", analysis_var), analysis_var)
  ) %>%
  left_join(indicator_metadata, by = c("analysis_var" = "name")) %>%
  relocate(theme, indicator, .after = analysis_type)

table_variable_x_group <- ensure_theme_idd(table_variable_x_group, "table_variable_x_group")

# Percentages only for proportions; means keep their unit; NA -> "N/A".
format_stat <- function(x, is_pct) {
  dplyr::case_when(
    is.na(x) ~ "N/A",
    is_pct ~ paste0(formatC(x * 100, format = "f", digits = 1), "%"),
    TRUE ~ formatC(x, format = "f", digits = 2)
  )
}

is_pct_row <- table_variable_x_group$analysis_type %in% c("select_one", "select_multiple", "ratio")
stat_columns <- names(dplyr::select(table_variable_x_group, where(is.numeric)))
table_variable_x_group <- table_variable_x_group %>%
  dplyr::mutate(dplyr::across(dplyr::all_of(stat_columns), ~ format_stat(.x, is_pct_row)))

table_variable_x_group %>%
  create_xlsx_variable_x_group_by_theme(
    file_path = out_path("Tables frequences", paste0("tableau_thematique_", run_date, ".xlsx")),
    theme_column = "theme_IDD",
    value_columns = "stat",
    overwrite = TRUE
  )

table_variable_x_group %>%
  create_xlsx_variable_x_group_all(
    file_path = out_path("Tables frequences", paste0("tableau_All_freq_", run_date, ".xlsx")),
    value_columns = "stat",
    overwrite = TRUE
  )

