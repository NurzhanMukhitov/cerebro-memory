#!/bin/bash
# Фаза 3: Перенос конфигурации Cerebro
# Запуск: на VPS под пользователем cerebro

set -e

echo "=== Фаза 3: Конфигурация Cerebro ==="

# 3.1 Клонирование cerebro-memory
if [ ! -d ~/cerebro-memory ]; then
  git clone https://github.com/NurzhanMukhitov/cerebro-memory.git ~/cerebro-memory
  echo "cerebro-memory клонирован."
else
  echo "cerebro-memory уже существует. Обновляю..."
  cd ~/cerebro-memory && git pull && cd ~
fi

# 3.2 Проверка ~/.openclaw
if [ ! -d ~/.openclaw ]; then
  echo "ВНИМАНИЕ: ~/.openclaw не найден."
  echo "Скопируйте с локальной машины (WSL):"
  echo "  scp -r ~/.openclaw cerebro@89.167.96.75:~/"
  echo "Затем перезапустите этот скрипт."
  exit 1
fi

# 3.3 Symlink SOUL.md (если cerebro-memory содержит manifest)
if [ -f ~/cerebro-memory/core/manifest.md ] && [ ! -L ~/.openclaw/SOUL.md ]; then
  ln -sf ~/cerebro-memory/core/manifest.md ~/.openclaw/SOUL.md 2>/dev/null || true
fi

# 3.4 Symlink USER.md (профиль пользователя — часовой пояс, локаль, обращение)
if [ -f ~/cerebro-memory/core/user-profile.md ] && [ -d ~/.openclaw/workspace ]; then
  ln -sf ~/cerebro-memory/core/user-profile.md ~/.openclaw/workspace/USER.md 2>/dev/null || true
fi

echo "=== Фаза 3 завершена ==="
echo "Проверьте openclaw.json и CLIProxyAPI/модель."
