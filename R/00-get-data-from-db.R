library(DBI)
library(RPostgres)
library(readr)
library(tidyr)
library(magrittr)

# PREREQUISITE: content from secret link (see notion infrastructure part)
# open your user Renviron file by using
#usethis::edit_r_environ()
# OR: if you want to have a local Renviron file in your project folder
#readRenviron(".Renviron")

WEBSITE_DIR <- ""
DATA_DIR <- if(Sys.getenv("DATA_DIR") != "") Sys.getenv("DATA_DIR") else "data/processed_gdpr" 

# extract environment variables
db_name <- Sys.getenv("COOLIFY_DB")
db_host <- Sys.getenv("COOLIFY_HOST")
db_port <- Sys.getenv("COOLIFY_PORT")
db_user <- Sys.getenv("COOLIFY_USER")
db_password <- Sys.getenv("COOLIFY_PASSWORD")

# create connection
con <- DBI::dbConnect(drv = RPostgres::Postgres(),
                      host = db_host,
                      port = db_port,
                      dbname = db_name,
                      user = db_user,
                      password = db_password)

DBI::dbListTables(con) # shows tables and views :) 

# tables with diversity information
diversity_items <- DBI::dbReadTable(con, "diversity_items")
diversity_groups_dict <- DBI::dbReadTable(con, "diversity_groups_dict")
diversity_groups_dict_en <- dplyr::filter(diversity_groups_dict, lang == "en")
diversity_items_labelled <- dplyr::left_join(diversity_groups_dict_en, diversity_items, by="diversity_group_id")
diversity_answers_dict <- DBI::dbReadTable(con, "diversity_answers_dict")
diversity_answers_dict_en <- dplyr::filter(diversity_answers_dict, lang == "en")

# table with responses, wide format, unlabelled
diversity_responses_wide <- DBI::dbReadTable(con, "diversity_responses_wide")
question_responses_wide <- DBI::dbReadTable(con, "question_responses_wide")
diversity_responses_wide_labelled <- DBI::dbReadTable(con, "diversity_responses_wide_labelled")
responses_wide  <- dplyr::left_join(question_responses_wide, diversity_responses_wide, by='respondent_id')

# tables with question information
question_items <- DBI::dbReadTable(con, "question_items")
question_items_dict  <- DBI::dbReadTable(con, "question_items_dict")
question_items_labelled <- dplyr::left_join(question_items, question_items_dict, by='question_item_id')
question_items_labelled_en <- dplyr::filter(question_items_labelled, lang == "en")

question_answers_dict  <- DBI::dbReadTable(con, "question_answers_dict")
question_answers_dict_en <- dplyr::filter(question_answers_dict, lang == "en")
subquestions_dict  <- DBI::dbReadTable(con, "subquestions_dict")
subquestions_dict_en <- dplyr::filter(subquestions_dict, lang == "en")
subquestions_items_labelled <- DBI::dbReadTable(con, "subquestions")

# labelled wide dataset for question responses
question_responses <- DBI::dbReadTable(con, "question_responses")
questions_answers_labelled_en <- dplyr::left_join(subquestions_dict_en, question_answers_dict_en, by = 'question_item_id')
questions_answers_labelled_en <- dplyr::select(questions_answers_labelled_en, 'subquestion_id', 'answer_id', 'answer_text')
question_responses_labelled <-  dplyr::left_join(question_responses, questions_answers_labelled_en, by = c('subquestion_id','value' = 'answer_id'))
question_responses_labelled <- dplyr::select(question_responses_labelled, 'subquestion_id', 'respondent_id', 'answer_text')
question_responses_labelled_wide <- tidyr::spread(question_responses_labelled, 'subquestion_id', 'answer_text')


# disconnect
DBI::dbDisconnect(con)

#question and diversity responses combined
responses_wide %>% readr::write_csv(here::here(WEBSITE_DIR, DATA_DIR, "responses_wide.csv"))

#write out objects  - questions
question_items_labelled_en %>% readr::write_csv(here::here(WEBSITE_DIR, DATA_DIR, "question_items_labelled.csv"))
subquestions_dict_en %>% readr::write_csv(here::here(WEBSITE_DIR, DATA_DIR, "subquestions_dict_en.csv"))
question_answers_dict_en %>% readr::write_csv(here::here(WEBSITE_DIR, DATA_DIR, "question_answers_dict_en.csv"))
subquestions_items_labelled %>% readr::write_csv(here::here(WEBSITE_DIR, DATA_DIR, "subquestions_items_labelled.csv"))


# write out objects - diversity questions and responses
diversity_items_labelled %>% readr::write_csv(here::here(WEBSITE_DIR, DATA_DIR, "diversity_items_labelled.csv"))
diversity_answers_dict_en %>% readr::write_csv(here::here(WEBSITE_DIR, DATA_DIR, "diversity_answers_dict_en.csv"))
diversity_responses_wide_labelled %>% readr::write_csv(here::here(WEBSITE_DIR, DATA_DIR, "diversity_responses_labelled_wide.csv"))

# write out objects - question responses 
question_responses_labelled_wide %>% readr::write_csv(here::here(WEBSITE_DIR, DATA_DIR, "question_responses_labelled_wide.csv"))
