# ssh_agent_init.sh — start or reuse a persistent ssh-agent, across shells
# AND across separate SSH login sessions, instead of spawning a fresh one
# (and re-prompting for the id_ed25519 passphrase) every single time a
# shell starts. POSIX-compatible — works sourced from bash or zsh.
#
# The agent, once spawned, daemonizes and keeps running independently of
# the shell/session that started it (standard ssh-agent behavior) — this
# script just remembers how to reconnect to it via a small env file, and
# only starts a new one if that agent is actually gone (e.g. after a
# reboot). Reused across shells in the SAME session works either way; this
# is what makes it also work across separate SSH logins.
#
# Sourced automatically by .zshrc.linux. To get the same behavior in bash
# (so `git pull`/`git push` don't prompt either), add this to ~/.profile
# (~/.profile runs for SSH login shells; ~/.bashrc alone would not):
#
#   for d in "$HOME/repos/dotfiles" "$HOME/Documents/repos/dotfiles"; do
#     [ -f "$d/ssh_agent_init.sh" ] && . "$d/ssh_agent_init.sh" && break
#   done

SSH_AGENT_ENV="$HOME/.ssh/agent.env"
[ -f "$SSH_AGENT_ENV" ] && . "$SSH_AGENT_ENV" > /dev/null

ssh-add -l >/dev/null 2>&1
case $? in
  1) ssh-add ~/.ssh/id_ed25519 2>/dev/null ;;                 # agent reachable, key not loaded yet
  2) eval "$(ssh-agent -s | tee "$SSH_AGENT_ENV")" > /dev/null  # no agent reachable — start + persist
     chmod 600 "$SSH_AGENT_ENV"
     ssh-add ~/.ssh/id_ed25519 2>/dev/null ;;
esac
