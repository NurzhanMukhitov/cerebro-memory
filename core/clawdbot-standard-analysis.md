# OpenClaw / Clawdbot: как настраивают стандартно и как у нас (Cerebro)

Документ для выравнивания с общепринятой настройкой OpenClaw и снижения «своего пути» там, где это не нужно.

---

## 1. Как устроен OpenClaw по документации и гайдам

### 1.1 Workspace и bootstrap-файлы

**Стандарт (docs.openclaw.ai, Agent Workspace):**

- Workspace по умолчанию: `~/.openclaw/workspace` (или `workspace-{PROFILE}`).
- Файлы в workspace задают поведение агента; они **инжектятся в контекст каждый раз** (при лимите символов).
- Назначение файлов:
  - **SOUL.md** — персона, тон, границы, «как себя вести». Правила, приоритеты, границы.
  - **USER.md** — кто пользователь, как к нему обращаться.
  - **IDENTITY.md** — имя агента, «вайб», эмодзи (создаётся при bootstrap).
  - **AGENTS.md** — как агент работает с памятью и инструментами, операционные инструкции.
  - **TOOLS.md** — заметки о локальных инструментах и соглашениях (не управляет доступом к tools).
  - **BOOTSTRAP.md** — одноразовый ритуал первого запуска (Q&A), после выполнения удаляется.
  - **HEARTBEAT.md**, **MEMORY.md**, **memory/** — опционально.
- **Bootstrap-ритуал:** при первом запуске OpenClaw задаёт вопросы (имя, эмодзи, стиль), пишет в IDENTITY, USER, SOUL.
- **Лимиты:** большие файлы обрезаются: `bootstrapMaxChars` (по умолчанию 20 000), `bootstrapTotalMaxChars` (150 000). Рекомендация — держать файлы короткими.
- **Skills:** в workspace может быть папка `skills/`; навыки также грузятся из `~/.openclaw/skills` и bundled. Установка через ClawHub: `clawhub install <skill>` в workspace.

### 1.2 SOUL.md — лучшие практики (по статьям/гайдам)

- Чёткие, недвусмысленные границы (что никогда не логировать, не передавать).
- Жёсткие формулировки («You MUST refuse…») лучше размытых («try not to…»).
- Разделы: Security, Financial, Tool restrictions, User-facing.
- SOUL — это именно персона и границы, а не единственный файл на все темы.

### 1.3 Архитектура из видео (Clawdbot Tutorial)

- **LLM** — подключаемая модель (Claude, GPT, MiniMax и т.д.).
- **Computer Control** — браузер, UI, shell, файлы, экран.
- **Memory** — долговременная, контекстная, по проектам.
- **Messaging** — Telegram, WhatsApp, iMessage, Discord.
- Цикл: запрос → планирование → шаг действия → выполнение → результат → анализ → продолжать/закончить → запись в память.
- Кастомный system prompt задаёт роль, стиль, ограничения, цели.
- Skills Marketplace — расширяемая архитектура (кастомные навыки, интеграции).

### 1.4 Где живут конфиг и секреты

- **В workspace (в репо):** SOUL, USER, IDENTITY, AGENTS, TOOLS, memory/, skills/.
- **Не в workspace (не коммитить):** `~/.openclaw/openclaw.json`, credentials/, sessions/, managed skills в `~/.openclaw/skills/`.

---

## 2. Как устроено у нас (Cerebro)

### 2.1 Workspace и файлы

- **SOUL:** не файл внутри workspace, а симлинк **`~/.openclaw/SOUL.md` → `~/cerebro-memory/core/manifest.md`**. То есть один большой манифест (27k+ символов) играет роль SOUL.
- **USER:** симлинк **`~/.openclaw/workspace/USER.md` → `~/cerebro-memory/core/user-profile.md`**. Совпадаем со стандартом по смыслу (профиль пользователя).
- **IDENTITY.md, AGENTS.md, TOOLS.md** в workspace **не создаём**. Вся логика (роль, советники, протоколы, календарь, время, границы) — в одном `manifest.md` = SOUL.
- **Bootstrap-ритуал** не используем: манифест и профиль ведём в репо cerebro-memory, не через Q&A OpenClaw.
- **Репо:** стратегический слой (manifest, identity, user-profile, protocols) и деплой — в одном репо; на VPS клонируем cerebro-memory и подвязываем симлинки.

### 2.2 Отличия от стандарта

| Аспект | Стандарт OpenClaw | Cerebro |
|--------|-------------------|---------|
| SOUL | Отдельный файл в workspace, «персона + границы», советуют держать коротким | Один файл (manifest) 27k+ символов, всё в одном; обрезается до 20k |
| Разделение ролей файлов | SOUL + IDENTITY + USER + AGENTS + TOOLS | По сути только SOUL (manifest) + USER (profile) |
| Bootstrap | Q&A ритуал, создаёт/обновляет файлы | Нет, файлы из репо |
| Skills | ClawHub, установка в workspace/skills | То же, но с фазой «сначала read-only» и протоколом |
| Память | MEMORY.md, memory/, модель из доки | Своя модель (Working Notes, Strategic, Ledger) описана в манифесте |
| Деплой | Обычно одна машина / свой workspace | VPS, репо, симлинки, run-on-vps, Deploy Key |

### 2.3 Где мы «своим путём»

1. **Один огромный SOUL** — весь манифест (советники, Decision Framework, протоколы, календарь, время) в одном файле. Стандарт: несколько файлов, каждый в пределах лимита.
2. **Обрезка контекста** — 27k обрезается до 20k; конец манифеста (часть правил) может не попадать в контекст. У других обычно несколько файлов, каждый короче.
3. **Нет IDENTITY/AGENTS/TOOLS** — не используем стандартные имена и разделение; всё в манифесте.
4. **Жёсткие протоколы в репо** — protocols/, Decision Ledger, фазность skills — это осознанный продукт (Cerebro = Executive AI Office), а не «как у всех».

---

## 3. Выводы и рекомендации

### 3.1 Что разумно приблизить к стандарту

- **Разнести контент по ролям файлов (как в доке):**
  - **SOUL.md** — только персона, тон, незыблемые границы, время, календарь, «сначала вызывай tools» (коротко, в пределах ~15–20k).
  - **AGENTS.md** — как работать с памятью, когда звать советников, операционные инструкции (отдельно из манифеста).
  - **USER.md** — оставить как есть (профиль из репо).
  - При желании добавить **IDENTITY.md** (имя, эмодзи) и короткий **TOOLS.md** (подсказки по инструментам).
- Так каждый файл будет попадать в лимит, меньше обрезки, модель стабильнее видит правила про время/календарь/tools.
- **bootstrapMaxChars** при необходимости можно поднять в `~/.openclaw/openclaw.json` (например до 25k), но лучше сначала сократить и разнести SOUL.

### 3.2 Что можно оставить как есть

- **Репо + симлинки на VPS** — нормальная схема «workspace из репо»; в доке рекомендуют git для workspace.
- **USER из репо** — соответствует стандарту по смыслу.
- **Skills через ClawHub** — так и делают; наша фазность (read-only сначала) и протокол — продуктовая политика, не противоречит архитектуре.
- **Деплой (phase-скрипты, run-on-vps, Deploy Key)** — удобная автоматизация, не конфликтует со стандартом.
- **Концепция Cerebro** (Executive AI Office, советники, Decision Framework) — осознанная надстройка над OpenClaw; её не нужно убирать, достаточно лучше вписать в стандартную раскладку файлов.

### 3.3 Практические шаги (по приоритету)

1. ~~**Изучить текущий manifest.md** и выделить блоки~~ — **выполнено.**
2. ~~**Сократить то, что остаётся в SOUL**~~ — **выполнено:** manifest.md ~10k символов, операционные инструкции перенесены в core/agents.md.
3. **На VPS:** завести в workspace симлинк `AGENTS.md` → `~/cerebro-memory/core/agents.md` (см. deploy/README.md, фаза 3).
4. ~~**Документировать**~~ — **выполнено:** таблица SOUL/USER/AGENTS в deploy/README.md.

### 3.4 Соответствие репо ↔ workspace (после рефактора)

| Файл OpenClaw (workspace) | Файл в репо cerebro-memory | Роль |
|---------------------------|----------------------------|------|
| SOUL.md | core/manifest.md | Персона, границы, время, календарь, output policy, language, memory disclosure, user profile hook. ~10k символов. |
| USER.md | core/user-profile.md | Профиль пользователя. |
| AGENTS.md | core/agents.md | Chief of Staff, Memory Model, Confirmation Protocol, Decision Framework, все советники (Sport, Work, Health, Finance, Learning), Decision Ledger. ~37k символов. |

---

## 4. Ссылки

- [Agent Workspace](https://docs.openclaw.ai/concepts/agent-workspace) — структура workspace, карта файлов, лимиты.
- [Agent Bootstrapping](https://docs.openclaw.ai/start/bootstrapping) — первый запуск, Q&A, запись в SOUL/USER/IDENTITY.
- SOUL.md best practices (openclawexperts, thecaio) — короткий SOUL, чёткие границы, абсолютные формулировки.
- Видео: Ultimate Clawdbot Tutorial (AI Master) — архитектура LLM + Computer Control + Memory + Messaging, цикл выполнения, skills.
