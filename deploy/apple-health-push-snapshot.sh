#!/usr/bin/env bash
# Вариант 1: Загрузить на VPS готовый снимок (ручной экспорт).
#   ./deploy/apple-health-push-snapshot.sh путь/к/файлу.md
# Вариант 2: healthsync — по умолчанию последние 7 дней → apple-health-snapshot.md (для ежедневного cron).
#   ./deploy/apple-health-push-snapshot.sh
# Вариант 3: Один раз выгрузить 3 месяца (базовый снимок для трендов) → apple-health-baseline.md.
#   APPLE_HEALTH_BASELINE=90 ./deploy/apple-health-push-snapshot.sh
#
# На VPS: ~/.openclaw/workspace/data/apple-health-snapshot.md (свежие 7 дн.) и apple-health-baseline.md (долгая история, вручную).

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VPS_HOST="${VPS_HOST:-89.167.96.75}"
VPS_USER="${VPS_USER:-cerebro}"
DATA_DIR="~/.openclaw/workspace/data"

if [ -n "${1:-}" ]; then
  # Передан путь к файлу — копируем на VPS как apple-health-snapshot.md
  if [ ! -f "$1" ]; then
    echo "Файл не найден: $1" >&2
    exit 1
  fi
  echo "Создаю каталог на VPS (если нет) и копирую $1..."
  ssh "${VPS_USER}@${VPS_HOST}" "mkdir -p $DATA_DIR"
  scp "$1" "${VPS_USER}@${VPS_HOST}:${DATA_DIR}/apple-health-snapshot.md"
  echo "Готово. Файл на VPS: ${DATA_DIR}/apple-health-snapshot.md"
  exit 0
fi

# Пытаемся использовать healthsync (если есть)
if ! command -v healthsync >/dev/null 2>&1; then
  echo "healthsync не найден в PATH."
  echo ""
  echo "Ручной способ: экспорт из «Здоровье» → файл → $0 путь/к/файлу.md"
  echo "Автоматический: установи healthsync и приложение HealthSync Helper, привяжи iPhone, затем снова запусти: $0"
  exit 1
fi

# Режим: базовый снимок (3 мес) или ежедневный (7 дней)
if [ -n "${APPLE_HEALTH_BASELINE:-}" ]; then
  DAYS="${APPLE_HEALTH_BASELINE}"
  REMOTE_FILE="apple-health-baseline.md"
  echo "Режим: базовый снимок за $DAYS дней → apple-health-baseline.md"
else
  DAYS="${APPLE_HEALTH_DAYS:-7}"
  REMOTE_FILE="apple-health-snapshot.md"
  echo "Режим: последние $DAYS дней → apple-health-snapshot.md"
fi

END_ISO=$(date -u +"%Y-%m-%dT23:59:59Z")
if [ "$DAYS" -gt 90 ] 2>/dev/null; then
  START_ISO=$(date -u -v-${DAYS}d +"%Y-%m-%dT00:00:00Z" 2>/dev/null || date -u -d "$DAYS days ago" +"%Y-%m-%dT00:00:00Z")
  AGGREGATE="--aggregate daily"
  echo "Запрашиваю данные за $DAYS дней с агрегацией по дням (healthsync)..."
else
  START_ISO=$(date -u -v-${DAYS}d +"%Y-%m-%dT00:00:00Z" 2>/dev/null || date -u -d "$DAYS days ago" +"%Y-%m-%dT00:00:00Z")
  AGGREGATE=""
  echo "Запрашиваю данные за последние $DAYS дней (healthsync)..."
fi
TYPES="steps,heartRate,heartRateVariability,sleepAnalysis,activeEnergyBurned,workouts,weight,bodyMassIndex,bodyFatPercentage,leanBodyMass"

JSON=$(healthsync fetch --start "$START_ISO" --end "$END_ISO" --types "$TYPES" $AGGREGATE --format json 2>/tmp/healthsync-err.txt) || true
if [ -s /tmp/healthsync-err.txt ]; then
  echo "healthsync fetch ошибка:" >&2
  cat /tmp/healthsync-err.txt >&2
fi

if [ -z "$JSON" ] || [ "$JSON" = "[]" ]; then
  echo "Не удалось получить данные. Проверь: healthsync status (приложение на iPhone открыто? та же Wi‑Fi?). Ручная загрузка: $0 путь/к/файлу.md" >&2
  exit 1
fi

# Собираем Markdown
TMP=$(mktemp)
if command -v jq >/dev/null 2>&1; then
  {
    echo "# Снимок Apple Health"
    echo ""
    echo "Обновлено: $(date -u +"%Y-%m-%d %H:%M UTC"). Период: последние $DAYS дней."
    echo ""
    echo "$JSON" | jq -r '
      if type == "array" then .[] else . end |
      "## \(.type // .dataType // "data")\n\(.value // .values // .) — \(.startDate // .date // "")\n"
    ' 2>/dev/null || echo "$JSON"
  } > "$TMP"
else
  echo "# Снимок Apple Health" > "$TMP"
  echo "" >> "$TMP"
  echo "Обновлено: $(date -u +"%Y-%m-%d %H:%M UTC"). Период: $DAYS дней." >> "$TMP"
  echo "" >> "$TMP"
  echo '```json' >> "$TMP"
  echo "$JSON" >> "$TMP"
  echo '```' >> "$TMP"
fi

REMOTE_PATH="${VPS_USER}@${VPS_HOST}:${DATA_DIR}/${REMOTE_FILE}"
echo "Копирую на VPS: $REMOTE_FILE ..."
ssh "${VPS_USER}@${VPS_HOST}" "mkdir -p $DATA_DIR"
scp "$TMP" "$REMOTE_PATH"
rm -f "$TMP"
echo "Готово. Файл на VPS: ${DATA_DIR}/${REMOTE_FILE}"
