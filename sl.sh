# install powerline-shell: https://github.com/b-ryan/powerline-shell
# install powerline fonts: https://github.com/powerline/fonts
# configure powerline: https://github.com/b-ryan/powerline-shell#config-file
  # {
  #   "segments": [
  #     "virtual_env",
  #     "ssh", 
  #     "cwd", 
  #     "git", 
  #     "jobs"
  #   ]
  # }

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

# ALIASES

alias resource="source ~/.bash_profile"
alias reload="source ~/.bash_profile"
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
alias gactions=~/gactions
alias repos="cd ~/documents/repos"
alias k="clear"

# FUNCTIONS

function lzip(){
  zip -FSr lambda.zip *
}

function mcd (){
  mkdir -p -- "$1" &&
    cd -P -- "$1"
}

function sl (){
  printf $LCYAN;
  printf "                         __                    .__                                   \n";
  printf "  ____________    ____  |  | __  ____    ____  |  |  _____    ___.__.  ____  _______ \n";
  printf " /  ___/\____ \  /  _ \ |  |/ /_/ __ \  /    \ |  |  \__  \  <   |  |_/ __ \ \_  __ \\"; printf "\n";
  printf " \___ \ |  |_> >(  <_> )|    < \  ___/ |   |  \|  |__ / __ \_ \___  |\  ___/  |  | \/\n";
  printf "/____  >|   __/  \____/ |__|_ \ \___  >|___|  /|____/(____  / / ____| \___  > |__|   \n";
  printf "     \/ |__|                 \/     \/      \/            \/  \/          \/         \n\n";

  printf $RESTORE;
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

function gdep {
  if [ -n "$1" ]
  then
    while true; do
      read -p "CONFIRM PRODUCTION DEPLOY $(git describe --tags --abbrev=0) => $1 | (Y/N) " yn
      case $yn in
        [Yy]* ) git checkout master && git checkout master && git reset --hard origin/master && git tag $1 && git push --tags ; break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
      esac
    done
  else
    printf "$LRED\nYOU MUST INCLUDE A TAG\n$RESTORE"
  fi
}

# START SESSION/PROMPT

unset MAILCHECK
# Set this to false to turn off version control status checking within the prompt for all themes
export SCM_CHECK=true
export SCM_GIT_SHOW_DETAILS=true
export SCM_GIT_SHOW_MINIMAL_INFO=true

#### powerline-shell
function _update_ps1() {
    PS1=$(powerline-shell $?)
}

if [[ $TERM != linux && ! $PROMPT_COMMAND =~ _update_ps1 ]]; then
    PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
fi
####

hi
curl -s wttr.in/11205?0 | tail -n +2 # change to your local zipcode
printf "\n$GREEN Well $(id -F), it seems you survived our last encounter…\n\n$LIGHTGRAY";