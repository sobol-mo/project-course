# Архітектура системи: Finance Assistant

**Версія**: 1.0
**Дата**: 2026-03-10

---

## Огляд

Finance Assistant — це **навичка (skill)** AI-агента ClawdBot. Вона не є окремим застосунком — це модуль, який розширює існуючого агента здатністю розуміти і обробляти фінансові повідомлення.

```
Telegram User
     │
     │  «Витратив 850 грн на продукти»
     ▼
  ClawdBot (AI Agent)
     │
     ├─ Розпізнає намір: log_expense
     ├─ Витягує: amount=850, currency=UAH, category=Їжа
     │
     ▼
  Finance Skill (наш модуль)
     │
     ├─ Зберігає у PostgreSQL → fin_transactions
     ├─ Зчитує збережений запис (Commit-Recall-Verify)
     │
     ▼
  ClawdBot → Telegram: «✅ Записано: -850 ₴ · Їжа · 10.03.2026»
```

---

## Компоненти системи

### 1. ClawdBot (існуючий, не модифікуємо ядро)

AI-агент на TypeScript/Node.js. Обробляє повідомлення від Telegram, визначає намір користувача і делегує виконання відповідній навичці.

Наш модуль підключається до ClawdBot як **custom skill**.

### 2. Finance Skill (наш модуль — будуємо з нуля)

TypeScript-модуль, який реалізує логіку Finance Assistant:

```
Finance Skill
├── intent_handlers/
│   ├── log_expense.ts        ← Обробка «Витратив X грн на Y»
│   ├── log_income.ts         ← Обробка «Заробив $X на Y»
│   └── get_report.ts         ← Обробка «Скільки витратив цього місяця?»
│
├── parsers/
│   ├── currency_parser.ts    ← «грн» → UAH, «$» → USD
│   └── category_mapper.ts    ← «продукти» → «Їжа»
│
├── db/
│   ├── transaction_repo.ts   ← CRUD для fin_transactions
│   └── category_repo.ts      ← Читання fin_categories
│
└── formatters/
    └── report_formatter.ts   ← Форматування відповіді бота
```

### 3. PostgreSQL (база даних)

Зберігає всі фінансові дані. Схема визначена в [`schemas/001_finance_schema.sql`](./schemas/001_finance_schema.sql).

Принцип: **жодних бізнес-даних у пам'яті агента** — тільки у БД.

---

## Ключові архітектурні принципи

### Commit-Recall-Verify

Кожна операція збереження даних виконується за трьома кроками:

1. **Commit** — записуємо у БД
2. **Recall** — зчитуємо збережений запис з БД
3. **Verify** — відправляємо підтвердження користувачу з даними, які реально збережені

Це гарантує, що користувач завжди бачить те, що насправді є в базі даних.

```typescript
// Приклад (псевдокод)
const saved = await transactionRepo.save(transaction); // Commit
const recalled = await transactionRepo.findById(saved.id); // Recall
return formatConfirmation(recalled); // Verify
```

### Data Sovereignty

Всі дані зберігаються в PostgreSQL під контролем власника системи.
Ніякі персональні фінансові дані не відправляються до зовнішніх сервісів окрім тексту запиту до AI для розпізнавання наміру.

### Single Source of Truth

Схема БД — єдине джерело правди про структуру даних.
Будь-які зміни до структури даних вносяться тільки через SQL-міграцію.

### No Auto-Conversion

Валюти зберігаються строго в оригіналі. Система не конвертує UAH у USD автоматично. Звіти показують суми по кожній валюті окремо.

---

## Потоки даних

### Запис операції

```
1. Telegram → ClawdBot: «Витратив 850 грн на продукти»
2. ClawdBot → LLM: визначити намір і параметри
3. LLM → ClawdBot: { intent: "log_expense", amount: 850, currency: "UAH", description: "продукти" }
4. ClawdBot → Finance Skill: log_expense(params)
5. Finance Skill → currency_parser: "UAH"
6. Finance Skill → category_mapper: "Їжа"
7. Finance Skill → PostgreSQL: INSERT INTO fin_transactions(...)
8. Finance Skill → PostgreSQL: SELECT * FROM fin_transactions WHERE id = ?
9. Finance Skill → ClawdBot: "✅ Записано: -850 ₴ · Їжа · 10.03.2026"
10. ClawdBot → Telegram: надсилає підтвердження
```

### Аналітичний запит

```
1. Telegram → ClawdBot: «Скільки витратив цього місяця?»
2. ClawdBot → LLM: визначити намір і параметри
3. LLM → ClawdBot: { intent: "get_report", period: "current_month", user_id: 123 }
4. ClawdBot → Finance Skill: get_report(params)
5. Finance Skill → PostgreSQL: SELECT ... GROUP BY currency
6. Finance Skill → report_formatter: форматує результат
7. Finance Skill → ClawdBot: «📊 Березень 2026:\n-12 450 ₴\n-$230\nТранзакцій: 34»
8. ClawdBot → Telegram: надсилає звіт
```

---

## Схема бази даних

Повна схема: [`schemas/001_finance_schema.sql`](./schemas/001_finance_schema.sql)

### Ключові таблиці

| Таблиця           | Призначення                                    |
| ----------------- | ---------------------------------------------- |
| `users`           | Профілі користувачів (Telegram ID)             |
| `currencies`      | Довідник валют (UAH, USD, EUR, USDT, USDC)     |
| `fin_categories`  | Ієрархічні категорії витрат і доходів          |
| `fin_accounts`    | Рахунки/гаманці (банк, біржа, готівка)         |
| `fin_transactions` | Всі фінансові операції                        |

### Ключові view

| View                   | Призначення                                  |
| ---------------------- | -------------------------------------------- |
| `fin_monthly_summary`  | Зведені витрати/доходи по місяцях            |

---

## Архітектурні рішення (ADR)

Команда фіксує архітектурні рішення у вигляді ADR (Architecture Decision Record).
Architect створює ADR-файл для кожного значущого рішення за шаблоном:

```markdown
# ADR-001: [Назва рішення]

**Статус**: Прийнято | Відхилено | Замінено
**Дата**: YYYY-MM-DD
**Автор**: [ім'я Architect]

## Контекст
[Яка проблема або питання потребувало рішення?]

## Розглянуті варіанти
1. [Варіант A] — [плюси/мінуси]
2. [Варіант B] — [плюси/мінуси]

## Прийняте рішення
[Який варіант обрано і чому]

## Наслідки
[Що змінюється в результаті цього рішення]
```

ADR-файли зберігаються у `02_Architecture/decisions/`.
