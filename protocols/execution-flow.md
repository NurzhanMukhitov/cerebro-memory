# Execution Flow

Execution Flow описывает, как система Cerebro обрабатывает любой пользовательский
запрос.

Каждое сообщение проходит через стандартный конвейер обработки.
Это делает поведение системы предсказуемым и предотвращает конфликт между
агентами.

---

# Общая схема обработки

Каждый запрос проходит 5 этапов:

1. Gateway
2. Router
3. Context Builder
4. Agent Execution
5. Commit Layer

---

# 1. Gateway

Gateway получает сообщение из Telegram и формирует стандартный объект запроса.

Пример Message Envelope:

```json
{
    "user_id": "user_1",
    "timestamp": "2026-03-05T10:21:00",
    "topic": "Sport",
    "topic_tag": "sport-thread",
    "message_text": "Можно ли сегодня тренироваться?",
    "attachments": []
}
```

Gateway не принимает решений.
Его задача — нормализовать входные данные и передать метку топика.

---

# 2. Router

Router определяет Primary Agent.

Если сообщение приходит из доменного топика Telegram, используется жёсткая
маршрутизация.

| Topic (Telegram) | Primary Agent |
|---|---|
| General | Chief of Staff |
| Work | Work Advisor |
| Sport | Sport Advisor |
| Health | Health Advisor |
| Nutrition | Food Advisor |
| Home | Home Advisor |
| Finance | Finance Advisor |
| Learning | Learning Advisor |
| Tech | Tech Advisor |

Если сообщение содержит мультидоменный контекст, Router может подключить
Secondary Advisors.

Примеры:

- Sport + Health
- Nutrition + Finance
- Work + Learning
- Home + Finance

---

# 3. Context Builder

Context Builder собирает Context Pack для выбранного агента.

Context Packs описаны в файле:

`protocols/context-packs.md`

Агент получает только необходимые данные.

Если нужный файл отсутствует:

1. система не придумывает данные
2. агент задаёт уточняющий вопрос
3. система предлагает создать файл-шаблон

---

# 4. Agent Execution

Primary Agent выполняет анализ запроса:

1. анализирует сообщение пользователя
2. применяет правила своего домена
3. использует Context Pack
4. формирует ответ пользователю

Если требуется изменить данные системы, агент создаёт Write Intent.

Агенты **не изменяют файлы напрямую**.

---

# Write Intent

Write Intent — это предложение изменить данные системы.

Пример:

```json
{
    "intent_type": "memory_write",
    "domain_owner": "Sport",
    "target_file": "health/log-2026-03-05.md",
    "section": "Training",
    "operation": "append",
    "content": "Велотренировка 40 км, зона 2",
    "source_agent": "Sport Advisor",
    "confidence": "high",
    "requires_confirmation": false
}
```

Формат Write Intent описан в:

`protocols/write-intent-protocol.md`

---

# 5. Commit Layer

Commit Layer отвечает за запись данных.

Он проверяет:

1. владельца данных (Data Ownership)
2. структуру файла
3. конфликт изменений
4. необходимость подтверждения пользователя

Правила владения данными описаны в:

`protocols/data-ownership.md`

---

# Operational и Strategic запись

## Operational Memory

Может записываться без подтверждения пользователя:

- запись тренировки
- запись еды
- обновление pantry
- запись сна
- обновление state

## Strategic Memory

Требует подтверждения пользователя:

- новая цель
- финансовое решение
- изменение приоритетов
- изменение правил системы

---

# State Model

Перед выполнением запроса система учитывает текущее состояние пользователя.

Источник состояния:

`state/current-state.json`

Описание модели состояния:

`protocols/state-model.md`

---

# Advisor Priority

Если рекомендации нескольких агентов конфликтуют, используется модель приоритетов.

Описание приоритетов:

`protocols/advisor-priority-model.md`

---

# Итог

Execution Flow обеспечивает:

- единый путь обработки запросов
- разделение ответственности между агентами
- безопасную запись данных
- предсказуемое поведение системы
