rm(list = ls(all = TRUE))

library(here)
getwd()

library(tidyverse)
library(dplyr)

process_round <- function(filename) {

  library("jsonlite")
  json_data <- fromJSON(filename,flatten=TRUE)
  
  # Get the files names
  #files = list.files(pattern="^round*")
  
  # First apply read.csv, then rbind
  # myfiles = do.call(rbind, lapply(files, function(x) fromJSON(x, flatten=TRUE)))
  #json_data = lapply(files, function(x) fromJSON(x, flatten=TRUE))
  
  #length(json_data)
  #str(json_data)
  
  games <- json_data[[1]]$matches
  thisround <- json_data[[1]]$round

  print(paste0("Round ",thisround))
  
  #str(games)
  #head(games)
  #colnames(games)
  
  df <- data.frame(thisround,games$match_time,games$matchNumber,games$competitors.venue.venueId,games$competitors.venue.venueName,games$gender)
  
  #colnames(df)
  #str(df)
  
  # rename columns by known name
  colnames(df)[colnames(df)=="games.match_time"] <- "game_time"
  colnames(df)[colnames(df)=="games.matchNumber"] <- "game_number"
  colnames(df)[colnames(df)=="games.competitors.venue.venueId"] <- "venue_id"
  colnames(df)[colnames(df)=="games.competitors.venue.venueName"] <- "venue_name"
  colnames(df)[colnames(df)=="games.gender"] <- "gender"
  
  #
  #
  #
  
  # need a tibble to do filter
  tdf <- as_tibble(games)
  
  # subset stats columns only
  #str(tdf)
  pstats_tmp <- tdf %>% select(starts_with("period_stats"))
  
  # shift non-NA values to left
  pstats_tmp[] <-  t(apply(pstats_tmp, 1, function(x) c(x[!is.na(x)], x[is.na(x)])))
  
  # subset first 16 columns, 8 for each team
  pstats <- pstats_tmp[c(1:16)]
  
  # rename columns by index as stats column names vary
  
  names(pstats)[1] <- "a.team_name"
  names(pstats)[2] <- "a.score"
  names(pstats)[3] <- "a.team_code"
  names(pstats)[4] <- "a.logo"
  names(pstats)[5] <- "a.q1"
  names(pstats)[6] <- "a.q2"
  names(pstats)[7] <- "a.q3"
  names(pstats)[8] <- "a.q4"
  
  names(pstats)[9] <- "b.team_name"
  names(pstats)[10] <- "b.score"
  names(pstats)[11] <- "b.team_code"
  names(pstats)[12] <- "b.logo"
  names(pstats)[13] <- "b.q1"
  names(pstats)[14] <- "b.q2"
  names(pstats)[15] <- "b.q3"
  names(pstats)[16] <- "b.q4"
  
  pstats[,c(2,5:8,10,13:16)] <- sapply(pstats[,c(2,5:8,10,13:16)],as.numeric)
  
  # combine match header and stats
  games_this_round <- cbind(df,pstats)
  
  return(games_this_round)
}

#
# MAIN
#

# game data by round
files = list.files(path="../data/2019",pattern="^round*",full.names = TRUE)
lmax <- length(files)

# initialise
thisround <- process_round(files[1])
games <- thisround
str(games)

for (i in 2:length(files)) {
  
  thisround <- process_round(files[i])
  games <- rbind(games,thisround)
}

# convert factors to character
games %>% mutate_if(is.factor, as.character) -> games

# identify home teams
venues <- read_csv("../data/2019/venues_mapping.csv")

venues <- venues %>%
  mutate(uid=paste(venue_id,home_team_code,sep="."))

games <- games %>%
  mutate(a.uid=paste(venue_id,a.team_code,sep="."),
         b.uid=paste(venue_id,b.team_code,sep="."),
         home_team_idx=NA)

# a home team
games <- games %>%
  left_join(venues,by=c("a.uid"="uid"),suffix=c("","_venues")) %>%
  mutate(home_team_idx=ifelse(!is.na(home_team_code),"a",home_team_idx)) %>%
  select(-ends_with("_venues"),-c("home_team_code"))

# b home team
games <- games %>%
  left_join(venues,by=c("b.uid"="uid"),suffix=c("","_venues")) %>%
  mutate(home_team_idx=ifelse(!is.na(home_team_code),"b",home_team_idx)) %>%
  select(-ends_with("_venues"),-c("home_team_code"))

# make team a home for any remaining
games <- games %>%
  mutate(home_team_idx=ifelse(is.na(home_team_idx),"a",home_team_idx))

# transform a,b features to home,away

a_names <- colnames(games)[grep("^a\\.",colnames(games))]
b_names <- colnames(games)[grep("^b\\.",colnames(games))]

bare_names <- sapply(strsplit(a_names,"\\."),function(x) x[2])

for(name in bare_names) {
  
  a <- paste("a",name,sep=".")
  b <- paste("b",name,sep=".")
  home <- paste("home",name,sep=".")
  away <- paste("away",name,sep=".")
  
  games <- games %>%
    mutate(!!home:=ifelse(home_team_idx=="a",.[[a]],.[[b]])) %>%
    mutate(!!away:=ifelse(home_team_idx=="a",.[[b]],.[[a]]))

}

# remove original a,b columns
games <- games %>% 
  select(-a_names,-b_names)

# margin
games$margin <- games$home.score - games$away.score
