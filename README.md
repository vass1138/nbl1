
# NBL1 2019: Inaugural Australian off-season basketball competition

Player stats and game data from the 2019 NBL1 season.

**Disclaimer: This material is for educational  purposes only.**

## Data Sources

Data was scraped (Python script included) from the NBL1 and FIBA stats websites in 2019.  Some of this data may no longer be available from those sites.

Data was downloaded as JSON.  Sample API URLs below.

Assets include:
 - game data: one file per round
 - player data: season stats
 - team data: standings at end of season

## Data Processing

Summary of major data cleaning operations. 

### Arranging Game Data by Home Team

Game data was not originally organised by home/away team.  Extracted a unique team list and 
manually assigned the corresponding home location.  This list was then joined with the game data to identify the home team.  Columns were rearranged so that the first team listed per game was the home team.  (Required for subsequent ELO modelling.)

### Calculating Player efficiency, possessions, and effective field goal percentage

The majority of player stats were downloaded already normalised to team totals (ie. fractional, not absolute, values supplied).  Despite this, the _standard_ expressions for additional calculated features were used as-is:

- efficiency: 
  > EFF = [PTS + REB +AST +STL + BLK + (FGA - FGM) - (FTA - FTM) - TO] / GP
- possessions: 
  > POS = 0.96 * [FGA - REB + TO (0.44 * FTA)]
- effective field goal percentage (actually, fraction): 
  > eFGP = (FGM + 0.5 * 3FGM) / FGA 

Note: REB represents _total_ rebounds.  Distinction between offensive and defensive is not available.

## ELO Modelling

The ELO modelling attempts were inspired by the Australian Football League (AFL) fitzRoy package: https://github.com/jimmyday12/fitzRoy.  This was one of the few examples I found that had such modelling in R.

Margin (home minus away scores) was mapped to from zero to one.  The margin range used was -45 to 45 points, which corresponds to +/- 3 sigma of the observed margin values.

Median margin was only 5 points.

## Contributing

If you'd like to contribute, please fork the repository and use a feature
branch. Pull requests are warmly welcome.

## Links / References

Data sources listed below.  Special mention also of the fitzRoy package that helped me getting started with the ELO modelling.

- NBL1 API (data no longer available): 
    - team example: https://nbl1.com.au/api/v1/team/getstats?splits=&page=1&competitionId=23703&limit=20&full=1
    - player example: https://nbl1.com.au/api/v1/players/leaderboard?competitionId=23703&page=1&limit=20
- FIBA stats API:
    - competition example: https://www.fibalivestats.com/data/competition/23703.json
    - game example: https://www.fibalivestats.com/data/1111022/data.json

## Licensing

The code in this project is licensed under MIT license.