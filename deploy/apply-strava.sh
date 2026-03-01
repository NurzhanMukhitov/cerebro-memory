#!/usr/bin/env bash
# Копирует deploy/strava.env на VPS в ~/.openclaw/strava.env и выставляет права.
# Перед запуском: скопируй strava.env.example в strava.env и заполни значения.
# Использует VPS_HOST и VPS_USER из run-on-vps.sh (по умолчанию cerebro@89.167.96.75).

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$SCRIPT_DIR/strava.env"

VPS_HOST="${VPS_HOST:-89.167.96.75}"
VPS_USER="${VPS_USER:-cerebro}"

if [ ! -f "$ENV_FILE" ]; then
  echo "Файл $ENV_FILE не найден."
  echo "Скопируй: cp deploy/strava.env.example deploy/strava.env"
  echo "Заполни в strava.env: STRAVA_CLIENT_ID, STRAVA_CLIENT_SECRET, STRAVA_ACCESS_TOKEN, STRAVA_REFRESH_TOKEN"
  exit 1
fi

echo "Копирую strava.env на VPS..."
scp "$ENV_FILE" "${VPS_USER}@${VPS_HOST}:~/.openclaw/strava.env"

echo "Права на VPS..."
ssh "${VPS_USER}@${VPS_HOST}" 'chmod 600 ~/.openclaw/strava.env'

if ! ssh "${VPS_USER}@${VPS_HOST}" 'grep -q "strava.env" ~/.config/systemd/user/openclaw-gateway.service 2>/dev/null'; then
  echo "Внимание: в unit gateway ещё нет EnvironmentFile для strava.env."
  echo "Добавь в ~/.config/systemd/user/openclaw-gateway.service строку: EnvironmentFile=%h/.openclaw/strava.env"
  echo "Затем на VPS: systemctl --user daemon-reload && systemctl --user restart openclaw-gateway"
else
  echo "Перезапуск gateway на VPS..."
  ssh "${VPS_USER}@${VPS_HOST}" 'systemctl --user daemon-reload && systemctl --user restart openclaw-gateway'
  echo "Готово. Strava env применён, gateway перезапущен."
fi
