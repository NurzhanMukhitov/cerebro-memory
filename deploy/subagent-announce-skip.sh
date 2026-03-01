#!/bin/bash
# Отключает отправку в чат служебного сообщения «Subagent finished / Готово: отправил сообщение в Telegram»
# после срабатывания напоминаний и других subagent-задач. Пользователь видит только результат (например,
# текст напоминания), без дубликата «Готово: messageId=...».
#
# Добавляет в ~/.openclaw/openclaw.json:
#   agents.defaults.subagents.announce = "skip"
#
# Требуется OpenClaw с поддержкой announce (PR #13303 или новее). В версии 2026.2.25 ключ
# НЕ поддерживается: после добавления gateway падает с "Unrecognized key: announce".
# Удалить ключ вручную: jq 'del(.agents.defaults.subagents.announce)' ~/.openclaw/openclaw.json > ...tmp && mv ...tmp ~/.openclaw/openclaw.json
# Затем: systemctl --user restart openclaw-gateway
#
# Запуск: на VPS под пользователем cerebro. Требуется jq.

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

# Добавить agents.defaults.subagents.announce = "skip", не затирая остальные ключи
jq '
  .agents = ((.agents // {}) | .defaults = ((.defaults // {}) | .subagents = ((.subagents // {}) + {"announce": "skip"})))
' "$CONFIG" > "${CONFIG}.tmp" && mv "${CONFIG}.tmp" "$CONFIG"

echo "Готово. В конфиг добавлено: agents.defaults.subagents.announce = \"skip\""
echo "Перезапустите gateway: systemctl --user restart openclaw-gateway"
