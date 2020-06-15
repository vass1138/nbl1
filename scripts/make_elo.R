#
# Generate ELO scores from season game data.
# Use one round as test data (parameter to elo_model() function).
# All other data used for training.
#

if (!exists("games")) {
  source("parse_json.R")
}

library(elo)

map_margin_to_outcome <- function(margin, marg.min = -49, marg.max = 49){
  norm <- (margin - marg.min)/(marg.max - marg.min) 
  norm %>% pmin(1) %>% pmax(0)
}

map_outcome_to_margin <- function(prob, marg.min = -49, marg.max = 49){
    margin <- prob * (marg.max -marg.min) + marg.min
    margin %>% pmin(marg.max) %>% pmax(marg.min)
}

elo_model <- function(train_data,train_gender,train_margin_lo,train_margin_hi,test_round) {
  
  HGA <- 5
  # carry_over <- 0.5
  k_val <- 20
  
  games_train <- train_data %>%
    filter(gender==train_gender,thisround!=test_round)

  # NBA advantage about 2.5-3.5
  elo.data <- elo.run(
    map_margin_to_outcome(margin,train_margin_lo,train_margin_hi) ~ adjust(home.team_code, HGA) + away.team_code,
    k = k_val,
    data = games_train
  )
  
  # https://cran.r-project.org/web/packages/elo/vignettes/elo.html
  # update proportional log of win margin
  # elo.run(score(points.Home, points.Visitor) ~ team.Home + team.Visitor +
  #           k(20*log(abs(points.Home - points.Visitor) + 1)), data = tournament)
  # 
  # different k values for home and away teams
  # k1 <- 20*log(abs(tournament$points.Home - tournament$points.Visitor) + 1)
  # elo.run(score(points.Home, points.Visitor) ~ team.Home + team.Visitor + k(k1, k1/2), data = tournament)
  
  #
  as.data.frame(elo.data)
  
  # final elo
  final.elos(elo.data)
  
  return(elo.data)
}

elo_predict <- function(elo_data,train_data,train_gender,train_margin_lo,train_margin_hi,test_round) {

  games_test <- train_data %>%
    filter(gender==train_gender,thisround==test_round)
  
  # predict final round
  games_test <- games_test %>%
    mutate(Prob = predict(elo_data, newdata = games_test))
  
  # compare actual vs predicted
  games_test <- games_test %>%
    mutate(pred_margin=round(map_outcome_to_margin(Prob,train_margin_lo,train_margin_hi)),
           result=ifelse((Prob>=0.5 & margin>=0) | (Prob<0.5 & margin<0),TRUE,FALSE)) %>%
    select(home.team_name,away.team_name,margin,Prob,pred_margin,result)
  
  return(games_test)
}

#
# MAIN
#

# 
games %>%
  ggplot(aes(margin,color=gender)) +
  geom_density()

games %>%
  ggplot(aes(gender,margin)) +
  geom_boxplot()

# determine limits of mapping function from density plot (3 sigma?)

margin_men_sd <- games %>%
  filter(gender=="MALE") %>%
  summarize(sd(margin)) %>%
  as.numeric()

margin_men_lo <- -3*margin_men_sd
margin_men_hi <- 3*margin_men_sd

#

margin_women_sd <- games %>%
  filter(gender=="FEMALE") %>%
  summarize(sd(margin)) %>%
  as.numeric()

margin_women_lo <- -3*margin_women_sd
margin_women_hi <- 3*margin_women_sd

#
# ELO
#

# ELO: Men

elo.men <- elo_model(games,"MALE",margin_men_lo,margin_men_hi,8)
as.data.frame(elo.men)

elo.men.final <- final.elos(elo.men)
elo.men.df <- cbind(read.table(text = names(elo.men.final)),elo.men.final)
colnames(elo.men.df) <- c("code","elo")

# Prediction: Men

pred.men <- elo_predict(elo.men,games,"MALE",margin_men_lo,margin_men_hi,8)

pred.men %>%
  filter(result==TRUE) %>%
  summarise(n()/nrow(pred.men))

# ELO: Women
  
elo.women <- elo_model(games,"FEMALE",margin_women_lo,margin_women_hi,8)
as.data.frame(elo.women)

elo.women.final <- final.elos(elo.women)
elo.women.df <- cbind(read.table(text = names(elo.women.final)),elo.women.final)
colnames(elo.women.df) <- c("code","elo")

# Prediction: Women

pred.women <- elo_predict(elo.women,games,"FEMALE",margin_women_lo,margin_women_hi,8)

pred.women %>%
  filter(result==TRUE) %>%
  summarise(n()/nrow(pred.women))

# Let's compare final ELO scores with final standings

link_games_to_elo <- function(mygender,mypath,mygames,myelo) {

  # teams
  tmp <- fromJSON(mypath,flatten=TRUE)
  teams <- subset(tmp, select = -c(sResults)) %>% mutate(gender=mygender)
  
  team_map <- games %>% 
    filter(gender==mygender) %>% 
    select(home.team_code,home.team_name) %>% 
    unique() %>% 
    as.data.frame() %>% 
    mutate_each(toupper)
  
  team_map$home.team_name[team_map$home.team_name == "ALBURY WODONGA"] <- "ALBURY/WODONGA"
  team_map$home.team_name[team_map$home.team_name == "NW TASMANIA"] <- "N W TASMANIA"
  team_map$home.team_name[team_map$home.team_name == "SOUTHERN"] <- "SANDRINGHAM"
  
  final <- teams %>% 
    filter(gender==mygender) %>% 
    left_join(team_map,by=c("clubName"="home.team_name"),suffix=c("",".b")) %>%
    left_join(myelo,by=c("home.team_code"="code"),suffix=c("",".c")) %>%
    mutate(gender=mygender) %>% 
    select(clubName,position,elo,gender)
  
  final$gender <- as.factor(final$gender)
  final$elo <- round(final$elo,0)
  
  return(final)
}

final.men <- link_games_to_elo("MALE","../data/2019/teams_men.txt",games,elo.men.df)
final.women <- link_games_to_elo("FEMALE","../data/2019/teams_women.txt",games,elo.women.df)

final <- rbind(final.men,final.women)

plot1 <- ggplot(final.men,aes(x=reorder(clubName,-position),y=elo)) +
  geom_col() +
  geom_label(aes(label = elo), fill="lightblue",hjust = "center") +
  geom_hline(yintercept=1500,linetype="solid",color="red",size=1) +
  xlab("Team") +
  ylab("ELO") +
  ylim(1450,1550) +
  ggtitle("NBL1 Men 2019", subtitle="Final ELO score vs Final Standing") +
  theme(axis.text.x = element_text(angle = 0),
        plot.title = element_text(hjust = 0.5),
        plot.subtitle=element_text(hjust = 0.5)) + 
  coord_flip()

plot2 <- ggplot(final.women,aes(x=reorder(clubName,-position),y=elo)) +
  geom_col() +
  geom_label(aes(label = elo), fill="pink", hjust = "center") +
  geom_hline(yintercept=1500,linetype="solid",color="red",size=1) +
  xlab("Team") +
  ylab("ELO") +
  ylim(1450,1550) +
  ggtitle("NBL1 Women 2019", subtitle="Final ELO score vs Final Standing") +
  theme(axis.text.x = element_text(angle = 0),
        plot.title = element_text(hjust = 0.5),
        plot.subtitle=element_text(hjust = 0.5)) +
  coord_flip()

#install.packages("cowplot")
library(cowplot)
p <- plot_grid(plot1,plot2)
