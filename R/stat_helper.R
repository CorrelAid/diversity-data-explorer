library(rstatix)
library(maditr)

compute_chisq <- function(data, ...) {
  
  data %>%
    count(..., answer_label) %>%
    dcast(answer_label ~ ..., value.var = "n", fill = 0) %>%
    remove_rownames %>% column_to_rownames(var="answer_label") %>% 
    chisq_test()
  
}

compute_cramer_v <- function(data, ...) {
  
  data %>%
    count(..., answer_label) %>%
    dcast(answer_label ~ ..., value.var = "n", fill = 0) %>%
    remove_rownames %>% column_to_rownames(var="answer_label") %>% 
    cramer_v()
  
}

compute_chisq_by_group <- function(group_name) {
  print(group_name)
  var <- ensym(group_name)
  
  ques_div_longer_nest_lab_df %>%
    mutate(
      chisq_stat = map(data, ~compute_chisq(.x, {{var}})),
      cramer_v   = map(data, ~compute_cramer_v(.x, {{var}}))
    ) %>%
    unnest(c(chisq_stat, cramer_v))
  
  
}

count_no_var <- function(data) {
  
  data %>% 
    dplyr::select(c(answer_label, starts_with("div_"))) %>%
    select_if(function(.) n_distinct(.) == 1) %>% 
    names() %>%
    length()
  
} 

count_answer_options <- function(data) {
  

  data %>% select(answer_label) %>% n_distinct()
}

verify_factor <- function(data) {
  
  is.factor(data$answer_label)
  
}

compute_clm <- function(data) {
  
  data <- data %>% dplyr::select(c(answer_label, starts_with("div_"))) %>%
    filter(!is.na(answer_label))
  
  m <- clm(formula = answer_label ~ 0 + ., data = data,
            link = "loglog",
            Hess = TRUE)
  
  tidy(m)
}
