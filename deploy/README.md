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

### Что нужно

1. **Второй Telegram-бот**
   - В Telegram: [@BotFather](https://t.me/BotFather) → `/newbot` → создать бота (например, CerebroSandboxBot).
   - Получить токен и сохранить его (он понадобится для конфига песочницы).

2. **Второй workspace на том же VPS**
   - Отдельная папка под песочницу, например:
     ```bash
     mkdir -p ~/.openclaw/workspace-sandbox
     ```
   - В неё можно скопировать минимальный набор из прод‑workspace (SOUL.md, BOOTSTRAP.md, IDENTITY.md и т.д.) или сделать симлинки на тот же `~/cerebro-memory/core/manifest.md`, если хочешь тот же манифест, но другие skills.
   - В песочницу устанавливаются тестовые skills (`clawhub install ...` из каталога workspace-sandbox или с указанием workdir).

3. **Второй процесс gateway**
   - Нужно запускать второй экземпляр OpenClaw gateway с:
     - другим workspace (например `~/.openclaw/workspace-sandbox`);
     - другим Telegram-токеном (в конфиге или переменной окружения для этого процесса).
   - Как именно задаётся workspace и токен, смотри в текущей конфигурации OpenClaw (например `openclaw.json`, переменные окружения или флаги `openclaw gateway start`). Обычно один gateway = один конфиг/один workspace.
   - Варианты:
     - **Ручной запуск:** в отдельном tmux/screen сессии запустить gateway с конфигом для песочницы (отдельный `openclaw.json` в workspace-sandbox или через `--config`/`OPENCLAW_*`).
     - **Второй user unit:** скопировать `openclaw-gateway.service` в `openclaw-gateway-sandbox.service`, в нём поменять путь к workspace и конфиг/токен, запускать вторым юнитом.

4. **Pairing в Telegram**
   - В новом боте выполнить команду pairing (как при первой настройке прод‑бота) и привязать свой Telegram user id, чтобы только ты мог с ним общаться.

### Git

- Один репозиторий `cerebro-memory` достаточен.
- Прод и песочница могут использовать один и тот же манифест (симлинки на `~/cerebro-memory/core/manifest.md`) или копию для экспериментов. Различие — какой бот, какой workspace и какие skills установлены, а не отдельный репо.
