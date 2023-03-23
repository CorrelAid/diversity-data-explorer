library(tidyverse)
library(here)
library(haven)
library(MASS)
library(ordinal)

source(here::here("R", "stat_helper.R"))


# Decide wether to keep NAs and replace them with random values
keep_NA <- TRUE
DATA_DIR <- if(Sys.getenv("DATA_DIR") != "") Sys.getenv("DATA_DIR") else "data/processed_gdpr" 

subquestions_items_labelled <- read_csv(here::here(DATA_DIR, "subquestions_dict_en.csv"))
diversity_responses_labelled_wide <- read_csv(here::here(DATA_DIR, "diversity_responses_labelled_wide.csv"))
question_responses_labelled_wide <- read_csv(here::here(DATA_DIR, "question_responses_labelled_wide.csv")) %>% select(-q15_SQ001)
diversity_factor_levels <- readr::read_csv(here::here("data/helper/diversity_factor_levels.csv"))

# one row per variable, nest levels
diversity_factor_levels <- diversity_factor_levels %>% 
  group_by(var) %>% 
  summarize(levels = list(levels),
            ordered = unique(ordered))

print("---- data wrangling and recoding ----")
# replace NAs with random values of the respective column and create identifier prefix for all diversity variables
if (keep_NA) {
  
  question_responses_labelled_wide <- question_responses_labelled_wide  %>% 
    mutate_at(vars(-respondent_id), factor) %>% as.data.frame()
  
  cat_vars <- question_responses_labelled_wide %>% dplyr::select(where(is.factor))
  nas <- sapply(cat_vars, function(x) sum(is.na(x)))
  
  for (i in names(nas)[(nas > 0 & nas < 4020)]) {
    replacement <- sample(levels(question_responses_labelled_wide[, i]), 1)
    question_responses_labelled_wide[,i] <- tidyr::replace_na(question_responses_labelled_wide[, i], replacement)
  }
  
  
  diversity_responses_labelled_wide <- diversity_responses_labelled_wide %>% 
    mutate_at(vars(-respondent_id), factor) %>% as.data.frame()
  
  cat_vars <- diversity_responses_labelled_wide %>% dplyr::select(where(is.factor))
  nas <- sapply(cat_vars, function(x) sum(is.na(x)))
  
  for (i in names(nas)[nas > 0]) {
    replacement <- sample(levels(diversity_responses_labelled_wide[,i]), 1)
    diversity_responses_labelled_wide[,i] <- tidyr::replace_na(diversity_responses_labelled_wide[,i], replacement)
  }
  
  
}


# convert each and every column of diversity group data to a factor, ordered if possible
recode_to_factor <- function(data, var, levels, ordered = TRUE) {
  data %>% 
    mutate("{var}" := factor(.data[[var]], levels = levels, ordered = ordered))
}

# this could probably also be dplyr and more elegant but no time
for (i in 1:nrow(diversity_factor_levels)) {
  diversity_responses_labelled_wide <- diversity_responses_labelled_wide %>% 
    recode_to_factor(diversity_factor_levels$var[i], 
                     diversity_factor_levels$levels[i][[1]],
                     diversity_factor_levels$ordered[i])
}

diversity_responses_labelled_wide <- diversity_responses_labelled_wide %>% 
  rename_at(vars(-respondent_id), ~paste0("div_", .))

# Removes all NAs - Warning: this will reduce the amount of data drastically
if (keep_NA == FALSE) {
  diversity_responses_labelled_wide <- diversity_responses_labelled_wide %>%
    tidyr::drop_na()
}


# join diversity group on questionnaire answers
ques_div_df <- diversity_responses_labelled_wide %>%
  left_join(question_responses_labelled_wide,
            by = "respondent_id")


# pivot our dataset in a longer data format - we now have rows for each 
# sub-question_item-respondent combination
ques_div_longer_df <-
  ques_div_df %>%
  pivot_longer(
    cols = starts_with("q"),
    names_to = "subquestion_id",
    values_to = "answer_label",
    values_drop_na = TRUE
  )

# filter for English info only, replace NAs with no answer
subquestions_info_df <- subquestions_items_labelled %>%
  filter(lang == "en") %>%
  replace(is.na(.), "No Answer")

# join further information about subquestions and nest according to their id
ques_div_longer_nest_lab_df <- 
  ques_div_longer_df %>%
  replace(is.na(.), "No Answer") %>%
  group_by(subquestion_id) %>%
  nest() %>%
  left_join(
    subquestions_info_df,
    by = "subquestion_id"
  ) %>%
  unnest(cols = c(data)) %>%
  ungroup() %>%
  dplyr::select(-c(lang)) %>%
  nest(data = -c(subquestion_id,
                 question_item_id,
                 label_major,
                 subquestion_id_minor
                 ))


######################## Recoding all answers as factors #######################

# code answer options as factors and order if appropriate. In a first step answers
# are removed which are not ideal for ordering. We could keep them as well, but would
# suffer a loss of information then. 
ques_div_longer_nest_fact_df <- ques_div_longer_nest_lab_df %>%
  mutate(data = map(data, ~ filter(., !answer_label %in% c("No Answer",
                                                           "I do not know",
                                                           "Don‘t know",
                                                           "I cannot judge the organisation/institution",
                                                           "Do not know / no assessment",
                                                           "I don't know.")))) %>%
  mutate(labels = data %>% map(~ {
    unique(.x$answer_label) %>%
    sort() %>%
    paste(collapse = ", ")})) %>%
  mutate(data = case_when(
    
    str_detect(labels, "No, Yes") ~ map(data, function(x) {
    mutate(x, answer_label = factor(answer_label,
                                    levels = c("No", "Yes"),
                                    ordered = TRUE))
  }),
  
  str_detect(labels, "Largely, Partly, Rather not") ~ map(data, function(x) {
    mutate(x, answer_label = factor(answer_label,
                                    levels = c("Rather not", "Partly", "Largely"),
                                    ordered = TRUE))
  }),
  
  str_detect(labels, "Yes, Not Selected") ~ map(data, function(x) {
    mutate(x, answer_label = factor(answer_label,
                                    levels = c("Not Selected", "Yes"),
                                    ordered = TRUE))
  }),
  
  str_detect(labels, "Rather minor problem") ~ map(data, function(x) {
    mutate(x, answer_label = factor(answer_label,
                                    levels = c("Rather minor problem",
                                               "Medium-sized problem",
                                               "Rather serious problem"),
                                    ordered = TRUE))
  }),
  
  str_detect(labels, "Rather yes, Undecided") ~ map(data, function(x) {
    mutate(x, answer_label = factor(answer_label,
                                    levels = c(
                                               "Undecided",
                                               "Rather yes"),
                                    ordered = TRUE))
  }),
  
  str_detect(labels, "Rather not, Rather yes, Undecided") ~ map(data, function(x) {
    mutate(x, answer_label = factor(answer_label,
                                    levels = c(
                                      "Undecided",
                                      "Rather yes"),
                                    ordered = TRUE))
  }),
  
  str_detect(labels, "Neutral / I have no opinion on this") ~ map(data, function(x) {
    mutate(x, answer_label = factor(answer_label,
                                    levels = c("I do not agree",
                                               "Neutral / I have no opinion on this",
                                               "I agree"),
                                    ordered = TRUE))
  }),
  
  str_detect(labels, "Baden-Wuerttemberg") ~ map(data, function(x) {
    mutate(x, answer_label = factor(answer_label,
                                    levels = c("Baden-Wuerttemberg",
                                               "Bayern",
                                               "Berlin",
                                               "Brandenburg",
                                               "Bremen",
                                               "Hamburg",
                                               "Hessen",
                                               "Lower Saxony",
                                               "Mecklenburg-West Pomerania"),
                                    ordered = FALSE))
  }),
  
  str_detect(labels, "Divorced / registered partnership dissolved") ~ map(data, function(x) {
    mutate(x, answer_label = factor(answer_label,
                                    levels = c("Divorced / registered partnership dissolved",
                                               "Married, living together",
                                               "Married, separated",
                                               "Registered partnership, living apart",
                                               "Registered partnership, living together",
                                               "Single",
                                               "widow / partner deceased"),
                                    ordered = FALSE))
  }),
  
  str_detect(labels, "No, it has no impact") ~ map(data, function(x) {
    mutate(x, answer_label = factor(answer_label,
                                    levels = c("Yes, it has a negative impact on career opportunities",
                                               "No, it has no impact",
                                               "Yes, it has a positive impact on career opportunities"),
                                    ordered = TRUE))
  }),
  
  str_detect(labels, "I am (currently) homeless.") ~ map(data, function(x) {
    mutate(x, answer_label = factor(answer_label,
                                    levels = c("I am (currently) homeless.",
                                               "I am renting",
                                               "I live in assisted living / senior home etc.",
                                               "I own the flat/house I live in"),
                                    ordered = FALSE))
  }),
  
  str_detect(labels, "No degree/qualification obtained abroad") ~ map(data, function(x) {
    mutate(x, answer_label = factor(answer_label,
                                    levels = c("No",
                                               "No degree/qualification obtained abroad",
                                               "Partly",
                                               "Yes"),
                                    ordered = TRUE))
  }),
  
  str_detect(labels, "No, my current activity is above my professional qualification.") ~ map(data, function(x) {
    mutate(x, answer_label = factor(answer_label,
                                    levels = c("No, my current activity is above my professional qualification.",
                                               "Yes",
                                               "No, my current occupation is below my professional qualification."
                                               ),
                                    ordered = TRUE))
  }),
  
  str_detect(labels, "fixed-term/limited contract") ~ map(data, function(x) {
    mutate(x, answer_label = factor(answer_label,
                                    levels = c("fixed-term/limited contract",
                                               "permanent contract"
                                    ),
                                    ordered = TRUE))
  }),
  
  str_detect(labels, "No, I already have one/several") ~ map(data, function(x) {
    mutate(x, answer_label = factor(answer_label,
                                    levels = c("No",
                                               "No, I already have one/several, and that is:",
                                               "Yes, the following:"
                                    ),
                                    ordered = FALSE))
  }),
  
  str_detect(labels, "11-15") ~ map(data, function(x) {
    mutate(x, answer_label = factor(answer_label,
                                    levels = c("1",
                                               "2",
                                               "3",
                                               "4",
                                               "5",
                                               "6 - 10",
                                               "11 - 15",
                                               "16 - 20",
                                               "21 and more"
                                    ),
                                    ordered = TRUE))
  }),
  
  str_detect(labels, "At least once a month") ~ map(data, function(x) {
    mutate(x, answer_label = factor(answer_label,
                                    levels = c("At least once a month",
                                               "At least quarterly",
                                               "At least once every six months",
                                               "At least once a year",
                                               "Less than once a year"
                                    ),
                                    ordered = TRUE))
  }),
  
  str_detect(labels, "Rather satisfied") ~ map(data, function(x) {
    mutate(x, answer_label = factor(answer_label,
                                    levels = c("Very dissatisfied",
                                               "Rather dissatisfied",
                                               "Rather satisfied",
                                               "Very satisfied"
                                    ),
                                    ordered = TRUE))
  }),
  
  str_detect(labels, "Sometimes") ~ map(data, function(x) {
    mutate(x, answer_label = factor(answer_label,
                                    levels = c("Never",
                                               "Rarely",
                                               "Sometimes",
                                               "Often",
                                               "Very often"
                                    ),
                                    ordered = TRUE))
  }),
  
  str_detect(labels, "High") ~ map(data, function(x) {
    mutate(x, answer_label = factor(answer_label,
                                    levels = c("Low",
                                               "Medium",
                                               "High"
                                    ),
                                    ordered = TRUE))
  }),
  
  str_detect(labels, "Quite common") ~ map(data, function(x) {
    mutate(x, answer_label = factor(answer_label,
                                    levels = c("Does not exist",
                                               "Very rare",
                                               "Rather rare",
                                               "Quite common",
                                               "Very common"
                                    ),
                                    ordered = TRUE))
  }),
  
  str_detect(labels, "Stayed the same") ~ map(data, function(x) {
    mutate(x, answer_label = factor(answer_label,
                                    levels = c("Strongly decreased",
                                               "Decreased",
                                               "Stayed the same",
                                               "Increased",
                                               "Strongly increased"
                                    ),
                                    ordered = TRUE))
  }),
  
  str_detect(labels, "Rather agree") ~ map(data, function(x) {
    mutate(x, answer_label = factor(answer_label,
                                    levels = c("Do not agree at all",
                                               "Rather do not agree",
                                               "Undecided",
                                               "Rather agree",
                                               "Fully agree"
                                    ),
                                    ordered = TRUE))
  }),
  
  str_detect(labels, "will lead to political changes that will affect my life negatively.") ~ map(data, function(x) {
    mutate(x, answer_label = factor(answer_label,
                                    levels = c("will lead to political changes that will affect my life negatively.",
                                               "will not lead to political changes that will affect my life.",
                                               "will lead to political changes that will positively impact my life."
                                    ),
                                    ordered = TRUE))
  }),
  
  str_detect(labels, "Average") ~ map(data, function(x) {
    mutate(x, answer_label = factor(answer_label,
                                    levels = c("Low",
                                               "Average",
                                               "Good"
                                    ),
                                    ordered = TRUE))
  }),
  
           TRUE ~ data)
  )


# map over each diversity group, filter 
# for categorical variables and compute chisq test ----
print("---- for categorical variables and compute chisq test. This might take a while... ----")
question_chisq_df <- grep("^div_",
                          names(ques_div_longer_df),
                          value = TRUE) %>%
  purrr::set_names() %>%
  map_dfr(compute_chisq_by_group, .id = "diversity_group") %>%
  select(-c(data))

# save statistics data frame
question_chisq_df %>%
  write_rds(file = here::here(DATA_DIR, "question_chisq_df.rds"))

# compute logistic regression for each binary question
print("---- compute logistic regression for each binary question ----")

question_log_reg_df <- ques_div_longer_nest_fact_df %>%
  mutate(no_var         = map(data, ~ count_no_var(.x)),
         n_answer_label = map(data, ~ count_answer_options(.x))) %>%
  unnest(col = c(no_var, n_answer_label)) %>%
  filter(n_answer_label == 2 & no_var == 0) %>%
  mutate(
    reg_data = map(data, ~ .x %>%
        dplyr::select(answer_label,
               starts_with("div")) %>%
                                       glm(answer_label ~ .,
                                           data = .,
                                           family = "binomial") %>%
                                      tidy())) %>%
  unnest(col = reg_data) %>%
  filter(!is.na(estimate)) %>%
  filter(term != "(Intercept)") %>%
  select(-data)


question_log_reg_df %>%
  write_rds(file = here::here(DATA_DIR, "question_log_reg_df.rds"))

question_polr_reg_df <- ques_div_longer_nest_fact_df %>%
  mutate(no_var = map(data, ~ count_no_var(.x)),
         n_answer_label = map(data, ~ count_answer_options(.x)),
         n_per_ques = map(data, nrow),
         is_fac = map(data, verify_factor)) %>%
  unnest(col = c(no_var, n_answer_label, n_per_ques, is_fac)) %>% 
  filter(n_answer_label > 2 & no_var == 0 & is_fac == TRUE) %>% 
  mutate(
    reg_data  = map(data, ~ compute_clm(.x))) %>%
  unnest(col  = reg_data) %>%
  filter(coef.type != "intercept") %>%
  filter(!is.na(estimate)) %>%
  select(-data)

question_polr_reg_df %>%
  write_rds(file = here::here(DATA_DIR, "question_pol_reg_df.rds"))





  

  






  
  



