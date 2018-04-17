# IMPORTS ETC
#export PATH="/usr/local/opt/openssl/bin:$PATH:/usr/local/share/npm/bin/:~/~npm-global/bin:"
export PATH="/usr/local/opt/openssl/bin:$PATH:/usr/local/share/npm/bin/:~/~npm-global/bin:$HOME/.npm-packages/bin:$PATH"

source /usr/local/opt/autoenv/activate.sh
source ~/.bash_git

#if [ -f ~/.bashrc ]; then
#  . ~/.bashrc
#fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# ALIASES

alias resource="source ~/.bash_profile"
alias ngrok=~/ngrok
alias py=python
alias gc="git commit -m"
alias gca="git commit -am"
alias gs="git status"
alias gp="git push"
alias gd="git diff"
alias ga="git add"
alias gaa="git add ."
alias gr="git rm"
alias ..="cd .."
alias ~="cd ~"
alias gactions=~/gactions
alias weather="curl wttr.in/11205"
alias repos="cd ~/documents/repos"

# AWS MOCKING STUFF

alias ddblocal="cd ~/documents/repos/tools/ddb_local/ && java -Djava.library.path=./DynamoDBLocal_lib -jar DynamoDBLocal.jar -sharedDb"

# FUNCTIONS

function lzip(){
  zip -FSr lambda.zip *
}

function mcd (){
  mkdir -p -- "$1" &&
    cd -P -- "$1"
}

function hi (){
  printf $LCYAN;
  printf "                         __                    .__                                   \n";
  printf "  ____________    ____  |  | __  ____    ____  |  |  _____    ___.__.  ____  _______ \n";
  printf " /  ___/\____ \  /  _ \ |  |/ /_/ __ \  /    \ |  |  \__  \  <   |  |_/ __ \ \_  __ \\"; printf "\n";
  printf " \___ \ |  |_> >(  <_> )|    < \  ___/ |   |  \|  |__ / __ \_ \___  |\  ___/  |  | \/\n";
  printf "/____  >|   __/  \____/ |__|_ \ \___  >|___|  /|____/(____  / / ____| \___  > |__|   \n";
  printf "     \/ |__|                 \/     \/      \/            \/  \/          \/         \n\n";

  printf $RESTORE;
}

function mta(){
  printf "$LCYAN\nNYC SUBWAY STATUS$RESTORE\n"
  curl -s nealrs.herokuapp.com/nyc/
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

archey
hi
printf "\n$GREEN Well $(id -F), it seems you survived our last encounter…\n\n$LIGHTGRAY";

###### BASH IT ######

# Path to the bash it configuration
export BASH_IT="/Users/nealrs/.bash_it"

# Lock and Load a custom theme file
# location /.bash_it/themes/
export BASH_IT_THEME='bobby'

# (Advanced): Change this to the name of your remote repo if you
# cloned bash-it with a remote other than origin such as `bash-it`.
# export BASH_IT_REMOTE='bash-it'

# Your place for hosting Git repos. I use this for private repos.
export GIT_HOSTING='neal@spokenlayer.com'

# Don't check mail when opening terminal.
unset MAILCHECK

# Change this to your console based IRC client of choice.
export IRC_CLIENT='irssi'

# Set this to the command you use for todo.txt-cli
export TODO="t"

# Set this to false to turn off version control status checking within the prompt for all themes
export SCM_CHECK=true
export SCM_GIT_SHOW_DETAILS=true
export SCM_GIT_SHOW_MINIMAL_INFO=true

# Set theme
export BASH_IT_THEME="powerline"

POWERLINE_PROMPT="battery user_info scm cwd"

# Set Xterm/screen/Tmux title with only a short hostname.
# Uncomment this (or set SHORT_HOSTNAME to something else),
# Will otherwise fall back on $HOSTNAME.
#export SHORT_HOSTNAME=$(hostname -s)

# Set Xterm/screen/Tmux title with only a short username.
# Uncomment this (or set SHORT_USER to something else),
# Will otherwise fall back on $USER.
#export SHORT_USER=${USER:0:8}

# Set Xterm/screen/Tmux title with shortened command and directory.
# Uncomment this to set.
#export SHORT_TERM_LINE=true

# Set vcprompt executable path for scm advance info in prompt (demula theme)
# https://github.com/djl/vcprompt
#export VCPROMPT_EXECUTABLE=~/.vcprompt/bin/vcprompt

# (Advanced): Uncomment this to make Bash-it reload itself automatically
# after enabling or disabling aliases, plugins, and completions.
# export BASH_IT_AUTOMATIC_RELOAD_AFTER_CONFIG_CHANGE=1

# Load Bash It
source "$BASH_IT"/bash_it.sh
