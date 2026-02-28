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

Профиль пользователя (чтобы бот «знал» часовой пояс и базовый контекст) лежит в репо: `core/user-profile.md`. Скрипт phase3 при наличии папки `~/.openclaw/workspace` создаёт симлинк `~/.openclaw/workspace/USER.md` → `~/cerebro-memory/core/user-profile.md`. Если phase3 уже выполнялся до появления user-profile, один раз вручную на VPS:

```bash
ln -sf ~/cerebro-memory/core/user-profile.md ~/.openclaw/workspace/USER.md
systemctl --user restart openclaw-gateway
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

## Обновление cerebro-memory на VPS

После изменений в репозитории (манифест, профиль, ledger) на VPS нужно подтянуть обновления.

### Ручной запуск

Под пользователем `cerebro` на VPS:

```bash
cd ~/cerebro-memory
git pull
# при необходимости перезапустить gateway:
systemctl --user restart openclaw-gateway
```

Либо выполнить скрипт (если он скопирован на VPS):

```bash
chmod +x ~/cerebro-memory/deploy/update-memory.sh
~/cerebro-memory/deploy/update-memory.sh
```

Скрипт пишет лог в `~/cerebro-memory.update.log`. Чтобы после каждого pull перезапускался gateway, раскомментируйте блок с `systemctl --user restart openclaw-gateway` в `deploy/update-memory.sh`.

### По расписанию (cron)

Чтобы репо обновлялось автоматически, на VPS под пользователем `cerebro` добавьте задание cron, например раз в час:

```bash
crontab -e
# добавить строку (подставьте путь к репо при необходимости):
0 * * * * /home/cerebro/cerebro-memory/deploy/update-memory.sh
```

Либо раз в день в заданное время:

```bash
0 6 * * * /home/cerebro/cerebro-memory/deploy/update-memory.sh
```

Установка cron выполняется вручную на VPS; скрипт должен быть исполняемым (`chmod +x .../update-memory.sh`).

---

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
| update-memory.sh | Обновление репо (git pull), ручной или по cron |
| setup-sandbox.sh | Подготовка песочницы: workspace-sandbox, симлинки, sandbox.env, user unit |
| openclaw-gateway-sandbox.service | Шаблон systemd user unit для второго gateway (песочница) |
| copy-from-local.sh | Копирование ~/.openclaw с локальной машины |

---

## Подключение skills (Phase 1)

Правила и матрица советник → skills описаны в `protocols/skills-integration.md`. Новые skills сначала проверяются в песочнице (второй бот), затем по одному включаются в прод.

### Команды на VPS (пользователь cerebro)

- Посмотреть, какие skills уже доступны агенту:
  ```bash
  openclaw skills list
  openclaw skills list --eligible
  ```
- Искать навыки в Claw Hub (нужен установленный `clawhub`):
  ```bash
  npx clawhub search "browser"
  npx clawhub search "summarize"
  ```
- Установить skill в текущий workspace (обычно `~/.openclaw/workspace` или `./skills`):
  ```bash
  clawhub install <skill-slug>
  ```
  После установки перезапустить gateway:
  ```bash
  systemctl --user restart openclaw-gateway
  ```

### Правило

Не добавлять в прод‑Cerebro навыки с write-операциями (почта, календарь, код, доски) до проверки в песочнице и до явного описания в протоколе (Phase 2/3).

---

## Песочница: второй бот (sandbox)

Второй бот нужен, чтобы тестировать новые skills без риска для прод‑Cerebro. Второй репозиторий на Git не нужен.

**Токен второго бота вводи только на VPS в файл `~/.openclaw/sandbox.env`. В чат и в репозиторий не вставляй.**

### Пошаговая настройка (со скриптом)

1. **Создать второго бота**
   - В Telegram: [@BotFather](https://t.me/BotFather) → `/newbot` → создать бота (например, CerebroSandboxBot).
   - Сохранить токен — он понадобится на шаге 3 (только на VPS, не в репо).

2. **На VPS под пользователем cerebro выполнить скрипт**
   - Сначала подтянуть репо: `cd ~/cerebro-memory && git pull`
   - Запустить подготовку песочницы:
     ```bash
     chmod +x ~/cerebro-memory/deploy/setup-sandbox.sh
     ~/cerebro-memory/deploy/setup-sandbox.sh
     ```
   - Скрипт создаёт `~/.openclaw/workspace-sandbox`, симлинки на манифест и профиль из cerebro-memory, файл `~/.openclaw/sandbox.env` с заглушкой для токена и копирует systemd user unit для песочницы.

3. **Подставить токен второго бота**
   - На VPS: `nano ~/.openclaw/sandbox.env`
   - Заменить `ПОДСТАВЬ_ТОКЕН_СЮДА` на реальный токен из BotFather. Сохранить.
   - Файл `sandbox.env` не коммитится в git и должен оставаться только на VPS.

4. **Запустить песочницу**
   ```bash
   systemctl --user start openclaw-gateway-sandbox
   ```
   Опционально включить автозапуск при входе пользователя:
   ```bash
   systemctl --user enable openclaw-gateway-sandbox
   ```

5. **Pairing в Telegram**
   - Открыть второго бота в Telegram и выполнить pairing (как для прод‑бота), привязать свой user id.

6. **Skills в песочницу**
   - Ставить отдельно из каталога песочницы: `cd ~/.openclaw/workspace-sandbox && clawhub install <skill>`
   - Перезапуск песочницы после установки skill: `systemctl --user restart openclaw-gateway-sandbox`

### Порты и конфликты

Если прод уже запущен как user unit `openclaw-gateway.service`, оба процесса (прод и песочница) работают на одной машине. OpenClaw по умолчанию может слушать один и тот же порт (например 18789). Если второй gateway при старте выдаёт ошибку «address already in use», задай для песочницы другой порт — через конфиг OpenClaw в `workspace-sandbox` или переменную окружения, если приложение это поддерживает. Конфликта по Telegram не будет: у каждого бота свой токен и свой поток getUpdates.

### Что нужно (без скрипта)

- Второй workspace: `~/.openclaw/workspace-sandbox` с симлинками SOUL.md, BOOTSTRAP.md, USER.md на `~/cerebro-memory/core/`.
- Токен второго бота — в конфиге или в `EnvironmentFile` (например `~/.openclaw/sandbox.env` с `TELEGRAM_BOT_TOKEN=...`).
- Второй процесс gateway с `WorkingDirectory=~/.openclaw/workspace-sandbox` и этим токеном (второй user unit или ручной запуск в tmux/screen).
- Альтернатива конфигу: если OpenClaw читает `openclaw.json` из текущей директории, скопировать `~/.openclaw/workspace/openclaw.json` в `workspace-sandbox/` и заменить в нём только telegram token для песочницы.

### Git

- Один репозиторий `cerebro-memory` достаточен.
- Прод и песочница могут использовать один и тот же манифест (симлинки на `~/cerebro-memory/core/manifest.md`) или копию для экспериментов. Различие — какой бот, какой workspace и какие skills установлены, а не отдельный репо.
