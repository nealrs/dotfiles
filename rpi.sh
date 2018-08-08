# COLORS

RESTORE='\033[0m'

RED='\033[00;31m'
GREEN='\033[00;32m'
YELLOW='\033[00;33m'
BLUE='\033[00;34m'
PURPLE='\033[00;35m'
CYAN='\033[00;36m'
LIGHTGRAY='\033[00;37m'

LRED='\033[01;31m'
LGREEN='\033[01;32m'
LYELLOW='\033[01;33m'
LBLUE='\033[01;34m'
LPURPLE='\033[01;35m'
LCYAN='\033[01;36m'
WHITE='\033[01;37m'

# LOGIN / PROMPT
GIT_PS1_SHOWDIRTYSTATE=true

export PS1="🥑$LIGHTGRAY $LCYAN\w$LIGHTGRAY ❯ "

# ALIASES

alias ngrok=~/ngrok
alias py=python
alias gc="git commit -m"
alias gca="git commit -am"
alias gs="git status"
alias gp="git push"
alias gpp="git push -u origin master"
alias gd="git diff"
alias ga="git add"
alias gaa="git add ."
alias gr="git rm"
alias ..="cd .."
alias ~="cd ~"

alias k="clear"
alias reload="source ~/.bash_profile"
alias rel="source ~/.bash_profile"

# AC CONTROLS 

alias ac_on="irsend SEND_ONCE frigid KEY_POWER"
alias ac_power="irsend SEND_ONCE frigid KEY_POWER"
alias ac_on_cool="irsend SEND_ONCE frigid KEY_POWER && irsend SEND_ONCE frigid KEY_C"
alias ac_on_cool_remote="irsend SEND_ONCE frigid KEY_POWER && irsend SEND_ONCE frigid KEY_C && irsend SEND_ONCE frigid BTN_START"
alias ac="irsend SEND_ONCE frigid"

# RPI CONTROLS

alias shutdown="sudo shutdown -h now"
alias reboot="sudo reboot"
alias config="sudo raspi-config"

# RANDO FUNCTIONS

function mcd (){
  mkdir -p -- "$1" &&
    cd -P -- "$1"
}

function weather(){
  printf "$LCYAN\nWEATHER (11205)$RESTORE"
  curl -s wttr.in/11205?0 | tail -n +2
}
function git_branch {
  git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* (*\([^)]*\))*/\1/'
}

function markup_git_branch {
  if [[ -n $@ ]]; then
    if [[ -z $(git status --porcelain 2> /dev/null | tail -n1) ]]; then
      echo -e " \001\033[32m\002($@)\001\033[0m\002"
    else
      echo -e " \001\033[31m\002($@)\001\033[0m\002"
    fi
  fi
}

function __git_prompt {
  GIT_PS1_SHOWDIRTYSTATE=1
  [ `git config user.pair` ] && GIT_PS1_PAIR="`git config user.pair`@"
  __git_ps1 " $GIT_PS1_PAIR%s" | sed 's/ \([+*]\{1,\}\)$/\1/'
}

function neal (){
  printf $LCYAN;
  printf "    _   _ ______          _      _____   _____ \n";
  printf "   | \ | |  ____|   /\   | |    |  __ \ / ____|\n";
  printf "   |  \| | |__     /  \  | |    | |__) | (___  \n";
  printf "   | . \` |  __|   / /\ \ | |    |  _  / \___ \\"; printf "\n";
  printf "   | |\  | |____ / ____ \| |____| | \ \ ____) |\n";
  printf "   |_| \_|______/_/    \_\______|_|  \_\_____/\n\n";

  printf $RESTORE;
}

