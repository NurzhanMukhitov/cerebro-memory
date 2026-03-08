# Context Packs

Context Packs определяют, какие данные агент получает перед обработкой запроса.

Цель Context Packs — обеспечить агенту необходимый контекст, не перегружая систему
лишними данными.

Каждый доменный агент имеет свой Context Pack.

---

# Общие правила

1. Агент получает только данные своего домена.
2. Дополнительные данные могут загружаться из связанных доменов.
3. Если файл отсутствует, система не придумывает данные.
4. Context Builder использует summaries, если файлы слишком большие.

---

# Общие данные для всех агентов

Все агенты получают базовый системный контекст.

| Данные | Файл |
|---|---|
| состояние пользователя | state/current-state.json |
| общий inbox | general/inbox.md |
| недельный план | general/weekly-plan.md |

---

# Chief of Staff

Chief of Staff получает обзор всей системы.

| Данные | Файл |
|---|---|
| состояние пользователя | state/current-state.json |
| inbox | general/inbox.md |
| недельный план | general/weekly-plan.md |
| задачи работы | work/tasks.md |
| проекты | work/projects.md |
| домашние задачи | home/tasks.md |
| бюджет | finance/budget.md |
| pantry | data/home-pantry.md |

---

# Work Advisor

Work Advisor работает с задачами и проектами.

| Данные | Файл |
|---|---|
| состояние пользователя | state/current-state.json |
| задачи | work/tasks.md |
| проекты | work/projects.md |
| недельный план | general/weekly-plan.md |

---

# Sport Advisor

Sport Advisor анализирует тренировки и нагрузку.

| Данные | Файл |
|---|---|
| состояние пользователя | state/current-state.json |
| health log | health/log-YYYY-MM-DD.md |
| последние тренировки | Strava |
| заметки о здоровье | health/log-last-7-days-summary |

---

# Health Advisor

Health Advisor анализирует состояние здоровья.

| Данные | Файл |
|---|---|
| состояние пользователя | state/current-state.json |
| health log | health/log-YYYY-MM-DD.md |
| сон | Apple Health |
| пульс и HRV | Apple Health |

---

# Food Advisor

Food Advisor работает с питанием и продуктами.

Telegram topic: **Nutrition**

| Данные | Файл |
|---|---|
| состояние пользователя | state/current-state.json |
| питание за день | health/log-YYYY-MM-DD.md |
| pantry | data/home-pantry.md |
| предпочтения | food/preferences.md |
| план питания | food/meal-plan.md |

---

# Home Advisor

Home Advisor управляет бытовыми задачами.

| Данные | Файл |
|---|---|
| состояние пользователя | state/current-state.json |
| домашние задачи | home/tasks.md |
| pantry | data/home-pantry.md |

---

# Finance Advisor

Finance Advisor анализирует бюджет и расходы.

| Данные | Файл |
|---|---|
| состояние пользователя | state/current-state.json |
| бюджет | finance/budget.md |
| операции | finance/ledger.md |

---

# Learning Advisor

Learning Advisor работает с обучением.

| Данные | Файл |
|---|---|
| состояние пользователя | state/current-state.json |
| цели обучения | learning/goals.md |
| план обучения | learning/plan.md |

---

# Tech Advisor

Tech Advisor работает с технической инфраструктурой.

| Данные | Файл |
|---|---|
| состояние пользователя | state/current-state.json |
| deploy инструкции | deploy/README.md |
| протокол skills | protocols/skills-integration.md |
| системные логи | gateway logs |

---

# Поведение при отсутствии данных

Если нужный файл отсутствует **после попытки его прочитать**:
1. Агент сообщает, что файл не найден или пуст.
2. Предлагает создать шаблон файла или ввести данные вручную.
3. Не придумывает содержимое.

**Важно:** «файл отсутствует» — только после вызова read. Нельзя сообщать «нет данных», не попытавшись прочитать файл.

**Кросс-доменные данные:** агент может читать файлы из других доменов, если запрос или рекомендация этого требуют (см. Cross-Domain Data Rule в manifest.md). Правило «агент получает только данные своего домена» — про первичный контекст, не про запрет читать другие файлы при необходимости.

---

# Итог

Context Packs обеспечивают:

- ограниченный и релевантный контекст
- устойчивую работу агентов
- предотвращение перегрузки контекста
