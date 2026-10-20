# ============================================================================
# EDUCATION
# Nécessite : 00_transversal.R exécuté avant (fonction add_age_18_cat()).
# ============================================================================

cols <- c("edu_ind_age")
edu_ind <- convert_columns_to_numeric(edu_ind, cols)
edu_ind <- add_loop_age_dummy(
  edu_ind,
  ind_age = "edu_ind_age",
  lb = 5,
  ub = 18,
  new_colname = NULL
)

cols <- c("edu_ind_age_schooling")
edu_ind <- convert_columns_to_numeric(edu_ind, cols)
# School age: age corrected to the start of the school year, used by every step below
# (access, barriers, disruption and edu_schooling_age_n)
cols <- c("edu_ind_age")
edu_ind <- convert_columns_to_numeric(edu_ind, cols)
edu_ind <- add_loop_edu_ind_age_corrected_d_2(
  edu_ind,
  main_dataset,
  id_col_loop = "uuid",
  id_col_main = "uuid",
  survey_start_date = "today",
  school_year_start_month = 9,
  ind_age = "edu_ind_age",
  month = NULL,
  schooling_start_age = 5,
  schooling_end_age = 17
)

edu_ind <- humind::add_loop_edu_access_d(
  edu_ind,
  ind_access = "edu_access",
  yes = "yes",
  no = "no",
  pnta = "pnta",
  dnk = "dnk",
  ind_schooling_age_d = "edu_ind_age_schooling"
)

main_dataset <- humind::add_loop_edu_access_d_to_main(
  main_dataset,
  edu_ind,
  ind_access_d = "edu_ind_access_d",
  ind_no_access_d = "edu_ind_no_access_d",
  id_col_main = "uuid",
  id_col_loop = "uuid"
)


# edu_ind <- edu_ind %>%
#   dplyr::mutate(
#     edu_barrier = dplyr::case_when(
#       
#       edu_barrier == "costs" ~ "costs",
#       edu_barrier == "child_too_young" ~ "child_work_home",
#       edu_barrier == "lack_interest" ~ "child_work_outside",
#       edu_barrier == "not_priority" ~ "child_too_young",
#       edu_barrier == "lack_accessible_school" ~ "child_graduated",
#       edu_barrier == "lack_classrooms" ~ "lack_interest",
#       edu_barrier == "lack_wash_facilities" ~ "not_priority",
#       edu_barrier == "school_closed" ~ "protection_at_school",
#       edu_barrier == "lack_teacher" ~ "protection_travel_school",
#       edu_barrier == "curriculum_not_useful" ~ "child_armed_group",
#       edu_barrier == "protection_at_school" ~ "child_marriage",
#       edu_barrier == "protection_travel_school" ~ "child_pregnancy",
#       edu_barrier == "child_work_home" ~ "child_health",
#       edu_barrier == "child_work_outside" ~ "lack_accessible_school",
#       edu_barrier == "child_armed_group" ~ "curriculum_not_useful",
#       edu_barrier == "child_marriage" ~ "lack_classrooms",
#       edu_barrier == "child_pregnancy" ~ "lack_wash_facilities",
#       edu_barrier == "child_health" ~ "school_closed",
#       edu_barrier == "language" ~ "lack_teacher",
#       edu_barrier == "ban" ~ "language",
#       edu_barrier == "enroll_lack_documentation" ~ "ban",
#       edu_barrier == "enroll_displacement" ~ "enroll_lack_documentation",
#       edu_barrier == "discrimination" ~ "enroll_displacement",
#       edu_barrier == "child_graduated" ~ "discrimination",
#       
#       edu_barrier == "other" ~ "other",
#       edu_barrier == "dnk" ~ "dnk",
#       edu_barrier == "pnta" ~ "pnta",
#       
#       TRUE ~ NA_character_
#     )
#   )
# Barrières de protection à l'éducation, niveau individu puis agrégé au ménage


edu_ind <- add_loop_edu_barrier_protection_d(
  edu_ind,
    barriers = "edu_barrier",
    protection_issues = c(
      "protection_at_school",
      "protection_travel_school",
      "child_work_home",
      "child_work_outside",
      "child_armed_group",
      "child_marriage",
      "child_pregnancy",
      "ban",
      "enroll_lack_documentation",
      "discrimination"
    ),
    ind_schooling_age_d = "edu_ind_age_schooling",
    barriers_undefined = c("dnk", "pnta", "other"),
    non_protection_issues = c(
      "costs",
      "lack_interest",
      "not_priority",
      "lack_accessible_school",
      "lack_classrooms",
      "lack_wash_facilities",
      "school_closed",
      "lack_teacher",
      "curriculum_not_useful",
      "child_health",
      "language",
      "enroll_displacement",
      "child_too_young",
      "child_graduated"
    )
)


main_dataset <- add_loop_edu_barrier_protection_d_to_main(
  main_dataset,
  edu_ind,
  ind_barrier_protection_d = "edu_ind_barrier_protection_d",
  id_col_main = "uuid",
  id_col_loop = "uuid"
)

# Disruption de la scolarité (attaque / aléas / déplacement / enseignant), individu puis ménage
edu_ind <- add_loop_edu_disrupted_d(
  edu_ind,
  attack = "edu_disrupted_attack",
  hazards = "edu_disrupted_hazards",
  displaced = "edu_disrupted_displaced",
  teacher = "edu_disrupted_teacher",
  levels = c("yes", "no", "dnk", "pnta"),
  ind_schooling_age_d = "edu_ind_age_schooling"
)

main_dataset <- add_loop_edu_disrupted_d_to_main(
  main_dataset,
  edu_ind,
  attack_d = "edu_disrupted_attack_d",
  hazards_d = "edu_disrupted_hazards_d",
  displaced_d = "edu_disrupted_displaced_d",
  teacher_d = "edu_disrupted_teacher_d",
  id_col_main = "uuid",
  id_col_loop = "uuid"
)


main_dataset <- add_loop_edu_ind_schooling_age_d_to_main(
  main_dataset,
  edu_ind,
  ind_schooling_age_d = "edu_ind_age_schooling",
  id_col_main = "uuid",
  id_col_loop = "uuid"
)

# Catégorie d'âge (>18 / <18) sur la boucle éducation
edu_ind <- add_age_18_cat(
  edu_ind,
  age_col = "edu_ind_age",
  int_undefined = c(-999, 999),
  char_undefined = "undefined",
  new_colname = "ind_age_18_cat"
)
