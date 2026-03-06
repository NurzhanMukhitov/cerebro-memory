#!/usr/bin/env bash
# Добавляет в ~/.openclaw/openclaw.json хук bootstrap-extra-files с путём data/HEARTBEAT.md.
# Запуск: на VPS — bash ~/cerebro-memory/deploy/add-health-bootstrap-hook.sh
# Требуется: jq (sudo apt install -y jq).

set -e
CFG="${OPENCLAW_CONFIG:-$HOME/.openclaw/openclaw.json}"
BACKUP="${CFG}.bak.$(date +%Y%m%d%H%M%S)"

if [ ! -f "$CFG" ]; then
  echo "Конфиг не найден: $CFG" >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "Нужен jq: sudo apt install -y jq" >&2
  exit 1
fi

cp -a "$CFG" "$BACKUP"
# Ensure hooks.internal.entries["bootstrap-extra-files"] exists with enabled and paths
jq '
  .hooks = (.hooks // {}) |
  .hooks.internal = (.hooks.internal // {}) |
  .hooks.internal.entries = (.hooks.internal.entries // {}) |
  .hooks.internal.entries["bootstrap-extra-files"] = (
    (.hooks.internal.entries["bootstrap-extra-files"] // {}) |
    .enabled = true |
    (if .paths then .paths else [] end + ["data/HEARTBEAT.md"]) as $paths |
    .paths = ($paths | unique)
  )
' "$CFG" > "${CFG}.tmp" && mv "${CFG}.tmp" "$CFG"
echo "Хук bootstrap-extra-files добавлен/обновлён в $CFG (бэкап: $BACKUP). Перезапусти gateway: systemctl --user restart openclaw-gateway"
