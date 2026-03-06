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

**Комплексный аудит бота (все блоки, что проверять):** см. [docs/bot-audit-2026-02.md](../docs/bot-audit-2026-02.md).

**Файлы workspace из репо (SOUL, USER, AGENTS, IDENTITY, TOOLS):**

| Файл в workspace | Репо | Назначение |
|------------------|------|------------|
| SOUL.md | `core/manifest.md` | Персона, границы, время, календарь, вывод (короткий SOUL). |
| USER.md | `core/user-profile.md` | Профиль пользователя, тон, приоритеты. |
| AGENTS.md | `core/agents.md` | Операционные инструкции: Chief of Staff, память, советники, Decision Framework, протоколы. |
| IDENTITY.md | `core/identity.md` | Имя агента, эмодзи, краткое описание (опционально). |
| TOOLS.md | `core/tools.md` | Подсказки по инструментам: когда вызывать session_status, календарь, остальные skills (опционально). |
| BOOTSTRAP.md | **не из репо** | На VPS должен быть **минимальным** (1 строка), не симлинк на manifest. Иначе тот же контент, что и SOUL, грузится дважды и сильно тормозит ответы. |

Профиль пользователя (чтобы бот «знал» часовой пояс и базовый контекст) лежит в репо: `core/user-profile.md`. Скрипт phase3 при наличии папки `~/.openclaw/workspace` создаёт симлинк `~/.openclaw/workspace/USER.md` → `~/cerebro-memory/core/user-profile.md`. **После рефактора** для подключения AGENTS на VPS один раз выполнить:

```bash
ln -sf ~/cerebro-memory/core/agents.md ~/.openclaw/workspace/AGENTS.md
systemctl --user restart openclaw-gateway
```

При желании подключить IDENTITY (имя, эмодзи):

```bash
ln -sf ~/cerebro-memory/core/identity.md ~/.openclaw/workspace/IDENTITY.md
systemctl --user restart openclaw-gateway
```

Подключить TOOLS (подсказки по инструментам):

```bash
ln -sf ~/cerebro-memory/core/tools.md ~/.openclaw/workspace/TOOLS.md
systemctl --user restart openclaw-gateway
```

**Чтобы бот в топике Health / «Здоровье» видел данные Apple Health и health-логи:** (в Telegram топик может называться Health или Здоровье — оба соответствуют домену здоровья.) workspace на VPS — это `~/.openclaw/workspace`. Снимок Apple Health попадает в `~/.openclaw/workspace/data/` (скрипт `apple-health-push-snapshot.sh` с Mac копирует туда файл). Папка **health** (лог по дням `health/log-YYYY-MM-DD.md`) лежит в репо `~/cerebro-memory/health/`, но по умолчанию не видна агенту. Нужно один раз на VPS создать симлинки:

```bash
# На VPS; с локальной машины: ./deploy/run-on-vps.sh "bash ~/cerebro-memory/deploy/setup-workspace-links.sh"
ln -sf ~/cerebro-memory/health ~/.openclaw/workspace/health
ln -sf ~/cerebro-memory/protocols ~/.openclaw/workspace/protocols
```

Либо выполнить скрипт из репо: `bash ~/cerebro-memory/deploy/setup-workspace-links.sh`. После этого бот сможет читать `data/apple-health-snapshot.md` (если снимок уже залит) и `health/log-*.md`. Перезапуск gateway не обязателен.

Если phase3 уже выполнялся до появления user-profile, симлинк USER вручную:

```bash
ln -sf ~/cerebro-memory/core/user-profile.md ~/.openclaw/workspace/USER.md
systemctl --user restart openclaw-gateway
```

**Оптимизация скорости ответа:** OpenClaw при каждом сообщении подгружает все bootstrap-файлы (SOUL, BOOTSTRAP, AGENTS, USER, TOOLS и т.д.). Если `BOOTSTRAP.md` был симлинком на `manifest.md` (как SOUL), один и тот же текст ~10k символов уходил в контекст дважды → лишние токены и задержка. На VPS BOOTSTRAP заменён на минимальный файл («See SOUL.md…»). Дополнительно: `AGENTS.md` ~22k обрезается до 20k (`bootstrapMaxChars`); сокращение `core/agents.md` до <20k символов ускорит и уберёт предупреждение в логах.

**Диагностика тормозов по логам (VPS):**
- **Rate limit OpenAI:** при появлении в логах `API rate limit reached. Please try again later` и нескольких подряд `embedded run agent end: isError=true` один запрос уходит в повторные попытки и может занять **60+ секунд**. Решение: реже слать запросы подряд, или перейти на `gpt-4o-mini` (меньше токенов/лимитов), или повысить tier в OpenAI.
- **Длительность одного запроса:** в JSON-логе (`/tmp/openclaw/openclaw-*.log`) искать `lane task done` → поле `durationMs` (время от старта обработки до отправки ответа в Telegram). Без rate limit типично 8–25 с; с лимитом — 60+ с.
- **Команда для быстрой проверки:**  
  `journalctl --user -u openclaw-gateway -n 50 --no-pager | grep -E "rate limit|sendMessage ok|bootstrap file AGENTS"`  
  и по времени между bootstrap и sendMessage прикинуть задержку.
- **Ответ не пришёл, в логах «compaction … Rate limit … TPM»:** агент уже сформировал ответ, но шлюз перед отправкой делает суммаризацию контекста (compaction) тем же API — упирается в лимит TPM, и ответ может не уйти. Решение: подождать 1–2 минуты (сброс TPM) и написать снова; не слать подряд много сообщений. **Не ставить** `compaction.mode = "off"` — в этой версии OpenClaw значение недопустимо, шлюз падает при старте (Config invalid).
- **Бот «печатает», но ответы не приходят:** в детальном логе ищи `embedded run agent end: ... isError=false` без последующего `sendMessage ok`. Если сразу после этого идёт `embedded run compaction start` и `compaction retry` — ответ готов, но compaction упирается в лимит (TPM/RPM) и сообщение в Telegram не отправляется. Что делать: не слать подряд несколько запросов (фото + текст + текст); подождать 1–2 мин после серии; при частых сбоях — повысить tier OpenAI или реже комбинировать тяжёлые запросы (фото + календарь + погода подряд).

#### Как проверить, что SOUL и AGENTS подключены

**1. На VPS — что файлы на месте и gateway жив:**

```bash
# Симлинки и размеры
ls -la ~/.openclaw/workspace/SOUL.md ~/.openclaw/workspace/USER.md ~/.openclaw/workspace/AGENTS.md ~/.openclaw/workspace/IDENTITY.md ~/.openclaw/workspace/TOOLS.md 2>/dev/null

# Сервис и последние логи
systemctl --user is-active openclaw-gateway
journalctl --user -u openclaw-gateway -n 30 --no-pager
```

SOUL чаще всего вешает в корне: `~/.openclaw/SOUL.md` → `~/cerebro-memory/core/manifest.md`. Если в workspace только USER и AGENTS — нормально; SOUL может быть прописан в конфиге отдельно.

**2. В боте — что правила из SOUL и AGENTS работают:**

- **SOUL (время, календарь, погода):** напиши «Который час?», «Что на этой неделе?» или «Что по погоде на завтра?» — бот должен вызвать `session_status` / календарный / weather tool и ответить по факту, без «нет доступа» и без просьбы скрина или альтернативных сайтов.
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

#### Временное переключение бота на OpenAI API (как у транскрипции)

**Откат на OAuth (одна строка на VPS):**  
`jq '.agents.defaults.model.primary = "openai-codex/gpt-5.3-codex"' ~/.openclaw/openclaw.json > ~/.openclaw/openclaw.json.tmp && mv ~/.openclaw/openclaw.json.tmp ~/.openclaw/openclaw.json && systemctl --user restart openclaw-gateway`

Сейчас основной агент может быть на `openai-codex/gpt-5.3-codex` (OAuth/подписка). Чтобы перевести бота на **OpenAI API** (оплата по использованию, тот же ключ, что и для голоса):

**Как это будет работать:** шлюз продолжит работать как раньше; меняется только источник ответов: вместо Codex (ChatGPT OAuth) запросы пойдут в API OpenAI по ключу из `~/.openclaw/openai.env`. Транскрипция голоса уже использует этот ключ — ничего дополнительно настраивать не нужно. После смены модели и рестарта шлюза бот сразу начнёт отвечать через выбранную модель (например, `openai/gpt-4o`).

**Возврат обратно:** да, в любой момент можно вернуть OAuth/Codex одной командой (см. ниже). Никаких потерь: OAuth-профиль на VPS остаётся, просто в конфиге снова указывается `openai-codex/gpt-5.3-codex` и делается рестарт.

1. **Перевести на API и модель GPT-4o** (на VPS):
   ```bash
   # Сохранить текущее значение на случай отката (опционально):
   # jq -r '.agents.defaults.model.primary' ~/.openclaw/openclaw.json

   jq '.agents.defaults.model.primary = "openai/gpt-4o"' ~/.openclaw/openclaw.json > ~/.openclaw/openclaw.json.tmp && mv ~/.openclaw/openclaw.json.tmp ~/.openclaw/openclaw.json
   systemctl --user restart openclaw-gateway
   ```
   Другие варианты: `openai/gpt-4o-mini` (дешевле), `openai/o3`, `openai/o3-mini`. Ключ уже в `~/.openclaw/openai.env`.

2. **Вернуть обратно на OAuth (Codex)** — если расход по API окажется выше ожидаемого:
   ```bash
   jq '.agents.defaults.model.primary = "openai-codex/gpt-5.3-codex"' ~/.openclaw/openclaw.json > ~/.openclaw/openclaw.json.tmp && mv ~/.openclaw/openclaw.json.tmp ~/.openclaw/openclaw.json
   systemctl --user restart openclaw-gateway
   ```
   После этого бот снова будет использовать подписку ChatGPT (Codex), расход по API прекратится.

### 8.1 Календарь (CalDAV / khal)

Чтобы бот видел календарь и мог отвечать на вопросы про встречи и расписание, нужен skill **caldav-calendar** (он даёт агенту инструменты для вызова `khal`).

**Предварительно:** на VPS должны быть настроены vdirsyncer и khal (CalDAV, например Larnilane/Mail.ru: Рабочий, Личный и др.). Коллекции синхронизируются в локальные каталоги; перед установкой skill убедись, что `vdirsyncer sync` и `khal list` работают под пользователем `cerebro`.

**Часовой пояс:** в `~/.config/khal/config` в секции `[locale]` обязательно задать:
- `local_timezone = Europe/Madrid` — как отображать время в khal;
- `default_timezone = Europe/Madrid` — в каком поясе создавать новые события (чтобы в .ics писался TZID=Europe/Madrid, а не «плавающее» время без пояса).
Без `default_timezone` khal пишет в .ics время без TZID; сервер Mail.ru может трактовать его как московское, и на Mac в Мадриде событие покажется на 2 часа раньше (например 12:00 станет 10:00). При добавлении событий агенту передавать время в Madrid; см. также manifest (Мск↔Мадрид, перевод часов Испании).

**Время «который час?» отстаёт на час:** на VPS системный TZ = UTC, а `session_status` берёт время процесса. Нужно запускать gateway с TZ пользователя. В unit сервиса `~/.config/systemd/user/openclaw-gateway.service` добавить (один раз): `Environment=TZ=Europe/Madrid`, затем `systemctl --user daemon-reload` и `systemctl --user restart openclaw-gateway`.

Установка skill:

```bash
cd ~/.openclaw/workspace
npx clawhub install caldav-calendar
systemctl --user restart openclaw-gateway
```

Проверка в Telegram: «Что у меня на неделе?», «Встречи на завтра», «Расписание на понедельник».

**Почему после добавления/удаления события ботом нужно обновить календарь на Mac (⌘R):** бот меняет календарь через khal/vdirsyncer на VPS, данные уходят на CalDAV‑сервер. Календарь на Mac — отдельный клиент: он не получает push-уведомлений от сервера и подтягивает изменения только при следующей синхронизации (авто — раз в несколько минут, или вручную ⌘R). Автоматически заставить «мгновенно» обновиться календарь на Mac нельзя; можно лишь напомнить в ответ бота: «Событие добавлено/изменено — обнови календарь (⌘R), если не видишь».

**Важно: после изменений календаря (khal add/delete/edit) обязательно запускать `vdirsyncer sync`** — иначе изменения остаются только в локальной папке на VPS и не попадают на CalDAV‑сервер (Mail.ru). Тогда на Mac после ⌘R дубликаты или старые события могут оставаться. На VPS под пользователем cerebro: после любого изменения календаря ботом нужно выполнить `vdirsyncer sync` (вручную или через exec, если агент умеет). Как страховку можно поставить cron каждые 2 мин: `*/2 * * * * /usr/bin/vdirsyncer sync` (или `vdirsyncer sync` с нужным PATH).

**Если бот пишет «календарь не подключён» / «нет доступа»:** (1) Логи gateway: `journalctl --user -u openclaw-gateway -n 100 --no-pager`. (2) Детальный лог (вызовы tool): `tail -200 /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log` — искать `embedded run tool` и имя tool (если нет вызова caldav/khal/calendar — модель не вызывает инструмент; в манифесте явно указано вызывать инструмент с именем/описанием caldav_calendar, khal, calendar). (3) При ошибке `khal: command not found` — добавить PATH в user unit и сделать `systemctl --user daemon-reload`.

**Если в топике Health / «Здоровье» бот пишет «не вижу данных» / «нет записей о самочувствии»:** (1) Проверить на VPS наличие файла и симлинков: `ls -la ~/.openclaw/workspace/data/apple-health-snapshot.md ~/.openclaw/workspace/health`. (2) Если `health` отсутствует — выполнить `bash ~/cerebro-memory/deploy/setup-workspace-links.sh`. (3) Снимок Apple Health заливается с Mac скриптом `./deploy/apple-health-push-snapshot.sh` (из каталога репо); после заливки файл появляется в `~/.openclaw/workspace/data/`. (4) После обновления правил в `core/manifest.md`, `core/tools.md`, `core/agents.md` или `core/user-profile.md` **на VPS** выполнить `systemctl --user restart openclaw-gateway` (с Mac: `./deploy/run-on-vps.sh "systemctl --user restart openclaw-gateway"`). (5) Диагностика: после нового запроса в топике «Здоровье» на VPS выполнить `grep -i read /tmp/openclaw/openclaw-*.log | tail -20` — если вызовов read нет, модель не вызывает инструмент; правило продублировано в SOUL, USER, TOOLS и AGENTS.

### 8.2 Напоминание за 15 мин до события в календаре

Скрипт `deploy/calendar-reminder-15min.sh` раз в 5 минут смотрит календарь (khal), находит события, которые начинаются через 12–18 мин, и шлёт в Telegram сообщение вида «⏰ Через ~15 мин: [название события]». По умолчанию учитываются только календари, в имени которых есть «Рабочий» (переменная `CALENDAR_FILTER`; чтобы напоминать обо всех — задать `CALENDAR_FILTER=*`).

**Требования на VPS:** khal, curl. Токен и chat_id для отправки в Telegram задаются в `~/.openclaw/calendar-reminder.env` (тот же бот и чат, что у gateway):

```bash
# ~/.openclaw/calendar-reminder.env (chmod 600)
TELEGRAM_BOT_TOKEN=123456:ABC...
TELEGRAM_CHAT_ID=211683644
# Опционально: только календари с "Рабочий" в имени (по умолчанию). Для всех событий:
# CALENDAR_FILTER=*
```

**Cron** (под пользователем cerebro): запускать скрипт каждые 5 мин:

```bash
crontab -e
# добавить строку (путь к репо — свой):
*/5 * * * * /home/cerebro/cerebro-memory/deploy/calendar-reminder-15min.sh
```

Проверка вручную: `bash ~/cerebro-memory/deploy/calendar-reminder-15min.sh` — при наличии события в окне 12–18 мин в чат должно прийти одно сообщение. Дедуп: уже отправленные события записываются в `~/.openclaw/calendar-15m-sent`, повторно не шлются.

### 8.3 Вечерний health check‑in (сон, питание, тренировки)

Идея: каждый вечер Cerebro сам задаёт вопрос про сон, питание и активность за день, а ответ ты пишешь в свободной форме. Агент использует этот ответ как ручной health‑лог (папка `health/`) вместе с данными Apple Health / Strava / Ultrahuman.

Скрипт `deploy/health-evening-checkin.sh` просто отправляет в Telegram сообщение с запросом вечёрнего отчёта по здоровью за текущий день.

**Требования на VPS:** curl. Токен и chat_id для отправки в Telegram задаются в `~/.openclaw/health-checkin.env` (тот же бот и чат, что у gateway):

```bash
# ~/.openclaw/health-checkin.env (chmod 600)
TELEGRAM_BOT_TOKEN=123456:ABC...
TELEGRAM_CHAT_ID=211683644
# Опционально: если хочешь свой текст сообщения целиком:
# TEXT_OVERRIDE="свой текст напоминания..."
```

**Cron** (под пользователем cerebro): запускать скрипт один раз в день в выбранное время, например в 21:30:

```bash
crontab -e
# добавить строку (путь к репо — свой, время — по своему часовому поясу на VPS):
30 21 * * * /home/cerebro/cerebro-memory/deploy/health-evening-checkin.sh
```

Проверка вручную: `bash ~/cerebro-memory/deploy/health-evening-checkin.sh` — в чат должно прийти одно сообщение с текстом вечернего health check‑in.

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
| setup-workspace-links.sh | Симлинки health/ и protocols/ в ~/.openclaw/workspace (чтобы бот видел health-логи и протоколы) |
| copy-from-local.sh | Копирование ~/.openclaw с локальной машины |
| run-on-vps.sh | Запуск команды на VPS по SSH (ключ в ~/.ssh/, не в репо) |

---

## Архитектура и протоколы

Каноническая архитектура топиков, доменов и данных описана в **protocols/** в корне репо.

- **protocols/README.md** — обзор: системные протоколы (Execution Flow, Context Packs, Data Ownership, State Model, Write Intent, Advisor Priority и др.) и доменные протоколы (General, Work, Sport, Health, Food, Home, Finance, Learning, Tech).
- **protocols/architecture-notes.md** — нейминг (Telegram Topic ↔ Internal Domain), роутинг по топикам, владение данными, целевая архитектура (state/current-state.json, Commit Layer — на первом этапе не реализуется).
- **protocols/domains/** — по одному файлу на домен с правилами агента, источниками данных и поведением по состоянию.

После обновления репо (`git pull` в `~/cerebro-memory`) папка `protocols/` доступна агенту в workspace; перезапуск gateway не обязателен для чтения новых файлов, но для применения изменений в `core/manifest.md` или `core/agents.md` нужен `systemctl --user restart openclaw-gateway`.

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
| 5 | **remind** | На VPS (с nvm: `export NVM_DIR=$HOME/.nvm; [ -s "\$NVM_DIR/nvm.sh" ] && . "\$NVM_DIR/nvm.sh"`): `cd ~/.openclaw/workspace && npx clawhub install remind`. Затем `systemctl --user restart openclaw-gateway`. Навык для напоминаний по времени и расписанию. | «Напомни в 18:00», «Напомни позвонить завтра в 10:00». |
| 6 | **rss-reader** | `cd ~/.openclaw/workspace && npx clawhub install rss-reader --force` (skill помечен suspicious — установка с --force). Перезапуск gateway. Ленты настраиваются отдельно (см. ниже). | «Какие новости?», «Что в лентах?». |
| 7 | **gog** | Сначала бинарник gog на VPS, OAuth (на Mac или VPS), копирование credentials и client_secret на VPS, PATH/env в user unit. Затем: `cd ~/.openclaw/workspace && npx clawhub install gog --force` (skill помечен suspicious), перезапуск gateway. Подробно — см. раздел «Настройка Gog» ниже. | «Покажи последние письма за день», «Что в календаре Google на сегодня?». |
| 8 | **strava** | Создать приложение на [strava.com/settings/api](https://www.strava.com/settings/api), получить OAuth-токены (см. «Настройка Strava» ниже), на VPS установить skill и прописать STRAVA_* в env или openclaw.json, перезапуск gateway. | «Как прошла последняя тренировка?», «Сколько накатал за неделю?», «План с учётом Strava». |

**Настройка rss-reader (ленты новостей):** фиды хранятся в `~/.openclaw/workspace/skills/rss-reader/data/feeds.json`. Добавить ленту на VPS (PATH с node обязателен):

```bash
export PATH="$HOME/.nvm/versions/node/v22.22.0/bin:$PATH"
cd ~/.openclaw/workspace/skills/rss-reader
node scripts/rss.js add "https://example.com/feed.xml" --category news
node scripts/rss.js list
node scripts/rss.js check
```

Примеры лент из SKILL.md: Hacker News `https://news.ycombinator.com/rss`, TechCrunch `https://techcrunch.com/feed/`, The Verge `https://www.theverge.com/rss/index.xml`. Удалить: `node scripts/rss.js remove "URL"`. В `feeds.json` можно править вручную: `name`, `category`, `enabled`, в `settings` — `maxItemsPerFeed`, `maxAgeDays`, `summaryEnabled`.

**Настройка Gog (Google Workspace CLI):** skill даёт доступ к Gmail, Google Calendar, Drive через CLI `gog` (gogcli). Риски и защита: см. [docs/bot-audit-2026-02.md](../docs/bot-audit-2026-02.md) и обсуждение (OAuth, права на файлы, минимум scope, подтверждение перед отправкой писем и созданием событий).

1. **GCP:** создать проект (или использовать существующий), включить Gmail API, Google Calendar API (при необходимости Drive API и др.). Credentials → Create credentials → OAuth client ID → тип **Desktop app**, скачать `client_secret_*.json`. Файл не коммитить в репо.
2. **OAuth на Mac (удобнее):** установить gog: `brew install steipete/tap/gogcli`. Выполнить `gog auth credentials /path/to/client_secret_*.json`, затем `gog auth add you@gmail.com --services gmail,calendar` (или нужный набор). Пройти вход в браузере. Узнать, куда gog сохраняет токены (часто `~/.config/gog`), подготовить копирование на VPS.
3. **VPS — бинарник gog:** скачать релиз для Linux amd64 с [github.com/steipete/gogcli/releases](https://github.com/steipete/gogcli/releases), распаковать. Установить: `sudo install -m 0755 gog /usr/local/bin/gog` или `install -m 0755 gog ~/bin/gog` (тогда добавить `~/bin` в PATH в user unit).
4. **VPS — credentials:** скопировать на VPS в домашний каталог `cerebro`: `client_secret_*.json` и папку с токенами gog (например `~/.config/gog`). Разместить так, чтобы процесс gateway читал их под пользователем `cerebro`. Права: `chmod 600` на файлы с секретами, `chmod 700` на каталог.
5. **User unit gateway:** убедиться, что `gog` в PATH (если в `~/bin` — добавить в `~/.config/systemd/user/openclaw-gateway.service` строку `Environment="PATH=/home/cerebro/bin:..."`). При необходимости задать `GOG_ACCOUNT`, `GOG_KEYRING_PASSWORD` (Environment= или EnvironmentFile=). Выполнить: `systemctl --user daemon-reload`, `systemctl --user restart openclaw-gateway`.
6. **Установка skill:** на VPS с nvm: `export NVM_DIR=$HOME/.nvm; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"`, `export PATH="$HOME/.nvm/versions/node/v22.22.0/bin:$PATH"`, `cd ~/.openclaw/workspace && npx clawhub install gog --force`, `systemctl --user restart openclaw-gateway`.
7. **Проверка:** на VPS `gog auth list`, при необходимости `gog gmail search 'newer_than:1d' --max 2`. В Telegram: «Покажи последние письма за сегодня», «Что в календаре Google на эту неделю?». Перед отправкой писем/созданием событий бот должен запрашивать подтверждение (правила в SOUL/TOOLS/AGENTS).

**Что делать дальше (Gog) — твои шаги 1–6 и 9:**

| Шаг | Где | Действие |
|-----|-----|----------|
| **1** | Браузер (GCP) | [Google Cloud Console](https://console.cloud.google.com) → проект → APIs & Services → включить Gmail API, Google Calendar API (при необходимости Drive и др.) → Credentials → Create credentials → OAuth client ID → тип **Desktop app** → скачать JSON. Сохранить как `client_secret_*.json` (не коммитить). |
| **2** | Mac | `brew install steipete/tap/gogcli`. Затем: `gog auth credentials /путь/к/client_secret_*.json`, `gog auth add твой@gmail.com --services gmail,calendar` (или gmail,calendar,drive). Пройти OAuth в браузере. Токены появятся в `~/.config/gog` — эту папку и client_secret потом копируешь на VPS. |
| **3** | VPS (SSH cerebro) | Скачать релиз: открыть [releases](https://github.com/steipete/gogcli/releases), взять `gogcli_*_linux_amd64.tar.gz`. На VPS: `cd /tmp && curl -fsSL -o gog.tgz "URL_из_страницы" && tar -xzf gog.tgz && sudo install -m 0755 gog /usr/local/bin/gog`. Проверка: `gog --version`. |
| **4** | Mac → VPS | Скопировать на VPS (в домашний каталог `cerebro`): `client_secret_*.json` и папку `~/.config/gog`. На VPS разместить: `client_secret` в `~/.config/gog/` или рядом, токены в `~/.config/gog/`. Выполнить: `chmod 700 ~/.config/gog`, `chmod 600 ~/.config/gog/*`. |
| **5** | VPS | Если gog в `/usr/local/bin` — PATH уже ок. Если ставил в `~/bin`: в `~/.config/systemd/user/openclaw-gateway.service` добавить `Environment="PATH=/home/cerebro/bin:/usr/local/bin:..."`. При нескольких аккаунтах: `Environment=GOG_ACCOUNT=твой@gmail.com`. Затем: `systemctl --user daemon-reload && systemctl --user restart openclaw-gateway`. |
| **6** | VPS | `export NVM_DIR=$HOME/.nvm; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"` и `export PATH="$HOME/.nvm/versions/node/v22.22.0/bin:$PATH"` (или свой путь node). Затем: `cd ~/.openclaw/workspace && npx clawhub install gog --force` и `systemctl --user restart openclaw-gateway`. |
| **9** | VPS + Telegram | На VPS: `gog auth list` (должен быть аккаунт). Опционально: `gog gmail search 'newer_than:1d' --max 2`. В Telegram написать: «Покажи последние письма за сегодня», «Что в календаре Google на эту неделю?» — бот должен вызвать gog и ответить. Для проверки подтверждения: «Напиши письмо на X с темой Y» — бот должен спросить подтверждение, не отправлять без «да». |

**Настройка Strava (тренировки, вел, бег, плавание):**

1. **Strava API (у себя в браузере):** зайти на [strava.com/settings/api](https://www.strava.com/settings/api). Создать приложение: название (например «Cerebro»), Category — что подходит, Authorization Callback Domain — для получения токена локально можно указать `localhost`. Сохранить **Client ID** и **Client Secret**.
2. **Получить OAuth-токены (один раз):** в браузере открыть (подставить свой Client ID):
   ```
   https://www.strava.com/oauth/authorize?client_id=ТВОЙ_CLIENT_ID&response_type=code&redirect_uri=http://localhost&approval_prompt=force&scope=activity:read_all
   ```
   Войти в Strava и разрешить доступ. После редиректа в адресной строке будет `http://localhost/?code=XXXXX&scope=...` — скопировать значение `code=XXXXX` (только код, без `code=`).
3. **Обменять code на токены (на Mac или VPS):**
   ```bash
   curl -X POST https://www.strava.com/oauth/token \
     -d client_id=ТВОЙ_CLIENT_ID \
     -d client_secret=ТВОЙ_CLIENT_SECRET \
     -d code=КОД_ИЗ_ШАГА_2 \
     -d grant_type=authorization_code
   ```
   В ответе будут `access_token` и `refresh_token` — сохранить оба.
4. **На VPS — установить skill:** (PATH с node обязателен)
   ```bash
   export NVM_DIR=$HOME/.nvm; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
   export PATH="$HOME/.nvm/versions/node/v22.22.0/bin:$PATH"
   cd ~/.openclaw/workspace && npx clawhub search strava
   ```
   Выбрать slug (например `strava`) и установить: `npx clawhub install strava` (или тот slug, что показан). Перезапуск: `systemctl --user restart openclaw-gateway`.
5. **На VPS — передать ключи боту.** Вариант A — через репо (рекомендуется): скопировать `deploy/strava.env.example` в `deploy/strava.env`, вписать в него Client ID, Client Secret, Access Token, Refresh Token (файл в .gitignore, не коммитится). Затем с Mac выполнить `./deploy/apply-strava.sh` — скрипт скопирует `strava.env` на VPS в `~/.openclaw/strava.env`. Один раз добавить в `~/.config/systemd/user/openclaw-gateway.service` строку `EnvironmentFile=%h/.openclaw/strava.env`, далее `systemctl --user daemon-reload` и перезапуск gateway. Вариант B — вручную на VPS: создать `~/.openclaw/strava.env` с содержимым:
   ```
   STRAVA_CLIENT_ID=твой_client_id
   STRAVA_CLIENT_SECRET=твой_client_secret
   STRAVA_ACCESS_TOKEN=access_token_из_шага_3
   STRAVA_REFRESH_TOKEN=refresh_token_из_шага_3
   ```
   Выполнить `chmod 600 ~/.openclaw/strava.env`. В `~/.config/systemd/user/openclaw-gateway.service` добавить строку `EnvironmentFile=%h/.openclaw/strava.env` (если ещё нет), затем `systemctl --user daemon-reload` и `systemctl --user restart openclaw-gateway`.  
   Вариант B — в `~/.openclaw/openclaw.json` в секции skills (если skill поддерживает) прописать `env` с этими переменными (см. документацию конкретного skill).
6. **Проверка:** в Telegram написать: «Как прошла последняя тренировка?», «Сколько накатал за неделю?» — бот должен вызвать Strava и ответить по данным из аккаунта.

**Обновление токена Strava (раз в ~6 часов или при 401):** Access token Strava живёт ~6 часов. Если бот перестал отдавать данные или в логах 401 — обновить токен. Локально (подставь значения из `deploy/strava.env`):
   ```bash
   curl -s -X POST https://www.strava.com/oauth/token \
     -d client_id="ТВОЙ_CLIENT_ID" \
     -d client_secret="ТВОЙ_CLIENT_SECRET" \
     -d grant_type=refresh_token \
     -d refresh_token="ТВОЙ_REFRESH_TOKEN"
   ```
   В ответе взять новые `access_token` и `refresh_token`, вписать их в `deploy/strava.env` (STRAVA_ACCESS_TOKEN и STRAVA_REFRESH_TOKEN), затем выполнить `./deploy/apply-strava.sh` и перезапуск gateway на VPS. На VPS можно то же сделать вручную, обновив `~/.openclaw/strava.env` и выполнив `systemctl --user restart openclaw-gateway`.

**Снимок Strava для советников Sport / Health / питание:** Чтобы советники (Sport, Health, питание в связи с нагрузкой) имели под рукой актуальный срез активностей и статистики, на VPS можно раз в день формировать снимок. Выполнить на VPS:
   ```bash
   bash ~/cerebro-memory/deploy/strava-sync-to-workspace.sh
   ```
   Скрипт пишет в `~/.openclaw/workspace/data/strava-snapshot.md` последние 60 активностей и YTD-сводку. Агент при запросах к Sport/Health может читать этот файл и при необходимости дополнять данными через exec к API. **Cron (раз в день):** в `crontab -e` пользователя cerebro добавить (подставить загрузку strava.env перед скриптом):
   ```bash
   5 6 * * * . ~/.openclaw/strava.env 2>/dev/null; bash ~/cerebro-memory/deploy/strava-sync-to-workspace.sh
   ```

**Данные Ultrahuman Ring (сон, восстановление, пульс, HRV):** Публичного API для личных аккаунтов нет — есть только **Partner API** (для одобренных приложений, OAuth на https://partner.ultrahuman.com). Варианты:

1. **Партнёрский доступ:** подать заявку в Ultrahuman на партнёрство; при одобрении можно будет сделать интеграцию по аналогии со Strava (токены, скрипт, снимок). Документация: [vision.ultrahuman.com/developer-docs](https://vision.ultrahuman.com/developer-docs).
2. **Снимок вручную (сейчас):** если в приложении Ultrahuman есть экспорт данных или ты выгружаешь отчёт (скрин, текст, CSV) — положи на VPS файл `~/.openclaw/workspace/data/ultrahuman-snapshot.md` (или `.txt`). Кратко опиши в нём сон, Recovery Index, нагрузку за последние дни, что видно в приложении. Агент и советники Health/Sport при запросах по восстановлению и сну могут читать этот файл (read). Раз в несколько дней обновляй содержимое и перезаливай на VPS (scp или вставка через SSH).
3. **Через Apple Health:** кольцо синхронизируется с Apple Health (HRV, температура, сон). Приложения вроде HealthExport экспортируют Health в CSV. Можно периодически экспортировать, при необходимости свести в краткий текст и положить в `workspace/data/ultrahuman-snapshot.md` как в п.2.
4. **Скриншоты + Back Tap + папка на ноуте (полуавтомат):** идея — на iPhone по двойному тапу по задней крышке (Настройки → Универсальный доступ → Касание → Back Tap) запускается Shortcut: сделать скриншот экрана (приложение Ultrahuman должно быть открыто на нужном экране — дашборд/сон/Recovery) и сохранить в iCloud Drive в папку «UltrahumanInbox» или отправить на Mac через AirDrop (файл попадёт в ~/Downloads). На Mac — папка-приёмник (например `~/UltrahumanInbox` или подпапка в Downloads). Скрипт (Folder Action или cron/launchd раз в N минут) проверяет папку: при появлении нового изображения запускает OCR (например `tesseract` или Vision на Mac), превращает текст в markdown и загружает на VPS в `~/.openclaw/workspace/data/ultrahuman-snapshot.md` через scp (как в `apple-health-push-snapshot.sh`: тот же VPS_HOST, REMOTE_PATH для ultrahuman). Бот уже читает `data/ultrahuman-snapshot.md` — менять агента не нужно. Итог: двойной тап по крышке → скрин попадает в папку на ноуте → скрипт распознаёт текст и пушит на VPS → бот видит обновлённый снимок. Ограничение: OCR не идеален для цифр и мелкого текста; лучше всего работает, если на скрине один экран с крупными метриками. При желании можно добавить в репо скрипт `deploy/ultrahuman-inbox-to-vps.sh` (проверка папки, OCR, scp) и настроить Folder Action или launchd.

В agents и tools указано: при наличии `data/ultrahuman-snapshot.md` учитывать его для Health/Sport наравне со снимком Strava.

**Apple Health (HealthKit)** — пошагово:

**Способ A: Ручной экспорт (без Mac как моста)**

1. На iPhone: открой «Здоровье» → профиль (иконка) → «Экспорт всех данных о здоровье» — выгрузится архив. Либо установи приложение вроде [HealthExport](https://healthexport.app/) и экспортируй в CSV за нужный период.
2. При необходимости сведи данные в краткий текст: сон (часы, качество), шаги за несколько дней, пульс/HRV если есть, тренировки. Сохрани в файл, например `apple-health-snapshot.md`.
3. С Mac (из каталога репо) загрузи снимок на VPS:
   ```bash
   ./deploy/apple-health-push-snapshot.sh путь/к/apple-health-snapshot.md
   ```
   Файл попадёт в `~/.openclaw/workspace/data/apple-health-snapshot.md` на VPS; бот и советники Health/Sport будут его учитывать. Повторяй шаги 1–3 раз в несколько дней при желании обновить снимок.

**Способ B: Автоматически через Mac + healthsync (iPhone и Mac в одной Wi‑Fi)** — с самого начала.

**Шаг 1. Клонировать репо и собрать iOS-приложение**

```bash
git clone https://github.com/mneves75/ai-health-sync-ios.git
cd ai-health-sync-ios
open "iOS Health Sync App/iOS Health Sync App.xcodeproj"
```

В Xcode: выбери симулятор или iPhone → ⌘R (Build and Run). При первом запуске разреши доступ к «Здоровье» (шаги, пульс, сон, тренировки). Экосистема [healthkit-sync](https://playbooks.com/skills/openclaw/skills/healthkit-sync): **iOS-приложение** (сервер mTLS + QR) + **CLI healthsync** на Mac.

Исходники описаны в [references/ARCHITECTURE](https://github.com/openclaw/skills/tree/HEAD/skills/mneves75/healthkit-sync/references) skill’а: проект «ai-health-sync-ios-clawdbot» (iOS Health Sync App + macOS/HealthSyncCLI). Репозиторий с кодом: **[github.com/mneves75/ai-health-sync-ios](https://github.com/mneves75/ai-health-sync-ios)** (HealthSync Helper App). Там же Quick Start, [DOCS/QUICKSTART.md](https://github.com/mneves75/ai-health-sync-ios/blob/master/DOCS/QUICKSTART.md), [TROUBLESHOOTING](https://github.com/mneves75/ai-health-sync-ios/blob/master/DOCS/TROUBLESHOOTING.md). Если выложен только skill (документация), а не полный репозиторий — напиши в сообщество OpenClaw (Discord/форум), откуда взять сборку iOS-приложения и как собрать CLI.

**Шаг 2. Установить CLI healthsync на Mac**

- **Homebrew:** сначала `brew tap mneves75/tap`, затем `brew install healthsync` (две отдельные команды).
- **Из исходников:** `cd ai-health-sync-ios/macOS/HealthSyncCLI` → `swift build -c release` → `sudo cp .build/release/healthsync /usr/local/bin/`
- **Готовый бинарник:** [Releases](https://github.com/mneves75/ai-health-sync-ios/releases) (arm64 или x86_64), распаковать и добавить в PATH.

Проверка: `healthsync version` или `healthsync --help`. iPhone и Mac должны быть в одной Wi‑Fi.

**Шаг 3. Установить приложение на iPhone**

Собранное в шаге 1 приложение запусти на реальном iPhone (или установи через Xcode на устройство). Разреши доступ к «Здоровье». Держи iPhone и Mac в одной сети.

**Шаг 4. Привязать iPhone и Mac (один раз)**

1. На **iPhone**: в приложении HealthSync Helper нажми «Start Server» → «Show QR Code» (при необходимости «Copy» для буфера обмена).
2. На **Mac**: `healthsync scan` (читает QR из буфера). Либо скриншот QR сохрани в файл и выполни `healthsync scan --file ~/Desktop/qr.png`.
3. После привязки конфиг в `~/.healthsync/config.json`, токен в связке ключей macOS. При ошибках: [TROUBLESHOOTING](https://github.com/mneves75/ai-health-sync-ios/blob/master/DOCS/TROUBLESHOOTING.md) (No devices found, Pairing code expired, Certificate mismatch).

**Фиксированный порт (опционально):** в репо cerebro-memory в `ai-health-sync-ios` приложение пропатчено: сервер слушает порт **8443** вместо случайного. Пересобери приложение в Xcode (⌘R), установи на iPhone, один раз заново отсканируй QR — дальше порт не будет меняться при перезапуске приложения, повторно сканировать QR не нужно.

**Шаг 5. Проверка выгрузки данных**

```bash
healthsync status
healthsync types
healthsync fetch --types steps,heartRate,sleepAnalysis --start 2026-01-01 --end 2026-01-07 --format json
```

Если команды выполняются и возвращают данные — связка работает. Типы: steps, heartRate, heartRateVariability, sleepAnalysis, workouts, weight и др. — см. [CLI Reference](https://github.com/mneves75/ai-health-sync-ios/blob/master/DOCS/learn/09-cli.md) в репо.

**Шаг 6. Снимок на VPS и обновление по расписанию**

Из каталога репо cerebro-memory на Mac:

```bash
./deploy/apple-health-push-snapshot.sh
```

**Два снимка (так и задумано):**

1. **Первый раз — базовая история (3 месяца):** один раз выгрузи длинный период для трендов. На Mac:
   ```bash
   APPLE_HEALTH_BASELINE=90 ./deploy/apple-health-push-snapshot.sh
   ```
   Создаётся `apple-health-baseline.md` на VPS (90 дней с агрегацией по дням). Обновлять вручную раз в месяц/квартал при желании.

2. **Каждый день — только свежие данные (7 дней):** по умолчанию скрипт выгружает последние **7 дней** в `apple-health-snapshot.md`. Cron в 21:00 запускает именно это — без лишнего объёма. Агент читает оба файла: baseline для контекста по времени, snapshot для актуальной недели.

Чтобы снимок обновлялся каждый день в **21:00**, добавь задание в cron на Mac.

**Автоматически** (из корня репо на Mac):

```bash
./deploy/setup-apple-health-cron.sh
```

Скрипт добавит в crontab строку `0 21 * * *` (каждый день в 21:00). Если задание уже есть — не дублирует.

**Вручную:** `crontab -e` и строка:

```bash
0 21 * * * cd /путь/к/cerebro-memory && ./deploy/apple-health-push-snapshot.sh
```

(Вечером в 21:00 Mac должен быть включён и в одной сети с iPhone.)

**Как это работает в реальности**

- **Ты ничего не делаешь в 21:00** — задание выполняется само. Cron в 21:00 запускает скрипт на Mac: тот забирает данные с iPhone через healthsync и отправляет снимок на VPS.
- **Что нужно к 21:00:** Mac включён (или выйдет из сна по расписанию), iPhone в той же Wi‑Fi сети, приложение HealthSync Helper на iPhone уже было открыто/привязано (обычно один раз настроил — и всё).
- **Xcode и кабель не нужны** для ежедневного снимка: healthsync работает по Wi‑Fi. Xcode и подключение по кабелю нужны только один раз — чтобы собрать и установить приложение HealthSync Helper на iPhone. Дальше достаточно Mac + iPhone в одной сети.
- **Если в 21:00 Mac был выключен или в другой сети:** этот день снимок не обновится. Можно один раз вручную запустить, когда будешь у Mac:  
  `cd /путь/к/cerebro-memory && ./deploy/apple-health-push-snapshot.sh`
- **Проверить, что cron стоит:** `crontab -l` — должна быть строка с `apple-health-push-snapshot.sh` и `0 21 * * *`.

**Шаг 7 (опционально). Skill для агента на VPS**

Чтобы агент знал форматы и типы данных Health, в workspace на VPS можно добавить skill:

```bash
npx playbooks add skill openclaw/skills --skill healthkit-sync
```

Документация по типам данных и командам — в SKILL.md skill’а.

---

Итог: **ручной путь** — экспорт с телефона → файл → `apple-health-push-snapshot.sh путь/к/файлу`. **Автоматический** — репо [mneves75/ai-health-sync-ios](https://github.com/mneves75/ai-health-sync-ios) и шаги 1–6 выше.

**Дубликат после напоминания («Subagent main finished» + «Готово: дождался … и отправил»):** в OpenClaw **2026.2.25** опция `agents.defaults.subagents.announce = "skip"` **не поддерживается** — при добавлении этого ключа gateway падает с «Unrecognized key: announce». Скрипт `~/cerebro-memory/deploy/subagent-announce-skip.sh` пока **не запускать**. После выхода версии OpenClaw с [PR #13303](https://github.com/openclaw/openclaw/pull/13303) (announce: user|parent|skip) обновите OpenClaw, затем выполните скрипт и перезапуск gateway. Если уже добавили ключ и gateway не стартует — удалить: `jq 'del(.agents.defaults.subagents.announce)' ~/.openclaw/openclaw.json > ~/.openclaw/openclaw.json.tmp && mv ~/.openclaw/openclaw.json.tmp ~/.openclaw/openclaw.json` и `systemctl --user restart openclaw-gateway`.

Логи при проблемах: `journalctl --user -u openclaw-gateway -n 50 --no-pager`.

### Правило

Сначала — только read-only skills. Навыки с write-операциями (почта, календарь, код, доски) добавлять только после явного описания в протоколе и с пониманием рисков.

---

## Второй бот (песочница) — опционально

При необходимости тестировать skills отдельно можно поднять второго Telegram-бота и отдельный workspace (`~/.openclaw/workspace-sandbox`). На текущей установке прод и второй gateway конфликтуют (один порт / перезапуск продового сервиса), поэтому режим «по очереди» или ручной запуск в tmux. Скрипты и юнит в репо не поддерживаются в текущем потоке; skills добавляем по одному в прод (см. `protocols/skills-integration.md`).
