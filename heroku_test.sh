#!/bin/bash

# COLORS
RESTORE='\033[0m'
LCYAN='\033[01;36m'

# declare array
declare -a arr=(
  #"news"
  
  "mta/subway"
  "mta/bus"
  "mta/mnr"
  "mta/lirr"
  "mta/bt"
  
  "subway/ace"
  "subway/bdfm"
  "subway/g"
  "subway/l"
  "subway/nqrw"
  "subway/jz"
  "subway/123"
  "subway/456"
  "subway/7" 
  "subway/sir" 
  "subway/s" 

  "time" 
  "time/CT" 
  "time/MT" 
  "time/PT"
)

## now loop through the above array
for i in "${arr[@]}"
do
  printf "\n\nCHECKING: $LCYAN$i$RESTORE\n"
  curl -s nealrs.herokuapp.com/$i/ | python -m json.tool
  # curl -s nealrs.herokuapp.com/mta/subway/ | python -m json.tool
done
