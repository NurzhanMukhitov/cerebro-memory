#!/usr/bin/env bash
# Снимает снимок данных Strava (активности + статистика атлета) и пишет в
# ~/.openclaw/workspace/data/strava-snapshot.md для использования советниками Sport/Health.
# Запускать на VPS (cron раз в день или после apply-strava.sh).
# Требует: curl, jq, ~/.openclaw/strava.env с STRAVA_ACCESS_TOKEN.

set -e

ENV_FILE="${HOME}/.openclaw/strava.env"
OUT_DIR="${HOME}/.openclaw/workspace/data"
OUT_FILE="${OUT_DIR}/strava-snapshot.md"

if [ ! -f "$ENV_FILE" ]; then
  echo "Не найден $ENV_FILE. Сначала настрой Strava (apply-strava.sh)." >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$ENV_FILE"
if [ -z "${STRAVA_ACCESS_TOKEN:-}" ]; then
  echo "В $ENV_FILE не задан STRAVA_ACCESS_TOKEN." >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
API="https://www.strava.com/api/v3"

# Последние активности (до 90 штук за раз)
ACTIVITIES=$(curl -s -H "Authorization: Bearer $STRAVA_ACCESS_TOKEN" \
  "${API}/athlete/activities?per_page=60" 2>/dev/null || echo "[]")
if [ "$ACTIVITIES" = "" ] || echo "$ACTIVITIES" | jq -e '.message' >/dev/null 2>&1; then
  echo "# Снимок Strava" > "$OUT_FILE"
  echo "" >> "$OUT_FILE"
  echo "Обновлено: $(date -u +"%Y-%m-%d %H:%M UTC"). Ошибка при запросе активностей (токен истёк или нет прав). Обнови токен (см. README) и перезапусти скрипт." >> "$OUT_FILE"
  exit 0
fi

# Профиль атлета
ATHLETE=$(curl -s -H "Authorization: Bearer $STRAVA_ACCESS_TOKEN" "${API}/athlete" 2>/dev/null || echo "{}")
ATHLETE_ID=$(echo "$ATHLETE" | jq -r '.id // empty')
if [ -n "$ATHLETE_ID" ]; then
  STATS=$(curl -s -H "Authorization: Bearer $STRAVA_ACCESS_TOKEN" \
    "${API}/athletes/${ATHLETE_ID}/stats" 2>/dev/null || echo "{}")
else
  STATS="{}"
fi

# Формируем Markdown в один файл
TMP="${OUT_FILE}.tmp"
{
  echo "# Снимок Strava для советников Sport / Health"
  echo ""
  echo "Обновлено: $(date -u +"%Y-%m-%d %H:%M UTC")."
  echo ""

  # Краткая сводка по статистике (если есть)
  if [ -n "$ATHLETE_ID" ] && echo "$STATS" | jq -e '.ytd_ride_totals' >/dev/null 2>&1; then
    echo "## Сводка за год (YTD)"
    echo ""
    ytd_ride=$(echo "$STATS" | jq -r '.ytd_ride_totals.distance // 0')
    ytd_run=$(echo "$STATS" | jq -r '.ytd_run_totals.distance // 0')
    ytd_swim=$(echo "$STATS" | jq -r '.ytd_swim_totals.distance // 0')
    echo "- Велосипед: $(( ytd_ride / 1000 )) км"
    echo "- Бег: $(( ytd_run / 1000 )) км"
    echo "- Плавание: $(( ytd_swim / 1000 )) м"
    echo ""
  fi

  echo "## Последние активности"
  echo ""

  echo "$ACTIVITIES" | jq -r '
    .[] |
    "### \(.name // "Без названия")\n" +
    "- Дата: \(.start_date)\n" +
    "- Тип: \(.type // .sport_type)\n" +
    "- Дистанция: \((.distance / 1000) | floor) км\n" +
    "- Время в движении: \((.moving_time / 60) | floor) мин\n" +
    (if .total_elevation_gain and .total_elevation_gain > 0 then "- Набор высоты: \(.total_elevation_gain) м\n" else "" end) +
    (if .average_heartrate then "- Ср. пульс: \(.average_heartrate) уд/мин\n" else "" end) +
    "\n"
  ' 2>/dev/null || echo "(не удалось разобрать активности)"
} > "$TMP" && mv "$TMP" "$OUT_FILE"

echo "Снимок записан: $OUT_FILE"
