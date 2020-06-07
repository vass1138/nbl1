# NBL1: Scripts

Brief description of scripts used to download and analyse team and player data.

- make_elo.R (requires objects generated by parse_json.R)\
  Generate ELO values from all rounds in season, except one round excluded as a test round.

- misc_plots.R\
  Miscellaneous ggplot examples.  Saved for future reference.

- nbl1_round_json.py\
  Initial (run-once) script to retrieve JSON data from online sources.  Results have been saved to data subfolder.

- parse_json.R\
  Main script for parsing game data and arranging home and away games.

- parse_schedule_20.R
  Attempt to parse 2020 schedule PDF file (multiple tables in 2-column layout).  Initial results saved to misc subfolder and require extensive manual cleanup.

- players.R
  Player stats.  Many of the source figures were normalised to team totals and are not the usual actual figures.  For example, free throws made (FTM) and attempted (FTA) are normalised to the team totals, and the percentage (FTP = FTM / FTA) is acually a fraction!