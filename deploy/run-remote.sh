#!/bin/bash
# Запуск развёртывания на VPS с локальной машины
# Требует: SSH-доступ к root@89.167.96.75

set -e
VPS=root@89.167.96.75
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Копирование скриптов на VPS..."
scp "$SCRIPT_DIR"/phase*.sh "$VPS":/root/

echo "Запуск Фазы 1 на VPS..."
ssh "$VPS" "chmod +x /root/phase1-server-setup.sh && /root/phase1-server-setup.sh"

echo ""
echo "Фаза 1 завершена. Далее:"
echo "  1. ssh-copy-id cerebro@89.167.96.75"
echo "  2. ssh cerebro@89.167.96.75"
echo "  3. Запустите вручную: phase2-openclaw.sh и далее"
