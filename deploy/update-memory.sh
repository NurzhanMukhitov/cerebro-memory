#!/bin/bash
# Обновление cerebro-memory на VPS
# Запуск: на VPS под пользователем cerebro (вручную или по cron/systemd timer)

set -e

REPO=~/cerebro-memory
LOG=~/cerebro-memory-update.log

if [ ! -d "$REPO" ]; then
  echo "$(date -Iseconds): ERROR: $REPO not found" >> "$LOG" 2>/dev/null || true
  exit 1
fi

cd "$REPO"
if ! git pull >> "$LOG" 2>&1; then
  echo "$(date -Iseconds): git pull failed, see $LOG" >> "$LOG" 2>&1
  exit 1
fi

# Опционально: перезапуск gateway для немедленной подтяжки манифеста/профиля
# Раскомментируйте, если нужен авто-рестарт после каждого pull:
# if systemctl --user is-active --quiet openclaw-gateway 2>/dev/null; then
#   systemctl --user restart openclaw-gateway
# fi

echo "$(date -Iseconds): OK" >> "$LOG"
