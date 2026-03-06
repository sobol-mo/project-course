# Implementation — Finance Skill

> Тут буде код навички. Студенти додають файли сюди в процесі роботи над проєктом.

---

## Очікувана структура

```text
10_Implementation/
├── README.md                   ← Ви тут
├── package.json                ← Залежності Node.js (TypeScript, pg, jest)
├── tsconfig.json               ← Конфігурація TypeScript
│
├── src/
│   ├── index.ts                ← Точка входу / реєстрація навички в ClawdBot
│   ├── intent_handlers/
│   │   ├── log_expense.ts      ← Обробка «Витратив X на Y»
│   │   ├── log_income.ts       ← Обробка «Заробив $X за Y»
│   │   └── get_report.ts       ← Обробка «Скільки витратив цього місяця?»
│   ├── parsers/
│   │   ├── currency_parser.ts  ← «грн» → UAH, «$» → USD
│   │   └── category_mapper.ts  ← «продукти» → «Їжа»
│   ├── db/
│   │   ├── connection.ts       ← Підключення до PostgreSQL
│   │   ├── transaction_repo.ts ← CRUD для fin_transactions
│   │   └── category_repo.ts    ← Читання fin_categories
│   └── formatters/
│       └── report_formatter.ts ← Форматування відповідей бота
│
└── tests/
    ├── currency_parser.test.ts
    ├── category_mapper.test.ts
    └── transaction_repo.test.ts
```

---

## Налаштування середовища

### Передумови

- Node.js 20+
- PostgreSQL 14+ (локально або через Docker)
- npm або yarn

### Встановлення

```bash
cd 10_Implementation
npm install
```

### Змінні середовища

Створіть файл `.env` (не додавайте до git):

```env
DATABASE_URL=postgresql://user:password@localhost:5432/finance_assistant
TELEGRAM_BOT_TOKEN=your_token_here
```

### Ініціалізація БД

```bash
# Застосовуємо схему
psql $DATABASE_URL < ../02_Architecture/schemas/001_finance_schema.sql
```

### Запуск тестів

```bash
npm test
```

### Збірка

```bash
npm run build
```
