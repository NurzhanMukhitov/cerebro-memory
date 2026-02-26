#!/bin/bash
# Фаза 6: Systemd и автозапуск
# Запуск: на VPS под пользователем cerebro (часть команд — sudo)

set -e

echo "=== Фаза 6: Systemd ==="

# Найти путь к openclaw
OPENCLAW_PATH=$(which openclaw 2>/dev/null || echo "/home/cerebro/.local/bin/openclaw")

# Создать systemd unit
sudo tee /etc/systemd/system/openclaw.service > /dev/null << EOF
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
Type=simple
User=cerebro
WorkingDirectory=/home/cerebro
ExecStart=$OPENCLAW_PATH gateway start
Restart=on-failure
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

# Включить и запустить
sudo systemctl daemon-reload
sudo systemctl enable openclaw
sudo systemctl start openclaw
sudo systemctl status openclaw --no-pager

echo "=== Фаза 6 завершена ==="
