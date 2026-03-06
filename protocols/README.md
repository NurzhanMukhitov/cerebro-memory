# Protocols — Cerebro

Правила и архитектура системы Cerebro (Personal AI OS на базе OpenClaw).

## Архитектура (источник истины)

Общая картина и нейминг: **architecture-notes.md**

### Системные протоколы

- **execution-flow.md** — конвейер обработки запроса (Gateway → Router → Context Builder → Agent Execution → Commit Layer)
- **context-packs.md** — какие данные получает каждый агент
- **context-budget.md** — лимиты контекста по агентам (токены)
- **data-ownership.md** — владение файлами и секциями (Owner, кто читает, Write Intent)
- **write-intent-protocol.md** — формат предложений на запись; запись только через Commit Layer (целевая архитектура)
- **state-model.md** — состояние пользователя (state/current-state.json), поведение доменов по состояниям
- **advisor-priority-model.md** — приоритеты доменов при конфликте рекомендаций
- **system-consistency-check.md** — чеклист согласованности архитектуры

### Доменные протоколы (protocols/domains/)

По одному файлу на домен: **general.md**, **work.md**, **sport.md**, **health.md**, **food.md**, **home.md**, **finance.md**, **learning.md**, **tech.md**

В каждом: назначение, Primary Agent, маршрутизация по топику Telegram, источники данных, поведение по state, память, ограничения.

### Прочие протоколы

- **skills-integration.md** — использование внешних skills
- **data-handling.md**, **advisors-autonomy.md**, **confirmation-protocol.md**, **memory-model.md**, **language-policy.md** — операционные правила

## Примечание

state/current-state.json и полный Commit Layer зафиксированы в документах как **целевая архитектура**. На первом этапе полный Commit Layer не реализуется; агенты продолжают использовать существующие механизмы записи в соответствии с core/manifest.md и core/agents.md.
