#!/bin/bash
# Фаза 1: Базовая подготовка сервера
# Запуск: на VPS после ssh root@89.167.96.75

set -e

echo "=== Фаза 1: Подготовка сервера ==="

# 1.1 Обновление системы
apt update && apt upgrade -y

# 1.2 Создание пользователя cerebro (интерактивно — ввести пароль)
if ! id cerebro &>/dev/null; then
  adduser cerebro
  usermod -aG sudo cerebro
  echo "Пользователь cerebro создан."
else
  echo "Пользователь cerebro уже существует."
fi

# 1.3 Firewall
ufw allow 22/tcp
ufw --force enable

echo "=== Фаза 1 завершена ==="
echo "Далее: скопируйте SSH-ключ с локальной машины:"
echo "  ssh-copy-id cerebro@89.167.96.75"
echo "Затем переключитесь на пользователя cerebro: su - cerebro"
