#!/usr/bin/env bash
# Добавляет в crontab на Mac задание: каждый день в 21:00 запускать
# apple-health-push-snapshot.sh (снимок Apple Health на VPS).
# Запускать из корня репо: ./deploy/setup-apple-health-cron.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CRON_CMD="cd $REPO_ROOT && ./deploy/apple-health-push-snapshot.sh"
CRON_LINE="0 21 * * * $CRON_CMD"

if crontab -l 2>/dev/null | grep -q "apple-health-push-snapshot.sh"; then
  echo "Задание для apple-health-push-snapshot.sh уже есть в crontab."
  crontab -l | grep "apple-health-push-snapshot"
  exit 0
fi

(crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab -
echo "Добавлено: каждый день в 21:00 — $CRON_CMD"
echo "Проверка: crontab -l"
