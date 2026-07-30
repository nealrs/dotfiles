# Login banners for `hi` (see shell_common.sh).
#
# Most machine names just need their name rendered in the house font
# (DiamFont — https://patorjk.com/software/taag/#p=display&f=DiamFont) in
# green. diamond_banner() below generates that programmatically from the
# font's own glyph table, so a new machine needs zero art.
#
# This file is for the exceptions: a machine whose banner should say
# something other than its literal hostname (define banner_<hostname> to
# override — e.g. a machine named "dingus" that should render "DIRTBAG"
# would get `function banner_dingus(){ diamond_banner "DIRTBAG"; }` here),
# plus one-off art that isn't DiamFont at all.

# --- generic DiamFont renderer ---
# Glyph table transcribed from DiamFont.flf (patorjk's FIGlet font editor
# export). "$" is the font's hardblank marker: it prints as a space but
# counts as ink for kerning, matching FIGlet's "Horizontal Fitting" layout
# (this font's only layout mode — no character smushing).
typeset -gA DIAMOND_GLYPH
DIAMOND_GLYPH[A]=$' ▗▄▖ \n▐▌ ▐▌\n▐▛▀▜▌\n▐▌ ▐▌\n     \n     \n     '
DIAMOND_GLYPH[B]=$'▗▄▄▖ \n▐▌ ▐▌\n▐▛▀▚▖\n▐▙▄▞▘\n     \n     \n     '
DIAMOND_GLYPH[C]=$' ▗▄▄▖\n▐▌   \n▐▌   \n▝▚▄▄▖\n     \n     \n     '
DIAMOND_GLYPH[D]=$'▗▄▄▄  \n▐▌  █$\n▐▌  █$\n▐▙▄▄▀$\n      \n      \n      '
DIAMOND_GLYPH[E]=$'▗▄▄▄▖\n▐▌   \n▐▛▀▀▘\n▐▙▄▄▖\n     \n     \n     '
DIAMOND_GLYPH[F]=$'▗▄▄▄▖\n▐▌   \n▐▛▀▀▘\n▐▌   \n     \n     \n     '
DIAMOND_GLYPH[G]=$' ▗▄▄▖\n▐▌   \n▐▌▝▜▌\n▝▚▄▞▘\n     \n     \n     '
DIAMOND_GLYPH[H]=$'▗▖ ▗▖\n▐▌ ▐▌\n▐▛▀▜▌\n▐▌ ▐▌\n     \n     \n     '
DIAMOND_GLYPH[I]=$'▗▄▄▄▖\n  █  \n  █  \n▗▄█▄▖\n     \n     \n     '
DIAMOND_GLYPH[J]=$'   ▗▖\n   ▐▌\n   ▐▌\n▗▄▄▞▘\n     \n     \n     '
DIAMOND_GLYPH[K]=$'▗▖ ▗▖\n▐▌▗▞▘\n▐▛▚▖ \n▐▌ ▐▌\n     \n     \n     '
DIAMOND_GLYPH[L]=$'▗▖   \n▐▌   \n▐▌   \n▐▙▄▄▖\n     \n     \n     '
DIAMOND_GLYPH[M]=$'▗▖  ▗▖\n▐▛▚▞▜▌\n▐▌  ▐▌\n▐▌  ▐▌\n      \n      \n      '
DIAMOND_GLYPH[N]=$'▗▖  ▗▖\n▐▛▚▖▐▌\n▐▌ ▝▜▌\n▐▌  ▐▌\n      \n      \n      '
DIAMOND_GLYPH[O]=$' ▗▄▖ \n▐▌ ▐▌\n▐▌ ▐▌\n▝▚▄▞▘\n     \n     \n     '
DIAMOND_GLYPH[P]=$'▗▄▄▖ \n▐▌ ▐▌\n▐▛▀▘ \n▐▌   \n     \n     \n     '
DIAMOND_GLYPH[Q]=$'▗▄▄▄▖ \n▐▌ ▐▌ \n▐▌ ▐▌ \n▐▙▄▟▙▖\n      \n      \n      '
DIAMOND_GLYPH[R]=$'▗▄▄▖ \n▐▌ ▐▌\n▐▛▀▚▖\n▐▌ ▐▌\n     \n     \n     '
DIAMOND_GLYPH[S]=$' ▗▄▄▖\n▐▌   \n ▝▀▚▖\n▗▄▄▞▘\n     \n     \n     '
DIAMOND_GLYPH[T]=$'▗▄▄▄▖\n  █  \n  █  \n  █  \n     \n     \n     '
DIAMOND_GLYPH[U]=$'▗▖ ▗▖\n▐▌ ▐▌\n▐▌ ▐▌\n▝▚▄▞▘\n     \n     \n     '
DIAMOND_GLYPH[V]=$'▗▖  ▗▖\n▐▌  ▐▌\n▐▌  ▐▌\n ▝▚▞▘ \n      \n      \n      '
DIAMOND_GLYPH[W]=$'▗▖ ▗▖\n▐▌ ▐▌\n▐▌ ▐▌\n▐▙█▟▌\n     \n     \n     '
DIAMOND_GLYPH[X]=$'▗▖  ▗▖\n ▝▚▞▘ \n  ▐▌  \n▗▞▘▝▚▖\n      \n      \n      '
DIAMOND_GLYPH[Y]=$'▗▖  ▗▖\n ▝▚▞▘ \n  ▐▌  \n  ▐▌  \n      \n      \n      '
DIAMOND_GLYPH[Z]=$'▗▄▄▄▄▖\n   ▗▞▘\n ▗▞▘  \n▐▙▄▄▄▖\n      \n      \n      '
DIAMOND_GLYPH[0]=$'▄▀▀▚▖\n█  ▐▌\n█  ▐▌\n▀▄▄▞▘\n     \n     \n     '
DIAMOND_GLYPH[1]=$'█$\n█$\n█$\n█$\n  \n  \n  '
DIAMOND_GLYPH[2]=$'▄▄▄▄$\n   █$\n█▀▀▀$\n█▄▄▄$\n     \n     \n     '
DIAMOND_GLYPH[3]=$'▄▄▄▄$\n   █$\n▀▀▀█$\n▄▄▄█$\n     \n     \n     '
DIAMOND_GLYPH[4]=$'▄  ▗▖\n█  ▐▌\n▀▀▀▜▌\n   ▐▌\n     \n     \n     '
DIAMOND_GLYPH[5]=$'▄▄▄▄$\n█    \n▀▀▀█$\n▄▄▄█$\n     \n     \n     '
DIAMOND_GLYPH[6]=$'▄▄▄▄$\n█    \n█▀▀█$\n█▄▄█$\n     \n     \n     '
DIAMOND_GLYPH[7]=$'▗▄▄▄▖\n   ▐▌\n   ▐▌\n   ▐▌\n     \n     \n     '
DIAMOND_GLYPH[8]=$'▄▄▄▄$\n█  █$\n█▀▀█$\n█▄▄█$\n     \n     \n     '
DIAMOND_GLYPH[9]=$'▄▄▄▄$\n█  █$\n▀▀▀█$\n▄▄▄█$\n     \n     \n     '

# REPLY := count of leading/trailing literal spaces in $1 (character-based,
# so it's safe on the multibyte box-drawing glyphs above).
function _diamond_blank_run(){
  local s="$1" edge="$2" n=0 i len=${#1}
  if [[ "$edge" == head ]]; then
    for (( i = 1; i <= len; i++ )); do
      [[ "${s[$i]}" == ' ' ]] || break
      (( n++ ))
    done
  else
    for (( i = len; i >= 1; i-- )); do
      [[ "${s[$i]}" == ' ' ]] || break
      (( n++ ))
    done
  fi
  REPLY=$n
}

# diamond_banner TEXT — render TEXT in DiamFont, green, kerned like FIGlet's
# "Horizontal Fitting" layout. Unknown characters (no glyph above) are
# skipped rather than erroring, so a stray digit/symbol degrades gracefully.
function diamond_banner(){
  emulate -L zsh
  local text="${(U)1}"
  local -a canvas g
  local i ch row overlap tb lb w L trimlen newrow
  local have_first=0

  for (( i = 1; i <= ${#text}; i++ )); do
    ch="${text[$i]}"
    [[ -n "${DIAMOND_GLYPH[$ch]}" ]] || continue
    g=("${(@f)DIAMOND_GLYPH[$ch]}")

    if (( ! have_first )); then
      canvas=("${g[@]}")
      have_first=1
      continue
    fi

    overlap=-1
    for row in 1 2 3 4 5 6 7; do
      _diamond_blank_run "${canvas[$row]}" tail; tb=$REPLY
      _diamond_blank_run "${g[$row]}" head; lb=$REPLY
      (( overlap == -1 || tb + lb < overlap )) && overlap=$(( tb + lb ))
    done
    w=${#g[1]}
    (( overlap > w )) && overlap=$w

    for row in 1 2 3 4 5 6 7; do
      L=${#canvas[$row]}
      trimlen=$(( L - overlap ))
      if (( trimlen <= 0 )); then
        newrow="${g[$row]}"
      else
        newrow="${canvas[$row][1,$trimlen]}${g[$row]}"
      fi
      canvas[$row]="$newrow"
    done
  done

  # Trailing rows are blank for every glyph in this font (baseline sits at
  # row 4) — drop them so the banner isn't padded with empty lines.
  local last=${#canvas}
  while (( last > 0 )) && [[ -z "${canvas[$last]// /}" ]]; do
    (( last-- ))
  done

  for row in "${canvas[@]:0:$last}"; do
    printf "\e[32m%s\e[0m\n" "${row//\$/ }"
  done
}

# --- exceptions / one-off art ---

function banner_spokenlayer (){
  printf $LCYAN;
  printf "                         __                    .__                                   \n";
  printf "  ____________    ____  |  | __  ____    ____  |  |  _____    ___.__.  ____  _______ \n";
  printf " /  ___/\____ \  /  _ \ |  |/ /_/ __ \  /    \ |  |  \__  \  <   |  |_/ __ \ \_  __ \\"; printf "\n";
  printf " \___ \ |  |_> >(  <_> )|    < \  ___/ |   |  \|  |__ / __ \_ \___  |\  ___/  |  | \/\n";
  printf "/____  >|   __/  \____/ |__|_ \ \___  >|___|  /|____/(____  / / ____| \___  > |__|   \n";
  printf "     \/ |__|                 \/     \/      \/            \/  \/          \/         \n\n";
  printf $RESTORE;
}

function banner_audicus_orig(){
  echo -e "\e[33m                                   \e[0m";
  echo -e "\e[32m █████╗ ██╗   ██╗██████╗ ██╗ ██████╗██╗   ██╗███████╗\e[0m";
  echo -e "\e[32m██╔══██╗██║   ██║██╔══██╗██║██╔════╝██║   ██║██╔════╝\e[0m";
  echo -e "\e[32m███████║██║   ██║██║  ██║██║██║     ██║   ██║███████╗\e[0m";
  echo -e "\e[32m██╔══██║██║   ██║██║  ██║██║██║     ██║   ██║╚════██║\e[0m";
  echo -e "\e[32m██║  ██║╚██████╔╝██████╔╝██║╚██████╗╚██████╔╝███████║\e[0m";
  echo -e "\e[32m╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝\e[0m";
}

function banner_kewtie_orig(){
  printf "\e[42m\e[30m                                                \e[0m\n"
  printf "\n";
  printf "██╗  ██╗███████╗██╗    ██╗████████╗██╗███████╗\n"
  printf "██║ ██╔╝██╔════╝██║    ██║╚══██╔══╝██║██╔════╝\n"
  printf "█████╔╝ █████╗  ██║ █╗ ██║   ██║   ██║█████╗  \n"
  printf "██╔═██╗ ██╔══╝  ██║███╗██║   ██║   ██║██╔══╝  \n"
  printf "██║  ██╗███████╗╚███╔███╔╝   ██║   ██║███████╗\n"
  printf "╚═╝  ╚═╝╚══════╝ ╚══╝╚══╝    ╚═╝   ╚═╝╚══════╝\n"
  printf "\n";
  printf "\e[42m\e[30m                                                \e[0m\n"
}

function banner_goober(){
  echo "\e[32m                  ▄▄                \e[0m";
  echo "\e[32m                  ██                \e[0m";
  echo "\e[32m▄████ ▄███▄ ▄███▄ ████▄ ▄█▀█▄ ████▄ \e[0m";
  echo "\e[32m██ ██ ██ ██ ██ ██ ██ ██ ██▄█▀ ██ ▀▀ \e[0m";
  echo "\e[32m▀████ ▀███▀ ▀███▀ ████▀ ▀█▄▄▄ ██    \e[0m";
  echo "\e[32m   ██                               \e[0m";
  echo "\e[32m ▀▀▀                                \e[0m";
}

#https://patorjk.com/software/taag/#p=display&f=Future+Smooth&t=ibanez&x=none&v=4&h=4&w=80&we=false
function banner_ibanez(){
  echo "\e[32m╷╭╮ ╭─╮╭╮╷╭─╴╶─╮\e[0m";
  echo "\e[32m│├┴╮├─┤│╰┤├╴ ╭─╯\e[0m";
  echo "\e[32m╵╰─╯╵ ╵╵ ╵╰─╴╰─╴\e[0m";

  #echo "\e[32m╻┏┓ ┏━┓┏┓╻┏━╸╺━┓\e[0m";
  #echo "\e[32m┃┣┻┓┣━┫┃┗┫┣╸ ┏━┛\e[0m";
  #echo "\e[32m╹┗━┛╹ ╹╹ ╹┗━╸┗━╸\e[0m";
}

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
