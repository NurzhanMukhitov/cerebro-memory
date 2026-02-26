#!/bin/bash
# Фаза 7: Мониторинг ресурсов
# Запуск: на VPS

echo "=== Фаза 7: Мониторинг ==="

# Установка htop если нет
command -v htop &>/dev/null || sudo apt install -y htop

# Скрипт логирования RAM
cat > ~/monitor.sh << 'MONITOR'
#!/bin/bash
LOG=~/ram_log.txt
while true; do
  echo "$(date): $(free -h | grep Mem)" >> "$LOG"
  sleep 300
done
MONITOR
chmod +x ~/monitor.sh

echo "Мониторинг настроен."
echo "Команды:"
echo "  free -h          — RAM"
echo "  htop             — CPU + RAM в реальном времени"
echo "  nohup ~/monitor.sh &  — логирование RAM каждые 5 мин"
echo "  tail -f ~/ram_log.txt  — просмотр логов"
echo ""
echo "Критерии апгрейда: < 500 MB свободно, OOM killer, падения Chrome/Whisper"
