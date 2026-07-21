#!/bin/bash
# health.sh — quick system health snapshot: CPU load/temp, memory, disk free.
# Runs on macOS and Linux (Bazzite/Fedora/Ubuntu). Uses native OS commands only —
# btop has no scriptable one-shot output, so this reads sysctl/vm_stat/sensors/df/proc
# directly instead.
# https://github.com/nealrs/dotfiles

GREEN='\033[0;32m'
NC='\033[0m'

row() { printf "${GREEN}%-10s${NC} %s\n" "$1" "$2"; }
fmt_gb() { awk -v b="$1" 'BEGIN{printf "%.1fG", b/1073741824}'; }

OS="$(uname -s)"

# ============================================================
# CPU load — instantaneous busy% (matches Activity Monitor/htop), plus the
# 1m load average for reference (that's demand on the run queue, not %busy,
# and reads higher on macOS than Linux for the same actual usage).
# ============================================================
if [[ "$OS" == "Darwin" ]]; then
  cores=$(sysctl -n hw.ncpu)
  load1=$(sysctl -n vm.loadavg | awk '{print $2}')
  idle=$(top -l 1 -n 0 | awk '/CPU usage/{gsub("%","",$7); print $7}')
  busy=$(awk -v i="$idle" 'BEGIN{printf "%.0f", 100-i}')
else
  cores=$(nproc)
  load1=$(awk '{print $1}' /proc/loadavg)
  read -r _ u1 n1 s1 i1 wa1 _ < <(awk '/^cpu /{print}' /proc/stat)
  sleep 0.2
  read -r _ u2 n2 s2 i2 wa2 _ < <(awk '/^cpu /{print}' /proc/stat)
  busy=$(awk -v u1="$u1" -v n1="$n1" -v s1="$s1" -v i1="$i1" -v wa1="$wa1" \
             -v u2="$u2" -v n2="$n2" -v s2="$s2" -v i2="$i2" -v wa2="$wa2" \
    'BEGIN{
       t1=u1+n1+s1+i1+wa1; t2=u2+n2+s2+i2+wa2;
       dt=t2-t1; didle=(i2+wa2)-(i1+wa1);
       printf "%.0f", (dt>0 ? (dt-didle)/dt*100 : 0)
     }')
fi
row "CPU load" "${busy}% busy  (load avg ${load1}, ${cores} cores)"

# ============================================================
# CPU temp (silently omitted on macOS if no working tool is installed)
# ============================================================
temp=""
if [[ "$OS" == "Darwin" ]]; then
  if command -v istats &>/dev/null; then
    temp=$(istats cpu temp --value-only 2>/dev/null)
  elif command -v osx-cpu-temp &>/dev/null; then
    temp=$(osx-cpu-temp 2>/dev/null | grep -oE '[0-9]+\.[0-9]+')
  fi
  # osx-cpu-temp reports 0.0 on Apple Silicon (unsupported) — treat as missing.
  if [[ -n "$temp" ]] && awk -v t="$temp" 'BEGIN{exit !(t>0)}'; then
    row "CPU temp" "${temp}°C"
  fi
else
  if command -v sensors &>/dev/null; then
    temp=$(sensors 2>/dev/null | grep -m1 -iE 'Package id 0|Tctl|Tdie|^CPU' | grep -oE '[+-][0-9]+\.[0-9]+°C' | head -1)
  fi
  if [[ -z "$temp" && -r /sys/class/thermal/thermal_zone0/temp ]]; then
    temp=$(awk '{printf "%.1f°C", $1/1000}' /sys/class/thermal/thermal_zone0/temp)
  fi
  [[ -z "$temp" ]] && temp="n/a (install lm-sensors: sudo apt/dnf install lm-sensors && sudo sensors-detect)"
  row "CPU temp" "$temp"
fi

# ============================================================
# Memory
# ============================================================
if [[ "$OS" == "Darwin" ]]; then
  total=$(sysctl -n hw.memsize)
  page_size=$(vm_stat | awk -F'[^0-9]+' '/page size of/{print $2}')
  free_pages=$(vm_stat | awk -F'[^0-9]+' '/Pages free/{print $2}')
  inactive_pages=$(vm_stat | awk -F'[^0-9]+' '/Pages inactive/{print $2}')
  used=$(( total - (free_pages + inactive_pages) * page_size ))
else
  read -r total used <<< "$(free -b | awk '/^Mem:/{print $2, $3}')"
fi
pct_mem=$(awk -v u="$used" -v t="$total" 'BEGIN{printf "%.0f", (u/t)*100}')
row "Memory" "$(fmt_gb "$used") / $(fmt_gb "$total")  (${pct_mem}%)"

# ============================================================
# Disk (root filesystem — falls back to /var on immutable distros
# like Bazzite/Silverblue, where / is a tiny composefs/overlay
# image and df would report bogus 0-byte free space)
# ============================================================
diskpath="/"
if [[ "$OS" != "Darwin" ]]; then
  rootfs=$(findmnt -no FSTYPE / 2>/dev/null)
  [[ "$rootfs" == "composefs" || "$rootfs" == "overlay" ]] && diskpath="/var"
fi
read -r dtotal dused dfree dpct <<< "$(df -k "$diskpath" | awk 'NR==2{print $2*1024, $3*1024, $4*1024, $5}')"
row "Disk free" "$(fmt_gb "$dfree") free of $(fmt_gb "$dtotal")  (${dpct} used)"
