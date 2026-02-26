#!/bin/bash
# Фаза 4: Headless Chrome (Playwright)
# Запуск: на VPS под пользователем cerebro

set -e

echo "=== Фаза 4: Headless Chrome ==="

# 4.1 Установка Playwright и Chromium
npm install -g playwright 2>/dev/null || npm install playwright
npx playwright install chromium
npx playwright install-deps chromium

# 4.2 Skill — через бота или clawdhub
echo "Установите skill Headless Chrome через Telegram-бота:"
echo "  'Установи skill Headless Chrome из Claw Hub'"
echo "Или: clawdhub install headless-chrome (если доступно)"

# 4.3 Проверка RAM
echo "=== Использование RAM после установки ==="
free -h

echo "=== Фаза 4 завершена ==="
