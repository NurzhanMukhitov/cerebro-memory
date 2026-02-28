#!/usr/bin/env bash
#
# Напоминание в Telegram за ~15 мин до начала события в календаре (khal).
# Запускать по cron каждые 5 мин, например: */5 * * * * /home/cerebro/cerebro-memory/deploy/calendar-reminder-15min.sh
#
# Требования на VPS: khal, curl. Переменные TELEGRAM_BOT_TOKEN и TELEGRAM_CHAT_ID
# задать в ~/.openclaw/calendar-reminder.env (или экспортировать перед запуском).
#
# Только «рабочие» события: по умолчанию фильтр по имени календаря (CALENDAR_FILTER).
# Оставь пустым или "*", чтобы напоминать обо всех событиях.

set -e

ENV_FILE="${HOME}/.openclaw/calendar-reminder.env"
STATE_FILE="${HOME}/.openclaw/calendar-15m-sent"
# Окно: напоминать о событиях, начинающихся через 12–18 мин (чтобы при запуске каждые 5 мин не пропустить)
MIN_MINUTES=12
MAX_MINUTES=18
# Фильтр календаря: только календари, в имени которых есть эта строка (или "*" = все). Пример: "Рабочий"
CALENDAR_FILTER="${CALENDAR_FILTER:-Рабочий}"

if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a
fi

if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
  echo "Ошибка: задайте TELEGRAM_BOT_TOKEN и TELEGRAM_CHAT_ID в $ENV_FILE или в окружении." >&2
  exit 1
fi

NOW_EPOCH=$(date +%s)
WINDOW_START=$((NOW_EPOCH + MIN_MINUTES * 60))
WINDOW_END=$((NOW_EPOCH + MAX_MINUTES * 60))

# Очистка state: удалить строки старше 2 часов (события уже прошли)
clean_state() {
  [ ! -f "$STATE_FILE" ] && return
  now_epoch=$(date +%s)
  cutoff=$((now_epoch - 7200))
  tmp=$(mktemp)
  while IFS= read -r line; do
    ep="${line%%:*}"
    [ -n "$ep" ] && [ "$ep" -gt "$cutoff" ] && echo "$line" >> "$tmp"
  done < "$STATE_FILE" 2>/dev/null || true
  mv -f "$tmp" "$STATE_FILE" 2>/dev/null || true
}

clean_state

# khal list: события в ближайшие 25 мин, одна строка на событие: "start | title | calendar"
# --day-format ' ' убирает заголовки дней (одна строка-разделитель может остаться)
khal list now 25m --format '{start} | {title} | {calendar}' --day-format ' ' 2>/dev/null | while IFS= read -r line; do
  [ -z "$line" ] && continue
  # Пропускаем строки без разделителя " | " (например заголовки)
  case "$line" in
    *" | "*" | "*) ;;
    *) continue ;;
  esac
  start_str="${line%% | *}"
  rest="${line#* | }"
  title="${rest%% | *}"
  calendar="${rest#* | }"
  # Только рабочий календарь (или все, если CALENDAR_FILTER=*)
  if [ -n "$CALENDAR_FILTER" ] && [ "$CALENDAR_FILTER" != "*" ]; then
    case "$calendar" in
      *"$CALENDAR_FILTER"*) ;;
      *) continue ;;
    esac
  fi
  start_epoch=$(date -d "$start_str" +%s 2>/dev/null || true)
  [ -z "$start_epoch" ] && continue
  if [ "$start_epoch" -ge "$WINDOW_START" ] && [ "$start_epoch" -le "$WINDOW_END" ]; then
    key="${start_epoch}:${title}"
    if [ -f "$STATE_FILE" ] && grep -qFx "$key" "$STATE_FILE" 2>/dev/null; then
      continue
    fi
    msg="⏰ Через ~15 мин: $title"
    if curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
      -d "chat_id=${TELEGRAM_CHAT_ID}" \
      --data-urlencode "text=$msg" \
      -d "disable_web_page_preview=true" >/dev/null 2>&1; then
      echo "$key" >> "$STATE_FILE"
    fi
  fi
done
