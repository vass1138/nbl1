# clear all objects from current session
rm(list = ls(all = TRUE))

# set working directory (.here)
library(here)
getwd()

library("jsonlite")
library(tidyverse)
library(dplyr)

# used for labelling outliers on boxplot
is_outlier <- function(x) {
  return(x < quantile(x, 0.25) - 1.5 * IQR(x) | x > quantile(x, 0.75) + 1.5 * IQR(x))
}

#
# DATA
#

# FIBA season stats by player
json_data <- fromJSON("../data/2019/players_men.txt",flatten=TRUE)
players <- as.data.frame(json_data$data$data) %>% mutate(gender="MALE")

json_data <- fromJSON("../data/2019/players_women.txt",flatten=TRUE)
players <- rbind(players,as.data.frame(json_data$data$data) %>% mutate(gender="FEMALE"))

# teams
tmp <- fromJSON("../data/2019/teams_men.txt",flatten=TRUE)
teams <- subset(tmp, select = -c(sResults)) %>% mutate(gender="MALE")

tmp <- fromJSON("../data/2019/teams_women.txt",flatten=TRUE)
teams <- rbind(teams,subset(tmp, select = -c(sResults)) %>% mutate(gender="FEMALE"))

#
# MAIN
#

# append team name to players
players <- players %>%
  inner_join(select(teams,"position","clubName","teamId"),by="teamId")

# additional features
# PPM = points per minute
# EFF = efficiency
# POS = possessions
# eFGP = effective technical shooting percentage
players <- players %>%
  mutate(PPM = PPG/MPG,
         EFF = (PPG + RPG + APG + SPG + BPG - (FGA-FGM) - (THREEPA - THREEPM) - (FTM-FTA) - TOPG),
         POS = 0.96 * (FGA + THREEPA + TOPG + (0.44 * FTA)),
         eFGP = if_else(FGA==0,0,(FGM + (0.5*THREEPM))/FGA))


# density plot for efficiency
ggplot(players,aes(EFF,color=gender)) +
  geom_density() +
  ggtitle("NBL1 Player Efficiency") +
  xlab("Efficiency") +
  ylab("Density")

get_top <- function(mydata,mygender,mycol,mycount) {
  
  if (mycount > nrow(mydata)) {
    mycount = nrow(mydata)
  }
  
  mydata <- mydata %>%
    filter(gender==mygender) %>% 
    arrange(desc(!!as.name(mycol))) %>% 
    top_n(mycount) 
  
  return(mydata)
}

players.FGP <- get_top(players,"MALE","FGP",5)
players.THREEPP <- get_top(players,"MALE","FGP",5)
players.FTP <- get_top(players,"MALE","FGP",5)

players.RPG <- get_top(players,"MALE","RPG",5)
players.APG <- get_top(players,"MALE","APG",5)
players.SPG <- get_top(players,"MALE","SPG",5)
players.BPG <- get_top(players,"MALE","BPG",5)

players.PPM <- get_top(players,"MALE","PPM",5)
players.EFF <- get_top(players,"MALE","EFF",5)

players.TOPG <- get_top(players,"MALE","TOPG",5)
players.PGPG <- get_top(players,"MALE","PFPG",5)


# league median
median_league <- players %>% 
  filter(gender=="MALE") %>% 
  summarise_if(is.numeric,median)

# team median
median_team <- players %>% 
  filter(gender=="MALE") %>% 
  group_by(clubName) %>% 
  summarise_if(is.numeric,median)


  



# efficiency by club, in order of club rank
players %>%
  filter(gender=="MALE") %>% 
  group_by(clubName) %>%
  arrange(position) %>%
  mutate(outlier = ifelse(is_outlier(EFF),FULLNAME,NA)) %>%
  ggplot(aes(x=reorder(clubName,position),y=EFF)) +
    geom_boxplot() +
    facet_grid(. ~ gender) +
    geom_text(aes(label = outlier), na.rm = TRUE, hjust = "right", nudge_x = -0.2, nudge_y = 1, size=3) +
    geom_hline(yintercept=median_league$EFF,linetype="solid",color="red",size=2) +
    xlab("Team") +
    ylab("Efficiency") +
    ggtitle("NBL1 Men 2019: Efficiency by Team") +
    theme(axis.text.x = element_text(angle = 90))

# efficiency by player
players_nun <- players %>%
  filter(clubName=="NUNAWADING",gender=="MALE")

ggplot(players_nun,aes(EFF)) +
  geom_density()

# top 10 players by efficiency
players_nun <- players_nun %>%
  arrange(desc(EFF)) %>% 
  top_n(10)

ggplot(players_nun,aes(x=reorder(factor(FULLNAME),EFF),y=EFF)) +
  geom_bar(stat="identity") +
  xlab("Player") +
  ylab("Efficiency") +
  ggtitle("NBL1 Men 2019: Efficiency by Team") +
  geom_text(aes(x=FULLNAME, y=EFF, label=EFF, 
                hjust=ifelse(sign(EFF)>0, -0.25, 0)), 
            position = position_dodge(width=1)) +
  coord_flip()

# recalc and confirm percentages
players %>%
  group_by(clubName) %>%
  summarize(mean(FGP),
            mean(THREEPP))

players %>%
  mutate(THREEPPEV = round(ifelse(THREEPA==0,0,THREEPM/THREEPA),2)) %>%
  select(starts_with("THREE"))

colnames(players)
tmp <- players %>%
  arrange(desc(MPG))


ggplot(tmp[1:10,],aes(x=reorder(FULLNAME,-MPG),y=MPG)) +
  geom_bar(stat="identity")





