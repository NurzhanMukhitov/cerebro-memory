#!/bin/bash
# Подготовка песочницы (второй бот) на VPS
# Запуск: на VPS под пользователем cerebro (не root)

set -e

echo "=== Подготовка песочницы Cerebro ==="

SANDBOX_WS=~/.openclaw/workspace-sandbox
SANDBOX_ENV=~/.openclaw/sandbox.env
REPO=~/cerebro-memory
USER_UNIT_DIR=~/.config/systemd/user
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Каталог workspace-sandbox
mkdir -p "$SANDBOX_WS"
echo "Каталог $SANDBOX_WS создан или уже есть."

# 2. Симлинки на манифест и профиль из cerebro-memory
if [ -f "$REPO/core/manifest.md" ]; then
  ln -sf "$REPO/core/manifest.md" "$SANDBOX_WS/SOUL.md"
  ln -sf "$REPO/core/manifest.md" "$SANDBOX_WS/BOOTSTRAP.md"
  echo "SOUL.md и BOOTSTRAP.md → cerebro-memory/core/manifest.md"
fi
if [ -f "$REPO/core/user-profile.md" ]; then
  ln -sf "$REPO/core/user-profile.md" "$SANDBOX_WS/USER.md"
  echo "USER.md → cerebro-memory/core/user-profile.md"
fi

# 3. Файл для токена (шаблон)
if [ ! -f "$SANDBOX_ENV" ]; then
  echo "TELEGRAM_BOT_TOKEN=ПОДСТАВЬ_ТОКЕН_СЮДА" > "$SANDBOX_ENV"
  chmod 600 "$SANDBOX_ENV"
  echo "Создан $SANDBOX_ENV — подставь токен второго бота и сохрани файл."
else
  echo "Файл $SANDBOX_ENV уже есть — проверь, что в нём правильный токен."
fi

# 4. Systemd user unit
mkdir -p "$USER_UNIT_DIR"
if [ -f "$SCRIPT_DIR/openclaw-gateway-sandbox.service" ]; then
  cp "$SCRIPT_DIR/openclaw-gateway-sandbox.service" "$USER_UNIT_DIR/openclaw-gateway-sandbox.service"
  echo "Юнит скопирован в $USER_UNIT_DIR/openclaw-gateway-sandbox.service"
else
  echo "ВНИМАНИЕ: openclaw-gateway-sandbox.service не найден в $SCRIPT_DIR"
  echo "Скопируй вручную из ~/cerebro-memory/deploy/ в $USER_UNIT_DIR/"
fi

systemctl --user daemon-reload
echo "systemctl --user daemon-reload выполнен."

echo ""
echo "--- Следующие шаги ---"
echo "1. Открой на VPS файл: nano ~/.openclaw/sandbox.env"
echo "   Замени ПОДСТАВЬ_ТОКЕН_СЮДА на токен второго бота из BotFather."
echo "   Токен в чат и в git не вставляй — только в этот файл на VPS."
echo ""
echo "2. Запусти песочницу:"
echo "   systemctl --user start openclaw-gateway-sandbox"
echo "   (опционально автозапуск: systemctl --user enable openclaw-gateway-sandbox)"
echo ""
echo "3. В Telegram открой второго бота и выполни pairing (как для прод-бота)."
echo ""
echo "4. Skills в песочницу ставишь отдельно: cd $SANDBOX_WS && clawhub install <skill>"
echo ""
