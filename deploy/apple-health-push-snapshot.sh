#!/usr/bin/env bash
# Вариант 1: Загрузить на VPS готовый снимок Apple Health (ручной экспорт).
#   ./deploy/apple-health-push-snapshot.sh путь/к/apple-health-snapshot.md
# Вариант 2: Если на Mac установлен healthsync CLI и iPhone привязан — выгрузить
#   последние 7 дней и отправить на VPS автоматически.
#   ./deploy/apple-health-push-snapshot.sh
#
# VPS: deploy/run-on-vps.sh (VPS_HOST, VPS_USER). Файл на VPS: ~/.openclaw/workspace/data/apple-health-snapshot.md

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VPS_HOST="${VPS_HOST:-89.167.96.75}"
VPS_USER="${VPS_USER:-cerebro}"
REMOTE_PATH="${VPS_USER}@${VPS_HOST}:~/.openclaw/workspace/data/apple-health-snapshot.md"

if [ -n "${1:-}" ]; then
  # Передан путь к файлу — просто копируем на VPS
  if [ ! -f "$1" ]; then
    echo "Файл не найден: $1" >&2
    exit 1
  fi
  echo "Создаю каталог на VPS (если нет) и копирую $1..."
  ssh "${VPS_USER}@${VPS_HOST}" "mkdir -p ~/.openclaw/workspace/data"
  scp "$1" "$REMOTE_PATH"
  echo "Готово. Снимок на VPS: ~/.openclaw/workspace/data/apple-health-snapshot.md"
  exit 0
fi

# Пытаемся использовать healthsync (если есть)
if ! command -v healthsync >/dev/null 2>&1; then
  echo "healthsync не найден в PATH."
  echo ""
  echo "Ручной способ:"
  echo "  1. Экспортируй данные из приложения «Здоровье» (Экспорт) или через приложение вроде HealthExport (CSV)."
  echo "  2. Составь краткий текст (сон, шаги, пульс за последние дни) и сохрани в файл, например apple-health-snapshot.md"
  echo "  3. Загрузи на VPS: $0 путь/к/apple-health-snapshot.md"
  echo ""
  echo "Автоматический способ (Mac + iPhone в одной Wi‑Fi):"
  echo "  Установи healthsync CLI и приложение для iPhone (см. README, раздел Apple Health), привяжи устройство, затем снова запусти: $0"
  exit 1
fi

# Выгружаем последние 7 дней
END_ISO=$(date -u +"%Y-%m-%dT23:59:59Z")
START_ISO=$(date -u -v-7d +"%Y-%m-%dT00:00:00Z" 2>/dev/null || date -u -d "7 days ago" +"%Y-%m-%dT00:00:00Z")
TYPES="steps,heartRate,heartRateVariability,sleepAnalysis,activeEnergyBurned,workouts"

echo "Запрашиваю данные за последние 7 дней (healthsync)..."
JSON=$(healthsync fetch --start "$START_ISO" --end "$END_ISO" --types "$TYPES" --format json 2>/dev/null) || true

if [ -z "$JSON" ] || [ "$JSON" = "[]" ]; then
  echo "Не удалось получить данные (проверь привязку: healthsync status)." >&2
  echo "Используй ручную загрузку: $0 путь/к/файлу.md" >&2
  exit 1
fi

# Собираем простой Markdown (если есть jq)
TMP=$(mktemp)
if command -v jq >/dev/null 2>&1; then
  {
    echo "# Снимок Apple Health"
    echo ""
    echo "Обновлено: $(date -u +"%Y-%m-%d %H:%M UTC"). Период: последние 7 дней."
    echo ""
    echo "$JSON" | jq -r '
      if type == "array" then .[] else . end |
      "## \(.type // .dataType // "data")\n\(.value // .values // .) — \(.startDate // .date // "")\n" 
    ' 2>/dev/null || echo "$JSON"
  } > "$TMP"
else
  echo "# Снимок Apple Health" > "$TMP"
  echo "" >> "$TMP"
  echo "Обновлено: $(date -u +"%Y-%m-%d %H:%M UTC")." >> "$TMP"
  echo "" >> "$TMP"
  echo '```json' >> "$TMP"
  echo "$JSON" >> "$TMP"
  echo '```' >> "$TMP"
fi

echo "Копирую снимок на VPS..."
ssh "${VPS_USER}@${VPS_HOST}" "mkdir -p ~/.openclaw/workspace/data"
scp "$TMP" "$REMOTE_PATH"
rm -f "$TMP"
echo "Готово. Снимок на VPS: ~/.openclaw/workspace/data/apple-health-snapshot.md"
