---
marp: true
theme: default
paginate: true
backgroundColor: #1a1a2e
color: #eaeaea
style: |
  section {
    font-family: 'Segoe UI', Arial, sans-serif;
    font-size: 24px;
  }
  h1 {
    color: #e94560;
    font-size: 52px;
    border-bottom: 3px solid #e94560;
    padding-bottom: 10px;
  }
  h2 {
    color: #0f3460;
    background: #e94560;
    padding: 6px 16px;
    border-radius: 6px;
    display: inline-block;
    font-size: 34px;
  }
  h3 { color: #e94560; }
  code {
    background: #0f3460;
    color: #53d8fb;
    padding: 2px 8px;
    border-radius: 4px;
  }
  table {
    font-size: 22px;
    border-collapse: collapse;
    width: 100%;
    background: #0f1c3f;
  }
  tr { background: #0f1c3f !important; }
  th { background: #e94560 !important; color: white; padding: 8px; }
  td { padding: 8px; border-bottom: 1px solid #2a3a6a; color: #eaeaea; background: #0f1c3f !important; }
  tr:nth-child(even) td { background: #162040 !important; }
  pre { background: #0f1c3f !important; border-radius: 8px; padding: 12px; }
  pre code { background: transparent !important; padding: 0; }
  blockquote {
    border-left: 4px solid #e94560;
    padding-left: 16px;
    color: #aaa;
    font-style: italic;
  }
---

# Дисципліна «Проєкт»

## Заняття 0: Kickoff

**Що ми будуємо? Для кого? Як?**

Весна 2026 · Системний аналіз та управління, 3 курс

---

### Сьогодні не буде теорії

> Ми одразу переходимо до справи.
>
> Сьогодні ви дізнаєтесь, **що** саме будуватимете цього семестру, **для кого** і **навіщо**.
>
> І до кінця заняття — вже **почнете**.

---

## Замовник — реальний

Цей курс не про симуляцію.

Викладач щодня користується системою, яку ви будете розвивати.

Ваш код потрапить у **виробничу систему**.

---

### Знайомтеся: Finance Assistant

**Проблема**: Більшість людей не ведуть особистий бюджет — це нудно і незручно.

**Рішення**: Telegram-бот з AI, якому пишеш як другу:

```text
«Витратив 850 грн на продукти»
«Заробив $500 фріланс»
«Скільки витратив цього місяця?»
```

Бот сам розпізнає суму, валюту, категорію — і зберігає у базу даних.

---

### Як це виглядає?

```text
Ви → Telegram: «Витратив 850 грн на продукти»
          ↓
     AI-агент ClawdBot розпізнає намір
          ↓
     Finance Skill обробляє операцію
          ↓
     PostgreSQL: INSERT INTO fin_transactions(...)
          ↓
     SELECT * FROM fin_transactions WHERE id = ?
          ↓
Бот → Telegram: «✅ Записано: -850 ₴ · Їжа · 10.03.2026»
```

---

### Що ви будуєте?

**Finance Skill** — навичку (TypeScript-модуль) для AI-агента:

- Логування витрат та доходів через природну мову
- Підтримка валют: UAH, USD, EUR, USDT
- Аналітика: «Скільки витратив цього місяця?» → звіт
- Multi-user: кілька членів домогосподарства

> Якщо встигнемо — **Health Skill**: логування симптомів і ліків.

---

### Схема даних вже є

База даних спроєктована. Таблиці визначені.

**Ваша задача** — написати код навички, яка:

1. Приймає природню мову від користувача
2. Розпізнає намір (AI)
3. Зберігає у PostgreSQL
4. Підтверджує операцію

**Схема**: `project/02_Architecture/schemas/001_finance_schema.sql`

---

## Як ми будемо працювати?

---

### Методологія: Scrum

**Зустріч (2 год) = Scrum-церемонії:**

```text
Review → Ретроспектива → Knowledge input → Planning
```

**Між зустрічами (~13 год) = реальна розробка:**

```text
GitHub Issues → feature branch → Pull Request → Code Review → merge
```

- Викладач між зустрічами = **Product Owner у GitHub Issues**
- Обсяг кожного спринту — **адаптивний** за результатами ретро

---

### Ролі в команді

| Роль            | Що робить |
| --------------- | --------- |
| Project Manager | Backlog, спринти, standup |
| **Architect**   | **Архітектурні рішення, ADR, технічне ревʼю** |
| Developer (×2)  | Код + БД |
| QA Engineer     | Тести + ревʼю PR |
| DevOps          | CI/CD pipeline |

---

### Роль Architect — детально

Architect **не пише весь код** — він проєктує рішення:

- Пропонує структуру модуля (які файли, які інтерфейси)
- Фіксує рішення у форматі **ADR** (Architecture Decision Record)
- Проводить технічне ревʼю PR від Developers
- Допомагає команді приймати правильні технічні рішення

> Саме так працює Senior Engineer або Tech Lead у реальній команді.

---

### Викладач = Product Owner

**Що це означає?**

- Ставить вимоги (User Stories)
- Приймає результати Demo
- **Не пише код** — тільки відповідає на питання про функціональність
- Технічні рішення — ваші

> Якщо не знаєте як — гугліть, питайте колег, потім викладача.
> Саме так працює реальна команда.

---

### Розклад: 9 зустрічей

| №  | Дата  | Формат                        |
| -- | ----- | ----------------------------- |
| 0  | 10.03 | **Kickoff** ← ми тут          |
| 1  | 14.03 | Review + Retro + Planning     |
| 2  | 24.03 | Review + Retro + Planning     |
| 3  | 07.04 | Review + Retro + Planning     |
| 4  | 21.04 | Review + Retro + Planning     |
| 5  | 05.05 | Review + Retro + Planning     |
| 6  | 19.05 | Review + Retro + Planning     |
| 7  | 23.05 | Review + Retro + Planning     |
| 8  | 02.06 | **Demo Day** + фінальна ретро |

---

## Сьогодні: Kickoff

### План на 90 хвилин

1. Огляд проєкту та Scrum (15 хв) ← зараз
2. Формування команди, розподіл ролей (15 хв)
3. Налаштування GitHub (20 хв)
4. Огляд `project/`: вимоги, архітектура, схема БД (20 хв)
5. Планування спринту 1: задачі до 14.03 (15 хв)

**Поїхали!**

---

# Запитання?

> Якщо щось незрозуміло — питайте зараз.
> Далі — ми в режимі роботи.
