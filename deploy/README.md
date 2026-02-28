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

### 8. Фаза 5: Whisper (голос → текст)

**Рекомендуется: openai-whisper-api** (облако, без нагрузки на RAM, платно). [ClawHub: openai-whisper-api](https://clawhub.ai/steipete/openai-whisper-api)

На VPS:
```bash
cd ~/.openclaw/workspace
npx clawhub install openai-whisper-api
```

Задать API-ключ OpenAI:
- **Вариант A:** в конфиге OpenClaw (если поддерживается), например в `~/.openclaw/workspace/openclaw.json` в секции skills для `openai-whisper-api` поле `apiKey`.
- **Вариант B:** переменная окружения для user-сервиса: в юните systemd добавить `Environment=OPENAI_API_KEY=sk-...` или положить ключ в `~/.openclaw/env` и подключать через `EnvironmentFile=`.

После установки и настройки ключа: `systemctl --user restart openclaw-gateway`.

Скилл предоставляет скрипт `scripts/transcribe.sh` для транскрипции файла. **Автоматический ответ на голос в Telegram** включается не скиллом, а встроенной обработкой OpenClaw (см. ниже).

#### Включение автоматической транскрипции голоса в Telegram

У OpenClaw есть встроенная поддержка голосовых: при получении голосового сообщения gateway сам вызывает транскрипцию (OpenAI API или локальный Whisper) и подставляет текст в диалог. Нужно добавить в конфиг gateway секцию `tools.media.audio`.

**Где конфиг:** обычно `~/.openclaw/openclaw.json` или `~/.openclaw/workspace/openclaw.json`. На VPS проверь: `ls -la ~/.openclaw/openclaw.json ~/.openclaw/workspace/openclaw.json 2>/dev/null`.

**Скрипт (добавит блок сам):** на VPS выполнить `~/cerebro-memory/deploy/add-audio-transcription.sh` (нужен `jq`: `sudo apt install -y jq`). Затем `systemctl --user restart openclaw-gateway`.

**Что добавить:** в корень JSON (рядом с `agent`, `channels` и т.д.) секцию `tools`:

```json
"tools": {
  "media": {
    "audio": {
      "enabled": true,
      "maxBytes": 20971520,
      "timeoutSeconds": 120,
      "models": [
        { "provider": "openai", "model": "gpt-4o-mini-transcribe" }
      ]
    }
  }
}
```

Если в конфиге уже есть `tools` (например `tools.exec`), добавь внутрь него только `media.audio`, не затирая остальное. Ключ OpenAI gateway возьмёт из окружения (`OPENAI_API_KEY` в systemd уже задан через `EnvironmentFile=~/.openclaw/openai.env`).

**После правок:**
```bash
systemctl --user restart openclaw-gateway
```
Проверка: отправить боту голосовое в Telegram — бот должен распознать и ответить по смыслу. Документация: [OpenClaw Audio and Voice Notes](https://docs.openclaw.ai/nodes/audio).

Альтернатива (локально, много RAM): faster-whisper или tg-voice-whisper — риск OOM на малых VPS.

### 8.1 Календарь (CalDAV / khal)

Чтобы бот видел календарь и мог отвечать на вопросы про встречи и расписание, нужен skill **caldav-calendar** (он даёт агенту инструменты для вызова `khal`).

**Предварительно:** на VPS должны быть настроены vdirsyncer и khal (CalDAV, например Larnilane/Mail.ru: Рабочий, Личный и др.). Коллекции синхронизируются в локальные каталоги; перед установкой skill убедись, что `vdirsyncer sync` и `khal list` работают под пользователем `cerebro`.

Установка skill:

```bash
cd ~/.openclaw/workspace
npx clawhub install caldav-calendar
systemctl --user restart openclaw-gateway
```

Проверка в Telegram: «Что у меня на неделе?», «Встречи на завтра», «Расписание на понедельник».

**Если бот пишет «календарь не подключён» / «нет доступа»:** сразу после такого ответа на VPS выполнить `journalctl --user -u openclaw-gateway -n 100 --no-pager` и проверить: (1) вызывался ли инструмент календаря (поиск по khal, caldav, calendar, tool); (2) есть ли ошибка (например `khal: command not found` — тогда добавить PATH в user unit: `Environment=PATH=/usr/bin:/usr/local/bin:...` в `~/.config/systemd/user/openclaw-gateway.service` и `systemctl --user daemon-reload`).

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
| add-audio-transcription.sh | Добавление tools.media.audio в openclaw.json (транскрипция голоса) |
| copy-from-local.sh | Копирование ~/.openclaw с локальной машины |

---

## Подключение skills

Правила и матрица советник → skills описаны в `protocols/skills-integration.md`. Skills добавляем **по одному в прод**: сначала read-only (погода, суммаризаторы, браузер на чтение), затем при необходимости — с доступом к данным и write только после явного описания в протоколе.

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

### Skills приоритета 1 (read-only)

Ставим по одному, после каждого — перезапуск gateway и проверка в Telegram.

| Шаг | Skill | Действия на VPS | Проверка в Telegram |
|-----|--------|------------------|----------------------|
| 1 | **weather** | Если ещё не установлен: `cd ~/.openclaw/workspace && clawhub install weather`. Затем `systemctl --user restart openclaw-gateway`. | «Какая погода в Барселоне?» |
| 2 | **summarize** | `cd ~/.openclaw/workspace && clawhub install summarize` (или `npx clawhub search summarize` → выбрать slug). `systemctl --user restart openclaw-gateway`. | Отправить ссылку: «Кратко перескажи что там» / «Сделай саммари». |
| 3 | **browser / Headless Chrome** | Сначала зависимости (если ещё не ставили): выполнить `~/cerebro-memory/deploy/phase4-chrome.sh`. Затем `npx clawhub search "browser"` или `"chrome"` → установить выбранный skill в workspace. Перезапуск gateway. | «Найди в интернете [факт]» или «Открой [URL] и скажи о чём страница». |
| 4 | **caldav-calendar** | Сначала vdirsyncer + khal (CalDAV, напр. Larnilane/Mail.ru). Затем `cd ~/.openclaw/workspace && npx clawhub install caldav-calendar`. Перезапуск gateway. | «Что на неделе?», «Встречи на завтра», «Расписание на понедельник». |

Логи при проблемах: `journalctl --user -u openclaw-gateway -n 50 --no-pager`.

### Правило

Сначала — только read-only skills. Навыки с write-операциями (почта, календарь, код, доски) добавлять только после явного описания в протоколе и с пониманием рисков.

---

## Второй бот (песочница) — опционально

При необходимости тестировать skills отдельно можно поднять второго Telegram-бота и отдельный workspace (`~/.openclaw/workspace-sandbox`). На текущей установке прод и второй gateway конфликтуют (один порт / перезапуск продового сервиса), поэтому режим «по очереди» или ручной запуск в tmux. Скрипты и юнит в репо не поддерживаются в текущем потоке; skills добавляем по одному в прод (см. `protocols/skills-integration.md`).
