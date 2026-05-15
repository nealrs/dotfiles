# some more ls aliases
alias ll='ls -alF'
#alias ls='ls -A'
#alias l='ls -CF'

alias l="ls -pa --color=auto"
alias ls="ls -pa --color=auto"
alias resource="source ~/.sshrc"
alias reload="source ~/.zshrc"
alias rel="source ~/.zshrc"
alias ..="cd .."
alias ~="cd ~"
alias k="clear"
alias dockup="docker compose up --detach"
alias dockupbuild="docker compose up --detach --build"
#alias s3nealup="s3fs nealshyam.com ~/s3/ns -o passwd_file=${HOME}/.passwd-s3fs -o url=http://s3.amazonaws.com/ -o use_path_request_style"
#alias s3nealdown="s3fs unmount  ~/s3/ns -o passwd_file=${HOME}/.passwd-s3fs -o url=http://s3.amazonaws.com/ -o use_path_request_style"
alias py="python3"
alias pip="python3 -m pip"
#alias kewtie="ssh nealrs@192.168.4.50"
alias web="python3 -m http.server" #web 1337` to run on port 1337
alias dns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder" #flush dns on mac
alias ii="ping -c 2 apnews.com && curl -sS 'neal.rs' | xmllint -html -xpath '//head/title/text()' - "
alias nealrs="ssh nealrs@192.168.4.50"
alias repos="cd ~/Documents/repos"

function avatar(){
  echo "\e[32m                                     ***                  \e[0m";
  echo "\e[32m                         ************* ***                \e[0m";
  echo "\e[32m                     *****               **               \e[0m";
  echo "\e[32m                 *****                    *               \e[0m";
  echo "\e[32m               ***                        *               \e[0m";
  echo "\e[32m             ***                          *               \e[0m";
  echo "\e[32m            **                            *               \e[0m";
  echo "\e[32m            *                          ***                \e[0m";
  echo "\e[32m            *                          **                 \e[0m";
  echo "\e[32m            *        ************ ****** **               \e[0m";
  echo "\e[32m             *       * **        ****      **              \e[0m";
  echo "\e[32m             **    **   *        *  **      *              \e[0m";
  echo "\e[32m              ** ***    **     ***   **     *              \e[0m";
  echo "\e[32m              ****       *******      *******              \e[0m";
  echo "\e[32m              *                           *                \e[0m";
  echo "\e[32m              *                           *                \e[0m";
  echo "\e[32m              *                           **               \e[0m";
  echo "\e[32m               *                           *               \e[0m";
  echo "\e[32m                ***                        *               \e[0m";
  echo "\e[32m                  *                        *               \e[0m";
  echo "\e[32m                  *                       **               \e[0m";
  echo "\e[32m                  *                      **                \e[0m";
  echo "\e[32m                  *                   ****                 \e[0m";
  echo "\e[32m             ******                   **                   \e[0m";
  echo "\e[32m          ****                         *********           \e[0m";
  echo "\e[32m       ****                                    ******      \e[0m";
  echo "\e[32m    ****                                            ****   \e[0m";
}

function neal_o(){
  echo "\e[32m                                     ***                   \e[0m";
  echo "\e[32m                         ************* ***                 \e[0m";
  echo "\e[32m                     *****               **                \e[0m";
  echo "\e[32m                 *****                    *                \e[0m";
  echo "\e[32m               ***                        *                \e[0m";
  echo "\e[32m             ***          \e[1;97mN E A L\e[0m\e[32m         *               \e[0m";
  echo "\e[32m            **                            *                \e[0m";
  echo "\e[32m            *                          ***                 \e[0m";
  echo "\e[32m            *                          **                  \e[0m";
  echo "\e[32m            *        ************ ****** **                \e[0m";
  echo "\e[32m             *       * **        ****      **              \e[0m";
  echo "\e[32m             **    **   *        *  **      *              \e[0m";
  echo "\e[32m              *  ***    **     ***   **     *              \e[0m";
  echo "\e[32m              ****       *******      *******              \e[0m";
  echo "\e[32m              *                           *                \e[0m";
  echo "\e[32m              *                           *                \e[0m";
  echo "\e[32m              *                           **               \e[0m";
  echo "\e[32m               *                           *               \e[0m";
  echo "\e[32m                ***                        *               \e[0m";
  echo "\e[32m                  *                        *               \e[0m";
  echo "\e[32m                  *                       **               \e[0m";
  echo "\e[32m                  *                      **                \e[0m";
  echo "\e[32m                  *                   ****                 \e[0m";
  echo "\e[32m             ******                   **                   \e[0m";
  echo "\e[32m          ****                         *********           \e[0m";
  echo "\e[32m       ****                                    ******      \e[0m";
  echo "\e[32m    ****                                            ****   \e[0m";
}

function neal(){
  echo "\e[32m                                     ███                   \e[0m";
  echo "\e[32m                         █████████████ ███                 \e[0m";
  echo "\e[32m                     █████               ██                \e[0m";
  echo "\e[32m                 █████                    █                \e[0m";
  echo "\e[32m               ███                        █                \e[0m";
  echo "\e[32m             ███          \e[1;97mN E A L\e[0m\e[32m         █               \e[0m";
  echo "\e[32m            ██                            █                \e[0m";
  echo "\e[32m            █                          ███                 \e[0m";
  echo "\e[32m            █                          ██                  \e[0m";
  echo "\e[32m            █         ║║║║║║║║║║║     ║║║║║║               \e[0m";
  echo "\e[32m             █       ║ ║║        ║║║║║      ║              \e[0m";
  echo "\e[32m             ██    ║║   ║        ║  ║║      ║              \e[0m";
  echo "\e[32m              █  ║║║    ║║     ║║║   ║║     ║              \e[0m";
  echo "\e[32m              █║║║       ║║║║║║║      ║║║║║║║              \e[0m";
  echo "\e[32m              █                           █                \e[0m";
  echo "\e[32m              █                           █                \e[0m";
  echo "\e[32m              █                           ██               \e[0m";
  echo "\e[32m               █                           █               \e[0m";
  echo "\e[32m                ███                        █               \e[0m";
  echo "\e[32m                  █                        █               \e[0m";
  echo "\e[32m                  █                       ██               \e[0m";
  echo "\e[32m                  █                      ██                \e[0m";
  echo "\e[32m                  █                   ████                 \e[0m";
  echo "\e[32m             ██████                   ██                   \e[0m";
  echo "\e[32m          ████                         █████████           \e[0m";
  echo "\e[32m       ████                                    ██████      \e[0m";
  echo "\e[32m    ████                                            ████   \e[0m";
}

#https://www.christianroessler.net/tech/2015/bash-array-random-element.html
function hi(){
  echo -e "\e[33m                                   \e[0m";
  echo -e "\e[32m █████╗ ██╗   ██╗██████╗ ██╗ ██████╗██╗   ██╗███████╗\e[0m";
  echo -e "\e[32m██╔══██╗██║   ██║██╔══██╗██║██╔════╝██║   ██║██╔════╝\e[0m";
  echo -e "\e[32m███████║██║   ██║██║  ██║██║██║     ██║   ██║███████╗\e[0m";
  echo -e "\e[32m██╔══██║██║   ██║██║  ██║██║██║     ██║   ██║╚════██║\e[0m";
  echo -e "\e[32m██║  ██║╚██████╔╝██████╔╝██║╚██████╗╚██████╔╝███████║\e[0m";
  echo -e "\e[32m╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝\e[0m";

  THINGS=(
    "remember to move" 
    "things ain't that bad" 
    "financially speaking, you're ok" 
    "don't take your wife for granted"
    "tomorrow might be better"
    "breathe"
    "tomorrow is another day"
    "be thankful for what you have"
    "take a break"
    "eat something"
    "take the lead on dinner tonight"
    "take a walk"
    "stand up and stretch"
    "you got this"
    "Rumi loves you"
    "go to town, you're the Head of Product"
  )
  RANDOM_INDEX=$((RANDOM % ${#THINGS[@]}))
  THING="${THINGS[$RANDOM_INDEX]}"

  net
  printf "\nHey buddy, $THING.\n\n";
  weather
}

function net(){
  printf "\n";
  printf "\e[32mWAN\e[0m\n";
  wan
  printf "\n\e[32mLAN\e[0m\n";
  lan
}

function weather(){
  #printf "$LCYAN\nWEATHER (11415)$RESTORE"
  curl 'wttr.in?format=3'
}

function mcd (){ #creates a directory and then like, goes into it
  mkdir -p -- "$1" &&
    cd -P -- "$1"
}

function wan(){
  #curl https://ipinfo.io/ip
  ip4=$(curl -s https://api.ipify.org)
  ip6=$(curl -s https://api64.ipify.org)
  echo "IPv4: \e[33m$ip4\e[0m"
  echo "IPv6: \e[33m$ip6\e[0m"
}

function wifi(){
  ##net && neal
  networksetup -setairportpower en0 off && sleep 5 && networksetup -setairportpower en0 on
  ## && sleep 10 && net && neal
}

function lan(){ # re-written with copilot from https://apple.stackexchange.com/questions/226871/how-can-i-get-the-list-of-all-active-network-interfaces-programmatically
  while read -r line; do
    if [[ $line =~ "Hardware Port: "* ]]; then
      port=${line#*Hardware Port: }
    elif [[ $line =~ "Device: "* ]]; then
      interface=${line#*Device: }
      ip=$(ipconfig getifaddr $interface)
      if [ -n "$ip" ]; then
        echo "$port: \e[33m$ip\e[0m"
      fi
    fi
  done < <(networksetup -listallhardwareports)
}

export VISUAL="pico"
export EDITOR="pico"

# set prompt
PROMPT='%t %~❱ '

#ok let'er rip
hi
