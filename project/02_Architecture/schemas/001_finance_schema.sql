-- =============================================================================
-- Finance Assistant — Database Schema
-- =============================================================================
-- Project: Finance Skill for ClawdBot
-- Course:  «Проєкт», KhPI, System Analysis and Management, Spring 2026
-- Version: 1.0 (2026-03-10)
-- Compatible with: PostgreSQL 14+
-- =============================================================================

-- Extension for UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


-- =============================================================================
-- 1. USERS
-- =============================================================================

-- User profiles, linked to Telegram accounts
CREATE TABLE IF NOT EXISTS users (
    id            UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    telegram_id   BIGINT      UNIQUE NOT NULL,
    username      VARCHAR(64),
    first_name    VARCHAR(128),
    last_name     VARCHAR(128),
    language_code VARCHAR(5)  DEFAULT 'uk',
    timezone      VARCHAR(50) DEFAULT 'Europe/Kiev',
    created_at    TIMESTAMPTZ DEFAULT NOW(),
    updated_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_telegram_id ON users(telegram_id);

COMMENT ON TABLE users IS 'User profiles, linked to Telegram accounts';


-- =============================================================================
-- 2. CURRENCIES
-- =============================================================================

-- Reference table for supported currencies (fiat + crypto)
CREATE TABLE IF NOT EXISTS currencies (
    code       VARCHAR(10) PRIMARY KEY,       -- UAH, USD, EUR, USDT, USDC
    name       VARCHAR(100) NOT NULL,
    symbol     VARCHAR(10),                   -- ₴, $, €, ₮
    type       VARCHAR(10)  NOT NULL,         -- fiat, crypto
    decimals   INT          DEFAULT 2,        -- 2 for fiat, 6-8 for crypto
    is_active  BOOLEAN      DEFAULT TRUE
);

-- Seed standard currencies
INSERT INTO currencies (code, name, symbol, type, decimals) VALUES
    ('UAH',  'Ukrainian Hryvnia', '₴', 'fiat',   2),
    ('USD',  'US Dollar',         '$', 'fiat',   2),
    ('EUR',  'Euro',              '€', 'fiat',   2),
    ('USDT', 'Tether',            '₮', 'crypto', 6),
    ('USDC', 'USD Coin',          '$', 'crypto', 6)
ON CONFLICT (code) DO NOTHING;

COMMENT ON TABLE currencies IS 'Supported currencies: fiat and crypto';


-- =============================================================================
-- 3. FINANCIAL CATEGORIES
-- =============================================================================

-- Transaction type enum
DO $$ BEGIN
    CREATE TYPE fin_transaction_type AS ENUM ('income', 'expense');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Hierarchical expense/income categories (per user)
CREATE TABLE IF NOT EXISTS fin_categories (
    id               UUID                 PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id          UUID                 REFERENCES users(id) ON DELETE CASCADE,
    transaction_type fin_transaction_type NOT NULL,
    name             VARCHAR(100)         NOT NULL,
    name_normalized  VARCHAR(100),
    parent_id        UUID                 REFERENCES fin_categories(id),  -- Hierarchy support
    icon             VARCHAR(20),
    is_default       BOOLEAN              DEFAULT FALSE,
    created_at       TIMESTAMPTZ          DEFAULT NOW(),

    CONSTRAINT unique_fin_category_per_user
        UNIQUE (user_id, transaction_type, name_normalized)
);

CREATE INDEX IF NOT EXISTS idx_fin_categories_user ON fin_categories(user_id);
CREATE INDEX IF NOT EXISTS idx_fin_categories_type ON fin_categories(transaction_type);

COMMENT ON TABLE fin_categories IS 'Financial categories for income and expenses, per user';


-- =============================================================================
-- 4. ACCOUNTS / WALLETS
-- =============================================================================

-- Where money is stored (bank account, exchange, cash, etc.)
CREATE TABLE IF NOT EXISTS fin_accounts (
    id           UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id      UUID        REFERENCES users(id) ON DELETE CASCADE,
    name         VARCHAR(100) NOT NULL,           -- "Monobank UAH", "Binance", "Cash"
    account_type VARCHAR(20)  NOT NULL,           -- bank, exchange, wallet, cash
    currency     VARCHAR(10)  REFERENCES currencies(code),
    description  TEXT,
    is_active    BOOLEAN      DEFAULT TRUE,
    created_at   TIMESTAMPTZ  DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fin_accounts_user ON fin_accounts(user_id);

COMMENT ON TABLE fin_accounts IS 'Financial accounts and wallets per user';


-- =============================================================================
-- 5. TRANSACTIONS
-- =============================================================================

-- All financial transactions: income and expenses combined
CREATE TABLE IF NOT EXISTS fin_transactions (
    id               UUID                 PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id          UUID                 REFERENCES users(id) ON DELETE CASCADE,
    category_id      UUID                 REFERENCES fin_categories(id),
    account_id       UUID                 REFERENCES fin_accounts(id),

    -- Core fields
    transaction_type fin_transaction_type NOT NULL,
    amount           DECIMAL(18, 8)       NOT NULL,   -- High precision for crypto
    currency         VARCHAR(10)          NOT NULL DEFAULT 'UAH'
                         REFERENCES currencies(code),
    transaction_date DATE                 NOT NULL DEFAULT CURRENT_DATE,

    -- Description
    item_name        VARCHAR(255),                    -- «хліб і молоко», «зарплата за березень»
    description      TEXT,
    counterparty     VARCHAR(255),                    -- АТБ, Work LLC, Client name

    -- Audit trail
    input_method     VARCHAR(20)          DEFAULT 'text',  -- text, voice, photo
    raw_input        TEXT,                                  -- Original user message

    created_at       TIMESTAMPTZ          DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fin_transactions_user     ON fin_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_fin_transactions_date     ON fin_transactions(transaction_date);
CREATE INDEX IF NOT EXISTS idx_fin_transactions_type     ON fin_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_fin_transactions_category ON fin_transactions(category_id);
CREATE INDEX IF NOT EXISTS idx_fin_transactions_currency ON fin_transactions(currency);

COMMENT ON TABLE fin_transactions IS 'Financial transactions log: income and expenses';


-- =============================================================================
-- 6. VIEWS
-- =============================================================================

-- Monthly summary by user, currency and transaction type
CREATE OR REPLACE VIEW fin_monthly_summary AS
SELECT
    user_id,
    DATE_TRUNC('month', transaction_date) AS month,
    transaction_type,
    currency,
    SUM(amount)   AS total_amount,
    COUNT(*)      AS transaction_count
FROM fin_transactions
GROUP BY
    user_id,
    DATE_TRUNC('month', transaction_date),
    transaction_type,
    currency;

COMMENT ON VIEW fin_monthly_summary IS 'Monthly totals per user, currency and transaction type';


-- =============================================================================
-- 7. DEFAULT CATEGORIES (auto-created for new users)
-- =============================================================================

-- Function: create default categories for a new user
CREATE OR REPLACE FUNCTION create_default_fin_categories(p_user_id UUID)
RETURNS void AS $$
BEGIN
    -- Expense categories
    INSERT INTO fin_categories (user_id, transaction_type, name, name_normalized, icon, is_default)
    VALUES
        (p_user_id, 'expense', 'Їжа',          'їжа',          '🍔', TRUE),
        (p_user_id, 'expense', 'Транспорт',     'транспорт',    '🚗', TRUE),
        (p_user_id, 'expense', 'Здоровʼя',     'здоровя',      '💊', TRUE),
        (p_user_id, 'expense', 'Розваги',       'розваги',      '🎬', TRUE),
        (p_user_id, 'expense', 'Комунальні',    'комунальні',   '🏠', TRUE),
        (p_user_id, 'expense', 'Одяг',          'одяг',         '👕', TRUE),
        (p_user_id, 'expense', 'Звʼязок',      'звязок',       '📱', TRUE),
        (p_user_id, 'expense', 'Інше',          'інше',         '📦', TRUE);

    -- Income categories
    INSERT INTO fin_categories (user_id, transaction_type, name, name_normalized, icon, is_default)
    VALUES
        (p_user_id, 'income', 'Зарплата',    'зарплата',    '💰', TRUE),
        (p_user_id, 'income', 'Фріланс',     'фріланс',     '💼', TRUE),
        (p_user_id, 'income', 'Подарунок',   'подарунок',   '🎁', TRUE),
        (p_user_id, 'income', 'Інвестиції',  'інвестиції',  '📈', TRUE),
        (p_user_id, 'income', 'Інше',        'інше',        '📦', TRUE);
END;
$$ LANGUAGE plpgsql;


-- Trigger: auto-create default categories when a new user is registered
CREATE OR REPLACE FUNCTION trigger_create_default_fin_categories()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM create_default_fin_categories(NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_user_created_fin_categories ON users;
CREATE TRIGGER tr_user_created_fin_categories
    AFTER INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION trigger_create_default_fin_categories();


-- =============================================================================
-- 8. UPDATED_AT TRIGGER
-- =============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_users_updated_at ON users;
CREATE TRIGGER tr_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();


-- =============================================================================
-- END OF SCHEMA
-- =============================================================================
