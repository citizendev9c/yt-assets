#!/usr/bin/env bash
# Install the 24h session tools from this repo onto the VPS (run as root).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"

[ "$(id -u)" -eq 0 ] || { echo "root로 실행해 주세요."; exit 1; }
command -v tmux >/dev/null || apt-get install -y tmux

install -m 755 "$here/bin/vps-session"        /usr/local/bin/vps-session
install -m 755 "$here/bin/vps-secret"         /usr/local/bin/vps-secret
install -m 755 "$here/bin/claude-session-run" /usr/local/bin/claude-session-run
install -m 755 "$here/bin/vps-notify"         /usr/local/bin/vps-notify
install -m 644 "$here/systemd/claude-session@.service" /etc/systemd/system/claude-session@.service
# Login reminder units are installed but only turned on in SETUP 6-7 (after Telegram works).
install -m 644 "$here/systemd/claude-login-check.service" /etc/systemd/system/claude-login-check.service
install -m 644 "$here/systemd/claude-login-check.timer"   /etc/systemd/system/claude-login-check.timer
install -d -m 755 /etc/claude-vps/sessions /var/log/claude-vps /root/projects
install -d -m 700 /root/.claude/skills/24h
install -m 644 "$here/skills/24h/SKILL.md" /root/.claude/skills/24h/SKILL.md
systemctl daemon-reload

echo "설치했어요."
vps-session doctor
