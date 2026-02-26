# Развёртывание Cerebro на VPS

Скрипты для поэтапного развёртывания на Hetzner VPS (cerebro-node-1, 89.167.96.75).

## Предварительные требования

- SSH-доступ к VPS (root или cerebro)
- Пароль или SSH-ключ для root@89.167.96.75

## Порядок выполнения

### 1. Подключиться к VPS

```bash
ssh root@89.167.96.75
```

### 2. Скопировать скрипты на VPS

С локальной машины (из папки cerebro):

```bash
scp deploy/phase*.sh root@89.167.96.75:/root/
```

### 3. Фаза 1: Подготовка сервера

```bash
chmod +x /root/phase1-server-setup.sh
/root/phase1-server-setup.sh
```

После создания пользователя cerebro — скопировать SSH-ключ:

```bash
# С локальной машины
ssh-copy-id cerebro@89.167.96.75
```

Переключиться на cerebro:

```bash
su - cerebro
```

### 4. Скопировать скрипты для cerebro

```bash
# От root
cp /root/phase*.sh /home/cerebro/
chown cerebro:cerebro /home/cerebro/phase*.sh
```

### 5. Фаза 2: OpenClaw

```bash
chmod +x ~/phase2-openclaw.sh
~/phase2-openclaw.sh
```

Пройти onboarding (модель, Telegram, skills).

### 6. Фаза 3: Конфигурация

С локальной машины (WSL) скопировать openclaw:

```bash
./deploy/copy-from-local.sh
```

На VPS:

```bash
chmod +x ~/phase3-config.sh
~/phase3-config.sh
```

### 7. Фаза 4: Headless Chrome

```bash
chmod +x ~/phase4-chrome.sh
~/phase4-chrome.sh
```

Установить skill через бота: «Установи skill Headless Chrome из Claw Hub».

### 8. Фаза 5: Whisper

```bash
chmod +x ~/phase5-whisper.sh
~/phase5-whisper.sh
```

Через бота: «Установи skill faster-whisper» или настроить Whisper API.

### 9. Фаза 6: Systemd

```bash
chmod +x ~/phase6-systemd.sh
~/phase6-systemd.sh
```

### 10. Фаза 7: Мониторинг

```bash
chmod +x ~/phase7-monitor.sh
~/phase7-monitor.sh
```

## Файлы

| Файл | Описание |
|------|----------|
| phase1-server-setup.sh | Обновление, пользователь, firewall |
| phase2-openclaw.sh | Установка OpenClaw |
| phase3-config.sh | cerebro-memory, openclaw.json |
| phase4-chrome.sh | Playwright, Chromium |
| phase5-whisper.sh | faster-whisper или API |
| phase6-systemd.sh | Автозапуск |
| phase7-monitor.sh | Мониторинг RAM |
| copy-from-local.sh | Копирование ~/.openclaw с локальной машины |
