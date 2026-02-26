#!/bin/bash
# Копирование конфигурации с локальной машины на VPS
# Запуск: на локальной машине (WSL или Git Bash)

VPS_USER=cerebro
VPS_HOST=89.167.96.75

echo "Копирование ~/.openclaw на VPS..."
scp -r ~/.openclaw ${VPS_USER}@${VPS_HOST}:~/

echo "Готово. Теперь на VPS выполните phase3-config.sh"
