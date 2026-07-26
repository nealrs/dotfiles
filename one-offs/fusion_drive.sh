# Check if the HDD is visible (ROTA=1 means spinning disk)
alias diskcheck='lsblk -d -o NAME,ROTA,SIZE,MODEL'

# Manually spin down + remove sda from kernel if it reappears
alias nofusion='sudo /usr/bin/hdparm -Y /dev/sda && echo 1 | sudo tee /sys/block/sda/device/delete'

# iMac 2019 Fusion Drive — HDD (/dev/sda) has 65k bad sectors and will crash the machine.

# Permanent fix: /etc/udev/rules.d/99-no-poll-sda.rules
#   ACTION=="add", KERNEL=="sda", SUBSYSTEM=="block", ENV{UDISKS_AUTO}="0", ENV{UDISKS_IGNORE}="1", RUN+="/bin/sh -c '/usr/bin/hdparm -Y /dev/sda; echo 1 > /sys/block/sda/device/delete'"
# If sda shows up again (use diskcheck), run nuke-hdd to remove it without rebooting.
