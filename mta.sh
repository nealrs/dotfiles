#!/bin/bash

# COLORS
RESTORE='\033[0m'
LCYAN='\033[01;36m'

printf "$LCYAN\nNYC SUBWAY STATUS$RESTORE\n"
curl -s nealrs.herokuapp.com/nyc/
