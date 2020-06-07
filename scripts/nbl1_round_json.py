# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""
import requests

# rounds
#result = requests.get("https://nbl1.com.au/api/v1/match/results?page=1&limit=30&rounds=15")

# teams
#result = requests.get("https://nbl1.com.au/api/v1/team/getstats?splits=&page=1&competitionId=23704&limit=300&full=1")

# players
result = requests.get("https://nbl1.com.au/api/v1/players/leaderboard?competitionId=23704&page=1&limit=300")

print(result.status_code)

result.headers

c = result.content
print(c)

from bs4 import BeautifulSoup
soup = BeautifulSoup(c,"html.parser")

import json
newDictionary=json.loads(str(soup))

with open('c:/temp/data.txt', 'w') as outfile:  
    json.dump(newDictionary, outfile)


