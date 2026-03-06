# Write Intent Protocol

Write Intent Protocol описывает, как агенты системы предлагают изменения в
данных.

Агенты **не изменяют файлы напрямую**.
Любое изменение данных проходит через механизм Write Intent.

Это предотвращает:

- конфликт памяти
- неконтролируемую запись данных
- повреждение структуры файлов

---

# Основной принцип

Агент формирует **Write Intent** — предложение изменить данные.

Write Intent передаётся в Commit Layer, который:

1. проверяет владельца данных (Data Ownership)
2. проверяет структуру данных
3. проверяет необходимость подтверждения пользователя
4. выполняет запись

---

# Структура Write Intent

Write Intent имеет стандартный формат.

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

| Поле | Описание |
|---|---|
| intent_type | тип операции |
| domain_owner | владелец данных |
| target_file | файл для изменения |
| section | секция файла |
| operation | тип операции |
| content | данные для записи |
| source_agent | агент, инициировавший запись |
| confidence | уровень уверенности |
| requires_confirmation | требуется ли подтверждение |

Типы операций:

| Operation | Описание |
|---|---|
| append | добавить запись |
| update | обновить значение |
| replace | заменить секцию |
| delete | удалить запись |

---

# Operational записи

Некоторые записи могут выполняться без подтверждения пользователя.

Примеры:

- запись тренировки
- запись еды
- обновление pantry
- запись сна
- обновление state

---

# Strategic записи

Некоторые изменения требуют подтверждения пользователя.

Примеры:

- финансовые решения
- цели
- изменение планов
- изменение системных правил

В таких случаях поле `requires_confirmation` устанавливается в `true`.

---

# Commit Layer

Commit Layer проверяет:

1. владельца данных (Data Ownership)
2. корректность структуры
3. конфликт изменений
4. необходимость подтверждения пользователя

Только после проверки выполняется запись.

---

# Связь с другими протоколами

Write Intent используется вместе с:

- Execution Flow — `protocols/execution-flow.md`
- Data Ownership — `protocols/data-ownership.md`
- State Model — `protocols/state-model.md`
