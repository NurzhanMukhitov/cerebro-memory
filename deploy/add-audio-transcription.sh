#!/bin/bash
# Добавляет в ~/.openclaw/openclaw.json секцию tools.media.audio для транскрипции голоса в Telegram.
# Запуск: на VPS под пользователем cerebro (не root).
# Требуется: jq (sudo apt install -y jq).

set -e

CONFIG="${HOME}/.openclaw/openclaw.json"

if [ ! -f "$CONFIG" ]; then
  echo "Файл не найден: $CONFIG"
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "Установите jq: sudo apt install -y jq"
  exit 1
fi

# Добавить или обновить только tools.media.audio, остальное не трогать
jq '.tools.media.audio = {
  "enabled": true,
  "maxBytes": 20971520,
  "timeoutSeconds": 120,
  "models": [
    { "provider": "openai", "model": "gpt-4o-mini-transcribe" }
  ]
}' "$CONFIG" > "${CONFIG}.tmp" && mv "${CONFIG}.tmp" "$CONFIG"

echo "Готово. Перезапустите gateway: systemctl --user restart openclaw-gateway"
