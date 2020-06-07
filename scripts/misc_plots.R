# misc plots

#
# Additional features
#


# point diff for home minus away
all$d0 <- all$a.score - all$b.score
all$d1 <- all$a.q1 - all$b.q1
all$d2 <- all$a.q2 - all$b.q2
all$d3 <- all$a.q3 - all$b.q3
all$d4 <- all$a.q4 - all$b.q4

# fractional scores
all$a.f1 <- all$a.q1 / all$a.score
all$a.f2 <- all$a.q2 / all$a.score
all$a.f3 <- all$a.q3 / all$a.score
all$a.f4 <- all$a.q4 / all$a.score

all$b.f1 <- all$b.q1 / all$b.score
all$b.f2 <- all$b.q2 / all$b.score
all$b.f3 <- all$b.q3 / all$b.score
all$b.f4 <- all$b.q4 / all$b.score

# venues by team is not unique
#venues <- all %>% select(venue_id,venue_name,a.team_code,b.team_code)
#venues <- venues %>% arrange(venue_id)
#tmp <- venues[!duplicated(venues), ]
#write.csv(tmp,"venues.csv")

# filter by gender
men <- all %>% filter(gender == "MALE")
women <- all %>% filter(gender == "FEMALE")

summary(men$d0)
summary(women$d0)

count(men)
count(women)

qplot(all$d0,
      main="Score Differential",
      xlab="Final Home Minus Away Points",
      ylab="Matches",
      geom="histogram",
      fill=all$gender,
      binwidth=5) + labs(fill="Gender")

ggplot(all,aes(x=d0,fill=gender))+
  geom_histogram(aes(y=5*..density..),binwidth=5)+
  facet_wrap(~gender,nrow=2) +
  xlab("Final Home Minus Away Points") +
  labs(title="Points Differential Rounds 1-15")

ggplot(all, aes(x=d0, y=d1)) +
  geom_point() +
  facet_wrap(~gender,nrow=2) +
  xlab("Final Home Minus Away Points") +
  ylab("First Quarter Home Minus Away Points") +
  labs(title="Points Differential Rounds 1-15") +
  geom_smooth(method=lm, se=FALSE, fullrange=TRUE)


ggplot(all, aes(x=d0, y=d4)) +
  geom_point() +
  facet_wrap(~gender,nrow=2) +
  xlab("Final Home Minus Away Points") +
  ylab("First Quarter Home Minus Away Points") +
  labs(title="Points Differential Rounds 1-15") +
  geom_density_2d()

# home games
all$home <- 'HOME'

# get NUN games
team <- all %>% filter(a.team_code=='NUN' | b.team_code=='NUN')

# split tibble into home and away games; set
tmp1 <- team %>% filter(venue_id != 21412)
tmp1 <- tmp1 %>% mutate(home='AWAY')
tmp2 <- team %>% filter(venue_id == 21412)
team <- rbind(tmp1,tmp2)

team$direction <- 1
team$opp <- ''

tmp1 <- team %>% filter(b.team_code == 'NUN')
tmp1 <- tmp1 %>% mutate(direction=-1)
tmp1 <- tmp1 %>% mutate(opp=a.team_code)
tmp2 <- team %>% filter(b.team_code != "NUN")
tmp2 <- tmp2 %>% mutate(opp=b.team_code)
team <- rbind(tmp1,tmp2)

team$d0 <- team$d0 * team$direction
team$d1 <- team$d1 * team$direction
team$d2 <- team$d2 * team$direction
team$d3 <- team$d3 * team$direction
team$d4 <- team$d4 * team$direction

nuna_men <- team %>% filter(gender=='MALE')

summary(nuna_men)

qplot(nuna_men$d0,
      main="Score Differential",
      xlab="Team Minus Opposition Final Score",
      ylab="Matches",
      geom="histogram",
      fill=nuna_men$home,
      binwidth=5) + labs(fill="")

ggplot(nuna_men,aes(x=d0,fill=home))+
  geom_histogram(aes(y=5*..density..),binwidth=5)+
  facet_wrap(~home,nrow=2) +
  xlab("Team Minus Opposition Final Score") +
  labs(title="Points Differential Rounds 1-15")

ggplot(nuna_men, aes(x=d0, y=d4)) +
  geom_point() +
  geom_text(aes(label=opp),hjust=0, vjust=0) +
  facet_wrap(~home,nrow=2) +
  xlab("Team Minus Opposition Final Score") +
  ylab("First Quarter Home Minus Away Points") +
  labs(title="Points Differential Rounds 1-15") +
  geom_density_2d()