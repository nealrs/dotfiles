# kewtie — Ubuntu 22.04 desktop install, but reachable only via SSH; nobody
# is ever logged into the console. gdm3 (+ its Mutter/Xwayland login greeter)
# sits idle at ~200-400MB RAM for zero benefit on a box already running ~20
# Docker containers (Home Assistant, AdGuard, zigbee2mqtt, etc.).
#
# Independent of Docker: gdm3 lives under graphical.target, Docker under
# multi-user.target — none of this touches any container. Also independent
# of your SSH session: gdm3 owns the local graphical seat (seat0), your SSH
# login is a separate logind session — stopping/disabling gdm3 cannot lock
# you out over SSH.
#
# Recommended path: gdmoff now (no reboot needed to run it, doesn't stop
# anything today), let it take effect on kewtie's next natural reboot.

# Check current boot target + whether gdm3 is enabled/running (read-only)
alias gdmcheck='systemctl get-default; systemctl is-enabled gdm3; systemctl status gdm3 --no-pager'

# See everything graphical.target actually pulls in, before touching anything
alias gdmdeps='systemctl list-dependencies graphical.target'

# Apply: boot headless from now on. Takes effect on next reboot only —
# does NOT stop gdm3 today, does NOT require a reboot to run this command.
alias gdmoff='sudo systemctl set-default multi-user.target'

# Rollback: restore the graphical boot target (also next-reboot only)
alias gdmon='sudo systemctl set-default graphical.target'

# Optional: stop gdm3 immediately instead of waiting for a reboot, if you
# want the RAM back today. Safe over SSH (see above).
alias gdmstop='sudo systemctl stop gdm3'
alias gdmstart='sudo systemctl start gdm3'

# After gdmstop/gdmoff, verify nothing else broke:
alias gdmverify='systemctl --failed; echo ---; docker ps'
