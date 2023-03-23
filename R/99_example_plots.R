chisq_df <- read_rds(here::here("data", "processed", "question_chisq_df.rds"))

log_reg_df <- read_rds(here::here("data", "processed", "question_log_reg_df.rds"))

pol_reg_df <- read_rds(here::here("data", "processed", "question_pol_reg_df.rds"))

chisq_df %>%
  filter(subquestion_id == "q1_SQ001") %>%
  arrange(cramer_v) %>%    # First sort by val. This sort the dataframe but NOT the factor levels
  mutate(diversity_group = factor(diversity_group,
                                  levels = diversity_group)) %>% # This trick update the factor levels
ggplot(aes(x = diversity_group, y = cramer_v)) +
  geom_segment(aes(xend = diversity_group, yend = 0)) +
  geom_point(size = 4, color = "orange") +
  coord_flip() +
  labs(title = "Which variable has the highest effect on the response?",
         subtitle = "When you think of voluntary work in Germany:\nHave you been involved in voluntary work in local associations/initiatives/projects/self-help groups in the last 12 months?") +
  theme_bw() +
  xlab("") +
  ylab("Cramer V")


log_reg_df %>%
  filter(subquestion_id == "q1_SQ001") %>%
  filter(term != "(Intercept)") %>%
  filter(!is.na(estimate)) %>% 
  arrange(abs(estimate)) %>%
  mutate(term = factor(term,
                       levels = term)) %>% # This trick update the factor levels
  ggplot(aes(x = term, y = estimate)) +
  geom_segment(aes(xend = term, yend = 0)) +
  geom_point(size = 4, color = "orange") +
  coord_flip() +
  labs(title = "Which variable has the highest effect on the response?",
       subtitle = "When you think of voluntary work in Germany:\nHave you been involved in voluntary work in local associations/initiatives/projects/self-help groups in the last 12 months?") +
  theme_bw() +
  xlab("") +
  ylab("Log Odds")

pol_reg_df %>%
  filter(subquestion_id == "q5_SQ001") %>%
  arrange(abs(estimate)) %>%
  mutate(term = factor(term,
                       levels = term)) %>% # This trick update the factor levels
  ggplot(aes(x = term, y = estimate)) +
  geom_segment(aes(xend = term, yend = 0)) +
  geom_point(size = 4, color = "orange") +
  coord_flip() +
  labs(title = "Which variable has the highest effect on the response?",
       subtitle = "Regardless of your own experiences of discrimination:\nIn your opinion, how often does discrimination generally take place in the following areas of life in Germany? - Education") +
  theme_bw() +
  xlab("") +
  ylab("Log Odds")


  
  