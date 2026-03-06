#!/usr/bin/env bash
# Обновляет data/HEARTBEAT.md в workspace из data/apple-health-snapshot.md.
# HEARTBEAT.md — допустимое имя для bootstrap-extra-files; при подключении в openclaw.json
# этот файл подгружается в контекст при каждом запросе, и бот «видит» данные о здоровье без вызова read.
# Запуск: на VPS — bash ~/cerebro-memory/deploy/update-health-bootstrap.sh
# Рекомендуется: cron после заливки снимка или раз в час.

set -e
WS="${OPENCLAW_WS:-$HOME/.openclaw/workspace}"
SNAPSHOT="$WS/data/apple-health-snapshot.md"
OUT="$WS/data/HEARTBEAT.md"
MAX_LINES=100

if [ ! -f "$SNAPSHOT" ]; then
  echo "Нет файла $SNAPSHOT — сначала залей снимок (apple-health-push-snapshot.sh с Mac)." >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT")"
{
  echo "# Health data (bootstrap)"
  echo ""
  echo "Данные из Apple Health за последние дни (срез для контекста агента). При вопросе о здоровье использовать эти данные."
  echo ""
  head -n "$MAX_LINES" "$SNAPSHOT"
  echo ""
  echo "[... полный снимок в data/apple-health-snapshot.md ]"
} > "$OUT"
echo "Обновлён $OUT ($(wc -c < "$OUT") байт)"
