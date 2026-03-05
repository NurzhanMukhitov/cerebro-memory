#!/usr/bin/env bash
#
# Вечерний health check‑in в Telegram.
# Идея: раз в день в фиксированное время бот задаёт вопрос про сон, питание и тренировки за сегодня.
# Ответ пользователя агент использует как ручной лог (папка health/) вместе с данными Apple Health / Strava / Ultrahuman.
#
# Запускать по cron один раз в день, например:
#   30 21 * * * /home/cerebro/cerebro-memory/deploy/health-evening-checkin.sh
#
# Требования на VPS: curl.
# Переменные TELEGRAM_BOT_TOKEN и TELEGRAM_CHAT_ID задать в ~/.openclaw/health-checkin.env
# (тот же бот и чат, что у gateway), опционально TEXT_OVERRIDE для полного переопределения текста сообщения.

set -e

ENV_FILE="${HOME}/.openclaw/health-checkin.env"

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

TODAY="$(date +%Y-%m-%d)"

# Проверяем, есть ли свежие данные Health/Strava за сегодня (по наличию свежего apple-health-snapshot.md).
# Это грубая эвристика: если снимок сегодня не обновлялся, считаем, что синхронизация не прошла.
APPLE_SNAPSHOT="${HOME}/.openclaw/workspace/data/apple-health-snapshot.md"
HAS_TODAY_SENSORS=0
if [ -f "$APPLE_SNAPSHOT" ]; then
  # mtime файла в формате YYYY-MM-DD (GNU stat на VPS)
  SNAPSHOT_DATE=$(stat -c %y "$APPLE_SNAPSHOT" 2>/dev/null | awk '{print $1}' || true)
  if [ "$SNAPSHOT_DATE" = "$TODAY" ]; then
    HAS_TODAY_SENSORS=1
  fi
fi

BASE_HEADER=$'🩺 Вечерний health check‑in\n\n'
BASE_HEADER+="$TODAY\n\n"

if [ "$HAS_TODAY_SENSORS" -eq 1 ]; then
  # Вариант 2: датчики есть, просим только субъективку/питание/детали
  DEFAULT_TEXT="$BASE_HEADER"
  DEFAULT_TEXT+=$'Хочу зафиксировать твой день в журнале здоровья.\n'
  DEFAULT_TEXT+=$'Напиши коротко:\n'
  DEFAULT_TEXT+=$'– как спалось и как себя чувствуешь сейчас;\n'
  DEFAULT_TEXT+=$'– что сегодня ел;\n'
  DEFAULT_TEXT+=$'– что было по активности/тренировкам, что стоит отметить.\n'
else
  # Вариант 2 (частично или сбой синка): данных Health/Strava за сегодня нет, просим базовые цифры
  DEFAULT_TEXT="$BASE_HEADER"
  DEFAULT_TEXT+=$'Похоже, сегодня синхронизация с датчиками прошла не полностью (данные Health/Strava за день не вижу).\n'
  DEFAULT_TEXT+=$'Чтобы не терять день в статистике, напиши, пожалуйста:\n'
  DEFAULT_TEXT+=$'– сон (время, длительность, качество);\n'
  DEFAULT_TEXT+=$'– активность/тренировки (что делал и сколько примерно);\n'
  DEFAULT_TEXT+=$'– если были необычные ощущения или симптомы.\n'
fi

TEXT="${TEXT_OVERRIDE:-$DEFAULT_TEXT}"

curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -d "chat_id=${TELEGRAM_CHAT_ID}" \
  --data-urlencode "text=${TEXT}" \
  -d "disable_web_page_preview=true" >/dev/null 2>&1 || {
  echo "Не удалось отправить сообщение в Telegram." >&2
  exit 1
}

