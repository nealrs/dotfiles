#!/usr/bin/env zsh
# cmds.sh — color-coded cheat sheet of every alias/function this repo defines.
# Reads the section banners already in .zshrc.mac/.zshrc.linux (picked by uname, so
# it's the same file that actually got symlinked to ~/.zshrc on this box) — there's no
# separate list to keep in sync, add a new "# ALIASES — foo" / "# FUNCTIONS — foo"
# banner in the zshrc and it shows up here for free. Also merges in the SSH aliases
# machines.sh generates from .machines.json, since those don't exist as literal text.
# Run via `h`.

REPOS="${REPOS:-$HOME/repos}"
[[ ! -d "$REPOS/dotfiles" && -d "$HOME/Documents/repos/dotfiles" ]] && REPOS="$HOME/Documents/repos"
DOTFILES="$REPOS/dotfiles"

if [[ "$(uname -s)" == "Darwin" ]]; then
  PLATFORM="macOS"; ZSHRC="$DOTFILES/.zshrc.mac"
else
  PLATFORM="Linux"; ZSHRC="$DOTFILES/.zshrc.linux"
fi
[[ -f "$ZSHRC" ]] || ZSHRC=~/.zshrc
if [[ ! -f "$ZSHRC" ]]; then
  echo "cmds: couldn't find a zshrc to read (looked for $ZSHRC)" >&2
  exit 1
fi

BOLD=$'\033[1m'; CYAN=$'\033[1;36m'; GREEN=$'\033[0;32m'; DIM=$'\033[2m'; NC=$'\033[0m'

# Function bodies don't carry a one-line summary the way `alias`es do, so these are
# hand-kept in sync with the README's "Aliases & functions" section — everything else
# in this script is derived straight from the zshrc, only this map is manual.
typeset -A func_desc
func_desc=(
  wan             "public IP + city/country (ipinfo.io)"
  lan             "local IP per network interface"
  net             "wan + lan together (shown at login via hi)"
  weather         "current weather (wttr.in)"
  wifi            "power-cycle Wi-Fi"
  mcd             "mkdir -p <dir> && cd into it"
  rn              "run rename.sh — normalize file names/dates"
  mo              "random line from motivation.md"
  hi              "login banner: ascii art + health + net + weather + mo"
  updatedotfiles  "git pull, regen ssh config + claude settings, re-source zshrc"
  s3              "mount/unmount toggle: connects if not mounted, asks to disconnect if it is"
  s3up            "mount an S3 bucket via s3fs (reads ~/.aws/credentials, no passwd file)"
  s3down          "unmount an s3up mount (bucket name or full path), force/lazy if busy"
)

# Same idea for aliases whose expansion doesn't explain itself (points at a script,
# or a flag/tool most people haven't memorized). Shown as "description  ->  expansion".
# Aliases not listed here just show their raw expansion, which is usually plenty
# (e.g. gs="git status" doesn't need translating).
typeset -A alias_desc
alias_desc=(
  genssh      "regenerate ~/.ssh/config from .machines.json + ssh_config.base"
  sshtrust    "print the ssh-copy-id commands to authorize this machine on every other known host"
  health      "CPU load/temp, memory, disk free — quick health snapshot"
  psg         "search running processes by name"
  dns         "flush the DNS cache"
  ll          "long listing, directories first"
  l           "short listing, all files incl. dotfiles"
  ls          "short listing, all files incl. dotfiles (same as l)"
  k           "clear the terminal"
  path        "print \$PATH one entry per line"
  json        "pretty-print JSON piped in on stdin"
  o           "open a file manager window in the current directory"
  reload      "re-source ~/.zshrc to pick up config changes"
  rel         "re-source ~/.zshrc to pick up config changes"
  resource    "re-source ~/.zshrc to pick up config changes"
  hosts       "edit /etc/hosts"
  showfiles   "show hidden files in Finder"
  hidefiles   "hide hidden files in Finder"
  ports       "list listening network ports"
  headers     "fetch just the HTTP response headers for a URL"
  web         "start a quick HTTP server in the current directory"
  ii          "connectivity check + fetch neal.rs page title"
  h           "list all aliases/functions from dotfiles with descriptions"
  copy        "copy stdin to the clipboard — pipe/redirect in, e.g. 'cat file | copy' (not 'copy file')"
  paste       "print the clipboard to stdout — redirect out, e.g. 'paste > file'"
  pbcopy      "copy stdin to the clipboard (Linux: realiased to wl-copy/xclip)"
  pbpaste     "print the clipboard to stdout (Linux: realiased to wl-paste/xclip)"
)

typeset -a order
typeset -A items   # title -> accumulated "kind\tname\tvalue\n" rows

title=""
capture=0
# banner_state: 0 = normal, 1 = just saw the divider that opens a banner (next
# line is the title), 2 = just saw the title (next divider just *closes* the
# banner box and must NOT be treated as opening a new one, or every banner's
# closing "# ====" line would immediately reset capture back off again).
banner_state=0

while IFS= read -r line; do
  if [[ "$line" =~ '^# =+$' ]]; then
    if (( banner_state == 2 )); then
      banner_state=0
    else
      banner_state=1
    fi
    continue
  fi
  if (( banner_state == 1 )); then
    banner_state=2
    if [[ "$line" == "# ALIASES"* ]]; then
      raw="${line#\# ALIASES}"
    elif [[ "$line" == "# FUNCTIONS"* ]]; then
      raw="${line#\# FUNCTIONS}"
    else
      raw=""
      capture=0
      title=""
    fi
    if [[ -n "$raw" ]]; then
      # strip the leading " — " (or " - ") separator without assuming the shell's
      # locale can regex-match the multi-byte em dash — just drop leading non-alnum bytes.
      title=$(printf '%s' "$raw" | sed -E 's/^[^A-Za-z0-9]+//')
      if [[ -z "${items[$title]+x}" ]]; then
        order+=("$title")
        items[$title]=""
      fi
      capture=1
    fi
    continue
  fi
  (( capture )) || continue

  if [[ "$line" =~ 'alias ([A-Za-z0-9_.-]+)=(.*)$' ]]; then
    name="${match[1]}"
    val="${match[2]}"
    case "$val" in
      \"*) val="${val#\"}"; val="${val%\"}" ;;
      \'*) val="${val#\'}"; val="${val%\'}" ;;
    esac
    if [[ -n "${alias_desc[$name]}" ]]; then
      val="${alias_desc[$name]}  ->  ${val}"
    fi
    items[$title]+="alias	${name}	${val}"$'\n'
  elif [[ "$line" =~ '^function ([A-Za-z0-9_]+)\(\)' ]] || [[ "$line" =~ '^([A-Za-z0-9_]+)\(\) *\{' ]]; then
    name="${match[1]}"
    items[$title]+="function	${name}	${func_desc[$name]}"$'\n'
  fi
done < "$ZSHRC"

# Merge in the SSH aliases/functions machines.sh generates from .machines.json —
# they don't exist as literal `alias` lines anywhere, so the scan above can't see them.
if [[ -f "$DOTFILES/machines.sh" ]]; then
  typeset -A pre_aliases
  pre_aliases=(${(kv)aliases})
  source "$DOTFILES/machines.sh" "$DOTFILES/.machines.json"
  ssh_title="ssh / places"
  if [[ -z "${items[$ssh_title]+x}" ]]; then
    order+=("$ssh_title")
    items[$ssh_title]=""
  fi
  for k in ${(k)aliases}; do
    [[ -n "${pre_aliases[$k]+x}" ]] && continue
    items[$ssh_title]+="alias	${k}	${aliases[$k]}"$'\n'
  done
  [[ -n "${functions[tssh]}" ]] && items[$ssh_title]+="function	tssh	<name> — ssh to any host in .machines.json over tailscale"$'\n'
fi

printf "\n${BOLD}dotfiles commands${NC}  ${DIM}(%s — %s)${NC}\n" "$PLATFORM" "$ZSHRC"

for t in "${order[@]}"; do
  [[ -z "${items[$t]}" ]] && continue
  printf "\n${BOLD}${CYAN}%s${NC}\n" "$t"
  while IFS=$'\t' read -r kind name val; do
    [[ -z "$kind" ]] && continue
    if [[ "$kind" == "function" ]]; then
      printf "  ${GREEN}%-16s${NC} ${DIM}%s${NC}\n" "${name}()" "$val"
    else
      printf "  ${GREEN}%-16s${NC} ${DIM}%s${NC}\n" "$name" "$val"
    fi
  done <<< "${items[$t]}"
done

printf "\n${DIM}Full source: %s${NC}\n\n" "$ZSHRC"
