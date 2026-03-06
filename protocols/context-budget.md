# Context Budget

Context Budget определяет максимальный объём контекста, который агент может
загрузить перед обработкой запроса.

Цель — предотвратить перегрузку контекста и сохранить стабильную работу системы.

Без ограничения контекста агенты могут:

- загружать слишком много данных
- замедлять систему
- терять релевантность информации

Context Budget ограничивает объём данных, которые может использовать агент.

---

# Основной принцип

Каждый агент имеет лимит контекста.

Context Builder должен:

1. загрузить обязательные данные
2. добавить релевантные данные
3. добавить дополнительные данные, если позволяет бюджет

---

# Бюджет агентов

| Agent | Максимальный бюджет |
|---|---|
| Chief of Staff | 12000 tokens |
| Health Advisor | 8000 tokens |
| Sport Advisor | 6000 tokens |
| Food Advisor | 6000 tokens |
| Finance Advisor | 6000 tokens |
| Work Advisor | 6000 tokens |
| Home Advisor | 4000 tokens |
| Learning Advisor | 4000 tokens |
| Tech Advisor | 4000 tokens |

---

# Приоритет загрузки данных

Context Builder использует три уровня данных.

## Mandatory Context

Обязательные данные, которые всегда загружаются.

Пример:

- state/current-state.json
- health/log-YYYY-MM-DD.md

## Relevant Context

Загружается при необходимости.

Пример:

- health/log-last-7-days-summary
- Strava-last-7-days

## Optional Context

Загружается только если остаётся место в бюджете.

Пример:

- health/log-last-28-days-summary
- long-term-trends

---

# Пример Context Budget (Sport)

Mandatory: 2000 tokens  
Relevant: 2000 tokens  
Optional: 2000 tokens  

Total: 6000 tokens

---

# Context Compression

Если файл слишком большой, используется summary.

Например:

вместо `health/log-last-30-days`  
используется `health/log-last-30-days-summary`

---

# Поведение при превышении бюджета

Если контекст превышает лимит:

Context Builder должен:

1. удалить optional context
2. сократить summaries
3. оставить только mandatory context

---

# Связь с другими протоколами

Context Budget используется на этапе Context Builder.

- Execution Flow — `protocols/execution-flow.md`
- Context Packs — `protocols/context-packs.md`

---

# Итог

Context Budget обеспечивает:

- быстрые ответы системы
- стабильную работу агентов
- отсутствие перегрузки контекста
