#!/bin/bash
# Фаза 5: Whisper (голос → текст)
# Запуск: на VPS под пользователем cerebro

set -e

echo "=== Фаза 5: Whisper ==="

# Рекомендуемый вариант: openai-whisper-api (облако, без нагрузки на RAM)
# https://clawhub.ai/steipete/openai-whisper-api
echo "Рекомендуется: openai-whisper-api (OpenAI API, платно, 0 RAM на VPS)."
echo "  cd ~/.openclaw/workspace && npx clawhub install openai-whisper-api"
echo "  Задать OPENAI_API_KEY: в ~/.openclaw/workspace/openclaw.json (skills.openai-whisper-api.apiKey)"
echo "  или export OPENAI_API_KEY=sk-..."
echo ""

# Локальный вариант (тяжёлый: PyTorch, много RAM; возможен OOM на малых VPS)
if command -v npx &>/dev/null; then
  echo "Локальный вариант (если нужен): npx clawhub install faster-whisper или tg-voice-whisper."
else
  echo "Установите skill через Telegram-бота: 'Установи skill openai-whisper-api'"
fi

# Проверка RAM
echo "=== Использование RAM ==="
free -h

echo "=== Фаза 5 завершена ==="
echo "После установки openai-whisper-api: systemctl --user restart openclaw-gateway"
