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

**Файлы workspace из репо (SOUL, USER, AGENTS):**

| Файл в workspace | Репо | Назначение |
|------------------|------|------------|
| SOUL.md | `core/manifest.md` | Персона, границы, время, календарь, вывод (короткий SOUL). |
| USER.md | `core/user-profile.md` | Профиль пользователя, тон, приоритеты. |
| AGENTS.md | `core/agents.md` | Операционные инструкции: Chief of Staff, память, советники, Decision Framework, протоколы. |

Профиль пользователя (чтобы бот «знал» часовой пояс и базовый контекст) лежит в репо: `core/user-profile.md`. Скрипт phase3 при наличии папки `~/.openclaw/workspace` создаёт симлинк `~/.openclaw/workspace/USER.md` → `~/cerebro-memory/core/user-profile.md`. **После рефактора** для подключения AGENTS на VPS один раз выполнить:

```bash
ln -sf ~/cerebro-memory/core/agents.md ~/.openclaw/workspace/AGENTS.md
systemctl --user restart openclaw-gateway
```

Если phase3 уже выполнялся до появления user-profile, симлинк USER вручную:

```bash
ln -sf ~/cerebro-memory/core/user-profile.md ~/.openclaw/workspace/USER.md
systemctl --user restart openclaw-gateway
```

#### Как проверить, что SOUL и AGENTS подключены

**1. На VPS — что файлы на месте и gateway жив:**

```bash
# Симлинки и размеры
ls -la ~/.openclaw/workspace/SOUL.md ~/.openclaw/workspace/USER.md ~/.openclaw/workspace/AGENTS.md 2>/dev/null

# Сервис и последние логи
systemctl --user is-active openclaw-gateway
journalctl --user -u openclaw-gateway -n 30 --no-pager
```

SOUL чаще всего вешает в корне: `~/.openclaw/SOUL.md` → `~/cerebro-memory/core/manifest.md`. Если в workspace только USER и AGENTS — нормально; SOUL может быть прописан в конфиге отдельно.

**2. В боте — что правила из SOUL и AGENTS работают:**

- **SOUL (время, календарь):** напиши «Который час?» или «Что на этой неделе?» — бот должен вызвать `session_status` / календарный tool и ответить по факту, без «нет доступа» и без просьбы скрина.
- **AGENTS (советники, формат):** спроси «Как сегодня день?» или «План на день» — ответ должен быть в стиле Chief of Staff (структура дня, приоритеты). На ответ с рекомендацией в конце должна быть строка вида `Intent: … (confidence: …)`.

**3. Логи — попал ли контент в контекст:**

В логах OpenClaw иногда видно, какие файлы подгружаются в bootstrap. Детальный лог (если есть): `tail -n 200 /tmp/openclaw/openclaw-*.log` — искать по "SOUL", "AGENTS", "bootstrap" или по первому фрагменту из manifest/agents. Если в конфиге OpenClaw явно перечислены файлы workspace (SOUL.md, USER.md, AGENTS.md и т.д.) — убедись, что там есть AGENTS.md или что подхватывается весь workspace.

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

**Часовой пояс:** если в боте время событий на час назад — в `~/.config/khal/config` в секции `[locale]` добавь `local_timezone = Europe/Madrid` (или свой пояс). Без этого khal использует системный TZ VPS (часто UTC).

Установка skill:

```bash
cd ~/.openclaw/workspace
npx clawhub install caldav-calendar
systemctl --user restart openclaw-gateway
```

Проверка в Telegram: «Что у меня на неделе?», «Встречи на завтра», «Расписание на понедельник».

**Если бот пишет «календарь не подключён» / «нет доступа»:** (1) Логи gateway: `journalctl --user -u openclaw-gateway -n 100 --no-pager`. (2) Детальный лог (вызовы tool): `tail -200 /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log` — искать `embedded run tool` и имя tool (если нет вызова caldav/khal/calendar — модель не вызывает инструмент; в манифесте явно указано вызывать инструмент с именем/описанием caldav_calendar, khal, calendar). (3) При ошибке `khal: command not found` — добавить PATH в user unit и сделать `systemctl --user daemon-reload`.

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
| run-on-vps.sh | Запуск команды на VPS по SSH (ключ в ~/.ssh/, не в репо) |

---

## Запуск команд на VPS с локальной машины

Чтобы запускать команды на VPS без ввода пароля (и чтобы агент мог вызывать `run-on-vps.sh`), один раз настрой вход по SSH-ключу.

### Настройка SSH-ключа (пошагово)

**Шаг 1. Проверить или создать ключ** (на своей машине, не на VPS)

```bash
ls -la ~/.ssh/id_ed25519.pub ~/.ssh/id_rsa.pub 2>/dev/null || true
```

- Если один из файлов есть — ключ уже есть, переходи к шагу 2.
- Если нет — создать ключ (парольную фразу можно оставить пустой для автоматизации):
  ```bash
  ssh-keygen -t ed25519 -C "cerebro-vps" -f ~/.ssh/id_ed25519_cerebro -N ""
  ```
  Публичный ключ будет в `~/.ssh/id_ed25519_cerebro.pub`.

**Шаг 2. Скопировать ключ на VPS**

Подставь свой IP, если не 89.167.96.75, и пользователя (обычно `cerebro`):

```bash
ssh-copy-id -i ~/.ssh/id_ed25519_cerebro.pub cerebro@89.167.96.75
```

(Если используешь стандартный ключ `id_ed25519` или `id_rsa`, можно просто: `ssh-copy-id cerebro@89.167.96.75`.)

Один раз введи пароль пользователя `cerebro` — дальше вход будет по ключу.

**Шаг 3. Проверить вход без пароля**

```bash
ssh cerebro@89.167.96.75 "echo OK"
```

Должно вывести `OK` без запроса пароля.

**Шаг 4. (По желанию) Указать свой ключ в SSH config**

Если создавал отдельный ключ (например `id_ed25519_cerebro`), добавь в `~/.ssh/config`:

```
Host cerebro-vps
  HostName 89.167.96.75
  User cerebro
  IdentityFile ~/.ssh/id_ed25519_cerebro
```

Тогда в скрипте можно использовать `VPS_HOST=cerebro-vps` (или поменять дефолт в `run-on-vps.sh` на `cerebro-vps`).

**Шаг 5. Запуск команд через скрипт**

Из корня репо cerebro-memory:

```bash
./deploy/run-on-vps.sh "journalctl --user -u openclaw-gateway -n 100 --no-pager"
./deploy/run-on-vps.sh "cd ~/cerebro-memory && git pull && systemctl --user restart openclaw-gateway"
```

Если ключ не стандартный (`id_ed25519`/`id_rsa`), задай его через config (шаг 4) или переменную: `GIT_SSH_COMMAND='ssh -i ~/.ssh/id_ed25519_cerebro' ./deploy/run-on-vps.sh "команда"` (или настрой Host в config и `VPS_HOST=cerebro-vps`).

Ключи и пароли в репо не хранить. Переменные `VPS_HOST`/`VPS_USER` при необходимости держать в `deploy/.env` (добавь `deploy/.env` в `.cursorignore`, чтобы агент не читал файл).

### Git pull на VPS без ввода пароля (Deploy Key)

Чтобы `run-on-vps.sh "cd ~/cerebro-memory && git pull ..."` работал без запроса логина/пароля, настрой на VPS **SSH Deploy Key** (один ключ только для этого репо, без токенов GitHub).

**На VPS** под пользователем `cerebro`:

1. Создать ключ (без пароля):
   ```bash
   ssh-keygen -t ed25519 -C "cerebro-vps-github" -f ~/.ssh/cerebro_memory_deploy -N ""
   ```
2. Вывести публичный ключ и скопировать:
   ```bash
   cat ~/.ssh/cerebro_memory_deploy.pub
   ```
3. В GitHub: репозиторий **NurzhanMukhitov/cerebro-memory** → Settings → Deploy keys → Add deploy key. Вставить ключ, название например `cerebro-node-1`. Read-only достаточно. Сохранить.
4. На VPS в `~/.ssh/config` добавить (чтобы для GitHub использовался только этот ключ):
   ```
   Host github.com
     HostName github.com
     User git
     IdentityFile ~/.ssh/cerebro_memory_deploy
     IdentitiesOnly yes
   ```
5. Переключить remote на SSH и проверить pull:
   ```bash
   cd ~/cerebro-memory
   git remote set-url origin git@github.com:NurzhanMukhitov/cerebro-memory.git
   git pull
   ```
   Должно пройти без запроса. При первом подключении к GitHub ввести `yes` для подтверждения host key.

После этого с локальной машины или через агента можно вызывать:
`./deploy/run-on-vps.sh "cd ~/cerebro-memory && git pull && systemctl --user restart openclaw-gateway"` — без ввода пароля на VPS.

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
