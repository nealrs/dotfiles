# IMPORTS ETC
export PATH="/usr/local/opt/openssl/bin:$PATH:/usr/local/share/npm/bin/:~/~npm-global/bin"
source /usr/local/opt/autoenv/activate.sh
source ~/.bash_git
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

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

# FUNCTIONS

lzip()
{
  zip -FSr lambda.zip *
}

mcd ()
{
  mkdir -p -- "$1" &&
    cd -P -- "$1"
}

sl (){
  printf $LCYAN;
  printf "                         __                    .__                                   \n";
  printf "  ____________    ____  |  | __  ____    ____  |  |  _____    ___.__.  ____  _______ \n";
  printf " /  ___/\____ \  /  _ \ |  |/ /_/ __ \  /    \ |  |  \__  \  <   |  |_/ __ \ \_  __ \\"; printf "\n";
  printf " \___ \ |  |_> >(  <_> )|    < \  ___/ |   |  \|  |__ / __ \_ \___  |\  ___/  |  | \/\n";
  printf "/____  >|   __/  \____/ |__|_ \ \___  >|___|  /|____/(____  / / ____| \___  > |__|   \n";
  printf "     \/ |__|                 \/     \/      \/            \/  \/          \/         \n\n";

  printf $RESTORE;
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
export PS1="🥑$LIGHTGRAY $LCYAN\w$LIGHTGRAY ❯ "

sl
printf "\n$GREEN Well $(id -F), it seems you survived our last encounter…\n\n$LIGHTGRAY";

