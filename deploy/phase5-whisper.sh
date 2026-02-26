#!/bin/bash
# Фаза 5: Whisper
# Запуск: на VPS под пользователем cerebro

set -e

echo "=== Фаза 5: Whisper ==="

# Вариант B: faster-whisper (локально)
if command -v clawdhub &>/dev/null; then
  clawdhub install faster-whisper
else
  echo "Установите skill faster-whisper через Telegram-бота:"
  echo "  'Установи skill faster-whisper'"
fi

# Проверка RAM
echo "=== Использование RAM ==="
free -h

echo "=== Фаза 5 завершена ==="
echo "Альтернатива: Whisper API в openclaw.json — 0 RAM, платно."
