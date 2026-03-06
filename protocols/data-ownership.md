# Data Ownership Matrix

Data Ownership Matrix определяет:

- какой домен владеет данными (Owner)
- кто может читать данные
- кто может предлагать изменения через Write Intent

Цель — предотвратить конфликт памяти между агентами.

---

# Основной принцип

1. У каждого файла один владелец (Owner).
2. Владелец отвечает за структуру и корректность данных.
3. Другие агенты могут предлагать изменения только через Write Intent.
4. Запись в файлы выполняется только через Commit Layer.

---

# Владение файлами

| Файл | Owner | Кто читает |
|---|---|---|
| state/current-state.json | Health | все домены |
| health/log-YYYY-MM-DD.md | Health (см. секции ниже) | Sport, Food, Chief of Staff |
| data/home-pantry.md | Home | Food, Chief of Staff |
| food/meal-plan.md | Food | Home |
| food/preferences.md | Food | — |
| finance/budget.md | Finance | Chief of Staff |
| finance/ledger.md | Finance | Chief of Staff |
| general/inbox.md | Chief of Staff | — |
| general/weekly-plan.md | Chief of Staff | Work |
| home/tasks.md | Home | Chief of Staff |
| work/tasks.md | Work | Chief of Staff |
| work/projects.md | Work | Chief of Staff |
| learning/goals.md | Learning | Chief of Staff |
| learning/plan.md | Learning | Chief of Staff |

---

# Владение секциями health log

Файл `health/log-YYYY-MM-DD.md` имеет владельцев по секциям.

| Section | Owner | Кто читает |
|---|---|---|
| Status | Health | Sport, Chief of Staff |
| Sleep | Health | Chief of Staff |
| Wellbeing | Health | Chief of Staff |
| Training | Sport | Health, Chief of Staff |
| Nutrition | Food | Health, Chief of Staff |

---

# Правило обновления state

Источник состояния пользователя:

`state/current-state.json`

Owner — **Health**.

Кто может предлагать обновление состояния:

- Health
- Chief of Staff
- Work
- Sport

Но запись происходит только через Commit Layer.

---

# Operational записи

Могут выполняться без подтверждения пользователя:

- запись тренировок
- запись еды
- обновление pantry
- обновление inbox
- обновление tasks
- обновление state

---

# Strategic записи

Требуют подтверждения пользователя:

- цели
- долгосрочные планы
- финансовые решения
- изменение правил системы
- изменение приоритетов

---

# Commit Layer

Commit Layer проверяет:

1. владельца файла
2. корректность структуры
3. конфликт изменений
4. необходимость подтверждения пользователя

---

# Итог

Data Ownership Matrix обеспечивает:

- один источник истины для каждого типа данных
- отсутствие конфликтов между агентами
- безопасную запись через Commit Layer
