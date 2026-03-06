# System Notes (Aligned) — Cerebro / Clawbot

Этот документ — пояснительная записка к протоколам системы.
Он НЕ задаёт новые правила и НЕ конкурирует с протоколами.
Источник истины: файлы протоколов и доменные протоколы в этой папке.

---

## 1) Канонический нейминг (фиксируем один раз)

Важно: Telegram Topic и Internal Domain могут различаться.

| Telegram Topic | Internal Domain | Primary Agent | Tag |
|---|---|---|---|
| General | general | Chief of Staff | general |
| Work | work | Work Advisor | work-thread |
| Sport | sport | Sport Advisor | sport-thread |
| Health | health | Health Advisor | health-thread |
| Nutrition | food | Food Advisor | nutrition-thread |
| Home | home | Home Advisor | home-thread |
| Finance | finance | Finance Advisor | finance-thread |
| Learning | learning | Learning Advisor | learning-thread |
| Tech | tech | Tech Advisor | tech-thread |

Ключевая договорённость:

- **Topic:** Nutrition  
- **Domain:** food  
- **Agent:** Food Advisor  
- **Folder:** food/

---

## 2) Роутинг и роли

Жёсткая маршрутизация при сообщении из доменного топика: Topic → Primary Agent.

Если запрос мультидоменный — Primary Agent остаётся главным, остальные подключаются как Secondary Advisors.

Chief of Staff: главный оркестратор для General и мультидоменных запросов; собирает план дня/недели; разводит конфликты приоритетов через Advisor Priority Model.

---

## 3) Память и конфликт данных

Главный принцип: «один тип данных — одно место».

Запись данных выполняется только через: **Write Intent → Commit Layer → запись в файл** (по Data Ownership).

**Operational записи:** тренировка, еда, сон, pantry, state  
**Strategic записи** (требуют подтверждения): цели, финансовые решения, системные правила, долгосрочные планы

---

## 4) Владение данными (кратко)

- state/current-state.json → Health (предложения от CoS/Work/Sport)
- health/log-YYYY-MM-DD.md: Status/Sleep/Wellbeing → Health; Training → Sport; Nutrition → Food
- data/home-pantry.md → Home
- food/meal-plan.md, food/preferences.md → Food
- finance/* → Finance
- work/* → Work
- general/* → Chief of Staff

Подробно — см. `protocols/data-ownership.md`.

---

## 5) Контекст (Context Packs + Context Budget)

Агенты не читают всё подряд. Context Builder собирает Context Pack по домену и режет объём по Context Budget.

Если данных нет: не придумывать; задать 1 уточняющий вопрос; предложить создать шаблон файла.

---

## 6) Готовая архитектура

В папке protocols/:

- **Системные протоколы:** execution-flow.md, context-packs.md, context-budget.md, data-ownership.md, write-intent-protocol.md, state-model.md, advisor-priority-model.md, system-consistency-check.md
- **Доменные протоколы:** domains/general.md, domains/work.md, domains/sport.md, domains/health.md, domains/food.md, domains/home.md, domains/finance.md, domains/learning.md, domains/tech.md
- **Заметки:** этот файл (architecture-notes.md)

---

## 7) Changelog (коротко)

- Добавлен домен Work (Work Advisor).
- Зафиксировано: Topic Nutrition → Domain food → Food Advisor → папка food/.
- Зафиксирован owner state/current-state.json → Health.
- Введён Write Intent → Commit Layer вместо прямой записи (целевая архитектура; полный Commit Layer на первом этапе не реализуется).
