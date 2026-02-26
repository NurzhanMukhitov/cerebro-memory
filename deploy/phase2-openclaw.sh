#!/bin/bash
# Фаза 2: Установка OpenClaw
# Запуск: на VPS под пользователем cerebro (su - cerebro)

set -e

echo "=== Фаза 2: Установка OpenClaw ==="

# 2.1 Установка
curl -fsSL https://openclaw.ai/install.sh | bash

# 2.2 Инициализация
openclaw init

# 2.3 Onboarding (интерактивно) — установит демон
echo "Запуск onboarding. Выберите: модель (Codex/OpenAI), Telegram, Skills — Skip."
openclaw onboard --install-daemon

# 2.4 Проверка RAM
echo "=== Использование RAM ==="
free -h

echo "=== Фаза 2 завершена ==="
