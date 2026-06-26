#!/usr/bin/env bash
# rename — normalize markdown, txt, and PDF filenames to YYYY-MM-DD-kebab-case.{ext}
#
# Markdown/txt: date from filename, falls back to first heading/line with a date
# PDF:          date from filename only; falls back to slug-only if no date found
# All types:    if no date found anywhere, still kebab-cases the title (SLUG)
#
# Usage:
#   rn              # current dir, non-recursive
#   rn -r           # current dir, recursive
#   rn -n           # dry-run
#   rn -r -n        # recursive dry-run
#   rn -h           # help

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
if [ -t 1 ]; then
  GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'
  CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
else
  GREEN=''; YELLOW=''; RED=''; CYAN=''; BOLD=''; NC=''
fi

# ── Defaults ──────────────────────────────────────────────────────────────────
DRY_RUN=true
RECURSIVE=false
YES=false
EXPLICIT_N=false
TARGET_DIR="$(pwd)"

# ── Args ──────────────────────────────────────────────────────────────────────
usage() {
  echo -e "${BOLD}rn${NC} — normalize markdown, txt, and PDF filenames to YYYY-MM-DD-kebab-case"
  echo ""
  echo "Usage: rn [-r] [-y] [-n] [-h] [directory]"
  echo ""
  echo "  -r    Recurse into subdirectories"
  echo "  -y    Apply without confirmation prompt"
  echo "  -n    Dry run only — print changes, no prompt"
  echo "  -h    Show this help"
  echo "  dir   Target directory (default: current directory)"
  exit 0
}

while getopts ":rynh" opt; do
  case $opt in
    r) RECURSIVE=true ;;
    y) YES=true ;;
    n) DRY_RUN=true; EXPLICIT_N=true ;;    # preview only, no prompt
    h) usage ;;
    \?) echo -e "${RED}Unknown flag: -${OPTARG}${NC}" >&2; exit 1 ;;
  esac
done
shift $((OPTIND - 1))
[ $# -gt 0 ] && TARGET_DIR="$1"

if [ ! -d "$TARGET_DIR" ]; then
  echo -e "${RED}Error:${NC} '$TARGET_DIR' is not a directory" >&2
  exit 1
fi

# ── Counters ──────────────────────────────────────────────────────────────────
RENAMED=0; SKIPPED=0; ALREADY_OK=0; CONFLICTS=0

# ── Helpers ───────────────────────────────────────────────────────────────────

slugify() {
  echo "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed "s/'//g" \
    | sed 's/[^a-z0-9 _-]//g' \
    | sed 's/[[:space:]_]/-/g' \
    | sed 's/-\{2,\}/-/g' \
    | sed 's/^-//; s/-$//'
}

# _pad: zero-pad a number to 2 digits
_pad() { printf '%02d' "$((10#$1))"; }

# _valid_date: sanity-check extracted values (month 1-12, day 1-31)
_valid_date() {
  local y="$1" m="$2" d="$3"
  [ "$y" -ge 2000 ] && [ "$y" -le 2099 ] || return 1
  [ "$m" -ge 1   ] && [ "$m" -le 12   ] || return 1
  [ "$d" -ge 1   ] && [ "$d" -le 31   ] || return 1
  return 0
}

# Map month name/abbrev → number (must be defined before extract_date)
_month_num() {
  case "$(echo "$1" | tr '[:upper:]' '[:lower:]')" in
    jan*) echo 1  ;; feb*) echo 2  ;; mar*) echo 3  ;;
    apr*) echo 4  ;; may)  echo 5  ;; jun*) echo 6  ;;
    jul*) echo 7  ;; aug*) echo 8  ;; sep*) echo 9  ;;
    oct*) echo 10 ;; nov*) echo 11 ;; dec*) echo 12 ;;
    *) echo "" ;;
  esac
}

# Sets EXTRACTED_YEAR/MONTH/DAY; returns 0 on success.
# Handles separators: - _ / .
# Handles padding: zero-padded or bare (2-6-2026, 2026-2-6)
# Handles year-first (ISO) and year-last (US) orders
# Handles named months in prose: "June 5, 2026" / "5th June 2026" / etc.
# Ambiguity rule: year-last + both fields ≤12 → treat first=month (US convention)
extract_date() {
  local s="$1"
  EXTRACTED_YEAR=""; EXTRACTED_MONTH=""; EXTRACTED_DAY=""
  local SEP='[-_/. ]'            # includes space: "05 14 2025"
  local Y='(20[0-9]{2})'
  local YY='([0-9]{2})'         # 2-digit year, will be expanded to 20YY
  local N='([0-9]{1,2})'
  local f1 f2 f3 raw tokens

  # ── 1. YYYY-?-?  (year first, any padding, any separator) ──────────────────
  if echo "$s" | grep -qE "${Y}${SEP}${N}${SEP}${N}"; then
    raw=$(echo "$s" | grep -oE "${Y}${SEP}${N}${SEP}${N}" | head -1)
    tokens=$(echo "$raw" | sed 's/[-_.\/]/ /g')
    read -r f1 f2 f3 <<< "$tokens"
    if _valid_date "$f1" "$f2" "$f3"; then
      EXTRACTED_YEAR="$f1"
      EXTRACTED_MONTH=$(_pad "$f2")
      EXTRACTED_DAY=$(_pad "$f3")
      return 0
    fi
  fi

  # ── 2. ?-?-YYYY  (year last, any padding, any separator) ───────────────────
  if echo "$s" | grep -qE "${N}${SEP}${N}${SEP}${Y}"; then
    raw=$(echo "$s" | grep -oE "${N}${SEP}${N}${SEP}${Y}" | head -1)
    tokens=$(echo "$raw" | sed 's/[-_.\/]/ /g')
    read -r f1 f2 f3 <<< "$tokens"
    # f3=year, f1=month, f2=day (US convention)
    if _valid_date "$f3" "$f1" "$f2"; then
      EXTRACTED_YEAR="$f3"
      EXTRACTED_MONTH=$(_pad "$f1")
      EXTRACTED_DAY=$(_pad "$f2")
      return 0
    fi
  fi

  # ── 3. ?-?-YY  (2-digit year last, expanded to 20YY) ──────────────────────
  # Tried before year-first: recent files more likely MM-DD-YY than YY-MM-DD
  if echo "$s" | grep -qE "(^|[^0-9])${N}${SEP}${N}${SEP}${YY}([^0-9]|$)"; then
    raw=$(echo "$s" | grep -oE "(^|[^0-9])${N}${SEP}${N}${SEP}${YY}([^0-9]|$)" | head -1 \
          | grep -oE '[0-9]{1,2}[-_/.][0-9]{1,2}[-_/.][0-9]{2}')
    tokens=$(echo "$raw" | sed 's/[-_.\/]/ /g')
    read -r f1 f2 f3 <<< "$tokens"
    f3="20${f3}"
    if _valid_date "$f3" "$f1" "$f2"; then
      EXTRACTED_YEAR="$f3"; EXTRACTED_MONTH=$(_pad "$f1"); EXTRACTED_DAY=$(_pad "$f2")
      return 0
    fi
  fi

  # ── 4. YY-?-?  (2-digit year first, expanded to 20YY) ─────────────────────
  if echo "$s" | grep -qE "(^|[^0-9])${YY}${SEP}${N}${SEP}${N}([^0-9]|$)"; then
    raw=$(echo "$s" | grep -oE "(^|[^0-9])${YY}${SEP}${N}${SEP}${N}([^0-9]|$)" | head -1 \
          | grep -oE '[0-9]{2}[-_/.][0-9]{1,2}[-_/.][0-9]{1,2}')
    tokens=$(echo "$raw" | sed 's/[-_.\/]/ /g')
    read -r f1 f2 f3 <<< "$tokens"
    f1="20${f1}"
    if _valid_date "$f1" "$f2" "$f3"; then
      EXTRACTED_YEAR="$f1"; EXTRACTED_MONTH=$(_pad "$f2"); EXTRACTED_DAY=$(_pad "$f3")
      return 0
    fi
  fi

  # ── 5. Named month — prose in H1 headings ──────────────────────────────────
  # "June 5, 2026" / "Jun 5th 2026" / "June 5 2026"
  local MONTHS='(Jan(uary)?|Feb(ruary)?|Mar(ch)?|Apr(il)?|May|Jun(e)?|Jul(y)?|Aug(ust)?|Sep(tember)?|Oct(ober)?|Nov(ember)?|Dec(ember)?)'
  if echo "$s" | grep -iqE "${MONTHS}[,. _]+([0-9]{1,2})(st|nd|rd|th)?[,. _]+20[0-9]{2}"; then
    raw=$(echo "$s" | grep -oiE "${MONTHS}[,. _]+([0-9]{1,2})(st|nd|rd|th)?[,. _]+20[0-9]{2}" | head -1)
    local mname dy yr mn
    mname=$(echo "$raw" | grep -oiE '^[A-Za-z]+')
    dy=$(echo "$raw"    | grep -oE '[0-9]{1,2}' | head -1)
    yr=$(echo "$raw"    | grep -oE '20[0-9]{2}')
    mn=$(_month_num "$mname")
    if [ -n "$mn" ] && _valid_date "$yr" "$mn" "$dy"; then
      EXTRACTED_YEAR="$yr"; EXTRACTED_MONTH=$(_pad "$mn"); EXTRACTED_DAY=$(_pad "$dy")
      return 0
    fi
  fi

  # "5 June 2026" / "5th June, 2026"
  if echo "$s" | grep -iqE "([0-9]{1,2})(st|nd|rd|th)?[,. _]+${MONTHS}[,. _]+20[0-9]{2}"; then
    raw=$(echo "$s" | grep -oiE "([0-9]{1,2})(st|nd|rd|th)?[,. _]+${MONTHS}[,. _]+20[0-9]{2}" | head -1)
    local mname dy yr mn
    dy=$(echo "$raw"    | grep -oE '^[0-9]+')
    # Skip leading digits+ordinal, then grab first alpha word of 3+ chars (the month name)
    mname=$(echo "$raw" | sed 's/^[0-9]*\(st\|nd\|rd\|th\)*[,. _]*//' | grep -oiE '^[A-Za-z]{3,}')
    yr=$(echo "$raw"    | grep -oE '20[0-9]{2}')
    mn=$(_month_num "$mname")
    if [ -n "$mn" ] && _valid_date "$yr" "$mn" "$dy"; then
      EXTRACTED_YEAR="$yr"; EXTRACTED_MONTH=$(_pad "$mn"); EXTRACTED_DAY=$(_pad "$dy")
      return 0
    fi
  fi

  # ── 6. Named month + 2-digit year: "May 13 25" / "May 13, 25" ──────────────
  if echo "$s" | grep -iqE "${MONTHS}[,. _]+([0-9]{1,2})(st|nd|rd|th)?[,. _]+[0-9]{2}([^0-9]|$)"; then
    raw=$(echo "$s" | grep -oiE "${MONTHS}[,. _]+([0-9]{1,2})(st|nd|rd|th)?[,. _]+[0-9]{2}" | head -1)
    local mname dy yr mn
    mname=$(echo "$raw" | grep -oiE '^[A-Za-z]+')
    dy=$(echo "$raw"    | grep -oE '[0-9]{1,2}' | head -1)
    yr="20$(echo "$raw" | grep -oE '[0-9]{2}$')"
    mn=$(_month_num "$mname")
    if [ -n "$mn" ] && _valid_date "$yr" "$mn" "$dy"; then
      EXTRACTED_YEAR="$yr"; EXTRACTED_MONTH=$(_pad "$mn"); EXTRACTED_DAY=$(_pad "$dy")
      return 0
    fi
  fi

  return 1
}

# Remove the date token from a string, leaving just the name portion.
# Handles all separator types, padded and unpadded, named months.
strip_date() {
  local s="$1"
  # YYYY[-_/. ]?[-_/. ]? (year first, unpadded ok, space sep ok)
  s=$(echo "$s" | sed 's/20[0-9][0-9][-_\/. ][0-9]\{1,2\}[-_\/. ][0-9]\{1,2\}[-_\/. ]*//g')
  # ?[-_/. ]?[-_/. ]YYYY (year last, unpadded ok, space sep ok)
  s=$(echo "$s" | sed 's/[0-9]\{1,2\}[-_\/. ][0-9]\{1,2\}[-_\/. ]20[0-9][0-9][-_\/. ]*//g')
  # YY[-_/. ]?[-_/. ] (2-digit year first, space sep ok)
  s=$(echo "$s" | sed 's/[0-9]\{2\}[-_\/. ][0-9]\{1,2\}[-_\/. ][0-9]\{1,2\}[-_\/. ]*//g')
  # ?[-_/. ]?[-_/. ]YY (2-digit year last, space sep ok)
  s=$(echo "$s" | sed 's/[0-9]\{1,2\}[-_\/. ][0-9]\{1,2\}[-_\/. ][0-9]\{2\}[-_\/. ]*//g')
  # Named month, month-first, 4-digit year: "June 5, 2026" / "Jun 5th 2026"
  s=$(echo "$s" | sed 's/[A-Za-z]\{3,9\}[,. _]*[0-9]\{1,2\}\(st\|nd\|rd\|th\)*[,. _]*20[0-9][0-9][,. _]*//g')
  # Named month, day-first, 4-digit year: "5th June 2026"
  s=$(echo "$s" | sed 's/[0-9]\{1,2\}\(st\|nd\|rd\|th\)*[,. _]*[A-Za-z]\{3,9\}[,. _]*20[0-9][0-9][,. _]*//g')
  # Named month, month-first, 2-digit year: "May 13 25"
  s=$(echo "$s" | sed 's/[A-Za-z]\{3,9\}[,. _]*[0-9]\{1,2\}\(st\|nd\|rd\|th\)*[,. _]*[0-9]\{2\}[,. _]*//g')
  # Lowercase and clean up
  echo "$s" | tr '[:upper:]' '[:lower:]'
}

# Prompt user y/n/s(kip all) for a conflict; sets CONFLICT_CHOICE
SKIP_ALL_CONFLICTS=false
prompt_conflict() {
  local src="$1" dst="$2"
  # In dry-run we never actually need to ask
  if [ "$DRY_RUN" = true ]; then
    CONFLICT_CHOICE="skip"
    return
  fi
  if [ "$SKIP_ALL_CONFLICTS" = true ]; then
    CONFLICT_CHOICE="skip"
    return
  fi
  echo -e "${YELLOW}CONFLICT${NC} $(basename "$src")"
  echo -e "         target already exists: $(basename "$dst")"
  printf  "         Overwrite? [y]es / [s]kip / [S]kip all: "
  local reply
  read -r reply </dev/tty
  case "$reply" in
    y|Y) CONFLICT_CHOICE="overwrite" ;;
    S)   SKIP_ALL_CONFLICTS=true; CONFLICT_CHOICE="skip" ;;
    *)   CONFLICT_CHOICE="skip" ;;
  esac
}

# ── Core file processor (markdown + txt) ──────────────────────────────────────
# $1 = filepath, $2 = extension (md or txt)
# For md:  H1 fallback requires "# " prefix
# For txt: H1 fallback reads first non-empty line (no prefix required)
process_text_file() {
  local filepath="$1"
  local ext="$2"
  local dir; dir=$(dirname "$filepath")
  local base; base=$(basename "$filepath" ".$ext")

  local year month day slug newname newpath date_source=""

  # 1. Try date from filename
  if extract_date "$base"; then
    year="$EXTRACTED_YEAR"; month="$EXTRACTED_MONTH"; day="$EXTRACTED_DAY"
    local name_part; name_part=$(strip_date "$base")
    slug=$(slugify "$name_part")
    date_source="filename"

  # 2. Fall back to first heading/line with a date
  else
    local first_line
    if [ "$ext" = "md" ]; then
      first_line=$(grep -m1 '^# ' "$filepath" 2>/dev/null | sed 's/^# //' || true)
    else
      first_line=$(grep -m1 '.' "$filepath" 2>/dev/null || true)
    fi
    # Reject obvious placeholders
    if echo "$first_line" | grep -qiE '(\{\{|\[date\]|YYYY|MM[-_/]DD|date.*here)'; then
      echo -e "${YELLOW}SKIP${NC}    $filepath  (template placeholder in heading)"
      SKIPPED=$((SKIPPED + 1))
      return
    fi
    if [ -n "$first_line" ] && extract_date "$first_line"; then
      year="$EXTRACTED_YEAR"; month="$EXTRACTED_MONTH"; day="$EXTRACTED_DAY"
      local line_name; line_name=$(strip_date "$first_line")
      if [ -n "$(echo "$line_name" | tr -d '[:space:]-')" ]; then
        slug=$(slugify "$line_name")
      else
        slug=$(slugify "$base")
      fi
      date_source="heading"
    else
      # No date anywhere — still kebab-case the title if it would change
      slug=$(slugify "$base")
      if [ -z "$slug" ]; then
        echo -e "${YELLOW}SKIP${NC}    $filepath  (no date and no slug)"
        SKIPPED=$((SKIPPED + 1))
        return
      fi
      date_source="slug-only"
    fi
  fi

  # Build target name
  if [ "$date_source" = "slug-only" ]; then
    newname="${slug}.${ext}"
  else
    newname="${year}-${month}-${day}"
    [ -n "$slug" ] && newname="${newname}-${slug}"
    newname="${newname}.${ext}"
  fi
  newpath="${dir}/${newname}"

  # Already correct
  if [ "$(basename "$filepath")" = "$newname" ]; then
    echo -e "${CYAN}OK${NC}      $filepath"
    ALREADY_OK=$((ALREADY_OK + 1))
    return
  fi

  # Conflict: target exists and is a different file
  if [ -e "$newpath" ] && [ "$filepath" != "$newpath" ]; then
    prompt_conflict "$filepath" "$newpath"
    if [ "$CONFLICT_CHOICE" = "skip" ]; then
      echo -e "${RED}CONFLICT${NC} $filepath  →  $newname  (skipped)"
      CONFLICTS=$((CONFLICTS + 1))
      return
    fi
    # overwrite: fall through to mv
  fi

  local label="RENAME"
  [ "$date_source" = "heading" ]   && label="RENAME*"
  echo -e "${GREEN}${label}${NC}  $filepath  →  $newname"

  if [ "$DRY_RUN" = false ]; then
    mv -- "$filepath" "$newpath"
  fi
  RENAMED=$((RENAMED + 1))
}

# ── Core file processor (PDF) ─────────────────────────────────────────────────
process_pdf() {
  local filepath="$1"
  local dir; dir=$(dirname "$filepath")
  local base; base=$(basename "$filepath" .pdf)

  local year month day slug newname newpath date_source=""

  if extract_date "$base"; then
    year="$EXTRACTED_YEAR"; month="$EXTRACTED_MONTH"; day="$EXTRACTED_DAY"
    local name_part; name_part=$(strip_date "$base")
    slug=$(slugify "$name_part")
    date_source="filename"
  else
    slug=$(slugify "$base")
    if [ -z "$slug" ]; then
      echo -e "${YELLOW}SKIP${NC}    $filepath  (no date and no slug)"
      SKIPPED=$((SKIPPED + 1))
      return
    fi
    date_source="slug-only"
  fi

  if [ "$date_source" = "slug-only" ]; then
    newname="${slug}.pdf"
  else
    newname="${year}-${month}-${day}"
    [ -n "$slug" ] && newname="${newname}-${slug}"
    newname="${newname}.pdf"
  fi
  newpath="${dir}/${newname}"

  if [ "$(basename "$filepath")" = "$newname" ]; then
    echo -e "${CYAN}OK${NC}      $filepath"
    ALREADY_OK=$((ALREADY_OK + 1))
    return
  fi

  if [ -e "$newpath" ] && [ "$filepath" != "$newpath" ]; then
    prompt_conflict "$filepath" "$newpath"
    if [ "$CONFLICT_CHOICE" = "skip" ]; then
      echo -e "${RED}CONFLICT${NC} $filepath  →  $newname  (skipped)"
      CONFLICTS=$((CONFLICTS + 1))
      return
    fi
  fi

  local label="RENAME"
  echo -e "${GREEN}${label}${NC}  $filepath  →  $newname"
  if [ "$DRY_RUN" = false ]; then
    mv -- "$filepath" "$newpath"
  fi
  RENAMED=$((RENAMED + 1))
}

# ── Main ──────────────────────────────────────────────────────────────────────
echo ""
[ "$RECURSIVE" = true ] && echo -e "${CYAN}RECURSIVE${NC} mode"
echo -e "Scanning: ${BOLD}$(cd "$TARGET_DIR" && pwd)${NC}"
echo "────────────────────────────────────────"

FIND_DEPTH="-maxdepth 1"
[ "$RECURSIVE" = true ] && FIND_DEPTH=""

# ── Preview pass (always dry-run) ─────────────────────────────────────────────
DRY_RUN=true
while IFS= read -r -d '' file; do
  process_text_file "$file" "md"
done < <(/usr/bin/find "$TARGET_DIR" $FIND_DEPTH -name "*.md" -type f -print0 | sort -z)

while IFS= read -r -d '' file; do
  process_text_file "$file" "txt"
done < <(/usr/bin/find "$TARGET_DIR" $FIND_DEPTH -name "*.txt" -type f -print0 | sort -z)

while IFS= read -r -d '' file; do
  process_pdf "$file"
done < <(/usr/bin/find "$TARGET_DIR" $FIND_DEPTH -name "*.pdf" -type f -print0 | sort -z)

echo "────────────────────────────────────────"
echo -e "Would rename: ${GREEN}${RENAMED}${NC}  |  Already OK: ${CYAN}${ALREADY_OK}${NC}  |  Skip: ${YELLOW}${SKIPPED}${NC}$([ "$CONFLICTS" -gt 0 ] && echo "  |  Conflicts: ${RED}${CONFLICTS}${NC}" || true)"
echo -e "  ${CYAN}*${NC} RENAME* = date from heading/first line"
echo ""

# ── Nothing to do ─────────────────────────────────────────────────────────────
if [ "$RENAMED" -eq 0 ]; then
  echo -e "${CYAN}Nothing to rename.${NC}"
  echo ""
  exit 0
fi

# ── Dry-run only (-n): stop here ──────────────────────────────────────────────
if [ "$YES" = false ] && [ "${EXPLICIT_N:-false}" = true ]; then
  exit 0
fi

# ── Confirm ───────────────────────────────────────────────────────────────────
if [ "$YES" = false ]; then
  printf "Apply these %d rename(s)? [y/N] " "$RENAMED"
  read -r reply </dev/tty
  [[ "$reply" =~ ^[Yy]$ ]] || { echo "Aborted."; echo ""; exit 0; }
fi

# ── Apply pass ────────────────────────────────────────────────────────────────
echo ""
DRY_RUN=false
RENAMED=0; SKIPPED=0; ALREADY_OK=0; CONFLICTS=0
SKIP_ALL_CONFLICTS=false

while IFS= read -r -d '' file; do
  process_text_file "$file" "md"
done < <(/usr/bin/find "$TARGET_DIR" $FIND_DEPTH -name "*.md" -type f -print0 | sort -z)

while IFS= read -r -d '' file; do
  process_text_file "$file" "txt"
done < <(/usr/bin/find "$TARGET_DIR" $FIND_DEPTH -name "*.txt" -type f -print0 | sort -z)

while IFS= read -r -d '' file; do
  process_pdf "$file"
done < <(/usr/bin/find "$TARGET_DIR" $FIND_DEPTH -name "*.pdf" -type f -print0 | sort -z)

echo "────────────────────────────────────────"
echo -e "Renamed: ${GREEN}${RENAMED}${NC}  |  Skipped: ${YELLOW}${SKIPPED}${NC}$([ "$CONFLICTS" -gt 0 ] && echo "  |  Conflicts: ${RED}${CONFLICTS}${NC}" || true)"
echo ""
