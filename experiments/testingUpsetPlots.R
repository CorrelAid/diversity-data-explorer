upset(as.data.frame(data_of_mc_question), nsets = 5, number.angles = 30, point.size = 2, line.size = 1, 
      mainbar.y.label = "Sublabel Intersections", sets.x.label = "Answers per Sublabel")
library(grid)
grid.text(questionLabel,x = 0.65, y=0.95, gp=gpar(fontsize=12))
MCTestquestion = "q1x1"
questionLabel <- questions %>% filter(question_item_id==MCTestquestion) %>% pull(label_major)
subquestionIds<- subquestions 	%>% filter(question_item_id==MCTestquestion) %>% pull(subquestion_id)
subquestionLabel<- subquestions 	%>% filter(question_item_id==MCTestquestion) %>% pull(label_major)

data_of_mc_question <- question_answers %>%  select(c(subquestionIds)) %>% rename_at(vars(subquestionIds), function(x) subquestionLabel)  %>% 
  mutate_all(funs(ifelse(is.na(.), 0, .))) %>% mutate(question_name=questionLabel, .before = 1)
names

library(UpSetR)
upset(as.data.frame(data_of_mc_question), nsets = 5, number.angles = 30, point.size = 2, line.size = 1, 
      mainbar.y.label = "Sublabel Intersections", sets.x.label = "Answers per Sublabel")
library(gridtext)

data_of_mc_question