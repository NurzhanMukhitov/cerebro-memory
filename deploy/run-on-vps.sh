#!/usr/bin/env bash
# Запуск команды на VPS (cerebro-node-1) без передачи ключей в репо.
# Ключ только у тебя: ~/.ssh/ или Host в ~/.ssh/config (например Host cerebro-vps).
# Использование:
#   ./deploy/run-on-vps.sh "journalctl --user -u openclaw-gateway -n 100 --no-pager"
#   ./deploy/run-on-vps.sh "cd ~/cerebro-memory && git pull && systemctl --user restart openclaw-gateway"
set -e

VPS_HOST="${VPS_HOST:-89.167.96.75}"
VPS_USER="${VPS_USER:-cerebro}"

if [ $# -eq 0 ]; then
  echo "Использование: $0 \"команда на VPS\""
  echo "Пример: $0 \"journalctl --user -u openclaw-gateway -n 100 --no-pager\""
  exit 1
fi

ssh "${VPS_USER}@${VPS_HOST}" "$@"
