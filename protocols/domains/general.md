# Чат / топик «General»

## Назначение

General является основным входом в систему Cerebro.

Этот чат используется для:

- мультидоменных вопросов
- планирования дня и недели
- приоритизации задач
- общего анализа жизни пользователя

General выполняет роль оркестратора всей системы.

## Агент домена

**Primary Agent:** Chief of Staff

Chief of Staff (CoS) отвечает за:

- координацию доменов
- выявление конфликтов рекомендаций
- приоритизацию задач
- стратегический обзор

## Маршрутизация

Если сообщение приходит из топика **General**, gateway назначает:

- **Primary Agent:** Chief of Staff  
- **Tag:** general-thread  

Chief of Staff может подключать другие домены.

| Домен | Когда подключается |
|---|---|
| Health | самочувствие |
| Sport | тренировки |
| Food | питание |
| Finance | деньги |
| Home | бытовые задачи |
| Learning | обучение |
| Tech | системные вопросы |

## Типичные запросы

- Что в приоритете сегодня?
- Суммируй неделю
- Как распределить задачи?
- Что делать дальше?
- Как сбалансировать работу и тренировки?

## Обязательные источники данных

Chief of Staff использует:

- state/current-state.json
- calendar/today, calendar/next-7-days
- general/inbox.md
- general/weekly-plan.md
- health/log-last-7-days-summary
- Strategic Memory, Working Memory

## Память General

Файлы: **general/inbox.md** (входящие задачи), **general/weekly-plan.md** (план недели).

**Operational** (без подтверждения): general/inbox.md, general/weekly-plan.md

**Strategic** (требует подтверждения): цели, долгосрочные планы, правила системы

## Разрешение конфликтов

При конфликте рекомендаций используется Advisor Priority Model.

Приоритет: Health > Finance > Work > Chief of Staff > Sport > Food > Home > Learning > Tech

Chief of Staff объясняет пользователю конфликт.

## Учёт состояния пользователя

Источник: state/current-state.json

| State | Поведение |
|---|---|
| HIGH_LOAD | уменьшить нагрузку |
| RECOVERY | снизить активность |
| FOCUS_WORK | приоритет работе |
| NORMAL | обычный режим |

## Ограничения

Chief of Staff не даёт медицинских рекомендаций, не принимает финансовые решения, не игнорирует ограничения Health.

## Итог

General Domain — центр системы. Chief of Staff выступает как операционный менеджер Personal AI OS.
