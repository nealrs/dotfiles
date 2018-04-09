#!/bin/bash

# COLORS
RESTORE='\033[0m'
LCYAN='\033[01;36m'

declare -a subway=(
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
)

printf "$LCYAN\nNYC SUBWAY STATUS$RESTORE\n"
for i in "${subway[@]}"
do
  curl -s nealrs.herokuapp.com/$i/ | jq -r '.titleText | sub(" SUBWAY "; " ")'
done