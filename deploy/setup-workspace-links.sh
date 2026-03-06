#!/usr/bin/env bash
# Создаёт в ~/.openclaw/workspace симлинки на health/ и protocols/ из репо cerebro-memory,
# чтобы агент мог читать health/log-*.md и protocols/ при ответах в топике «Здоровье» и др.
# Запуск: на VPS — bash ~/cerebro-memory/deploy/setup-workspace-links.sh
# С локальной машины: ./deploy/run-on-vps.sh "bash -s" < deploy/setup-workspace-links.sh

set -e
REPO="${CEREBRO_REPO:-$HOME/cerebro-memory}"
WS="${OPENCLAW_WS:-$HOME/.openclaw/workspace}"

if [ ! -d "$REPO" ]; then
  echo "Репо не найден: $REPO. Задай CEREBRO_REPO или запусти скрипт на VPS из каталога с клоном." >&2
  exit 1
fi
if [ ! -d "$WS" ]; then
  echo "Workspace не найден: $WS. Задай OPENCLAW_WS или настрой OpenClaw." >&2
  exit 1
fi

mkdir -p "$WS"
ln -sf "$REPO/health" "$WS/health"
ln -sf "$REPO/protocols" "$WS/protocols"
echo "Симлинки созданы: $WS/health -> $REPO/health, $WS/protocols -> $REPO/protocols"
