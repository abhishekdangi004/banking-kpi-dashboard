-- ===========================================================================
-- Banking KPI Dashboard – SQL Schema & Seed Data Script
-- Compatible with: PostgreSQL 14+, MySQL 8+, SQL Server 2019+, SQLite 3.35+
-- ===========================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- DROP existing tables (safe re-run)
-- ─────────────────────────────────────────────────────────────────────────────
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS loans;
DROP TABLE IF EXISTS customers;

-- ─────────────────────────────────────────────────────────────────────────────
-- TABLE 1: customers  (Dimension)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE customers (
    customer_id          VARCHAR(15)  PRIMARY KEY,
    first_name           VARCHAR(50)  NOT NULL,
    last_name            VARCHAR(50)  NOT NULL,
    age                  SMALLINT     NOT NULL CHECK (age BETWEEN 18 AND 100),
    employment_type      VARCHAR(30)  NOT NULL,
    annual_income        DECIMAL(12,2) NOT NULL CHECK (annual_income >= 0),
    credit_score         SMALLINT     NOT NULL CHECK (credit_score BETWEEN 300 AND 850),
    segment              VARCHAR(30)  NOT NULL,
    city                 VARCHAR(60)  NOT NULL,
    state                VARCHAR(10)  NOT NULL,
    country              VARCHAR(50)  NOT NULL DEFAULT 'USA',
    joined_date          DATE         NOT NULL,
    is_active            CHAR(3)      NOT NULL DEFAULT 'Yes' CHECK (is_active IN ('Yes','No'))
);

-- ─────────────────────────────────────────────────────────────────────────────
-- TABLE 2: loans  (Fact – Loan Accounts)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE loans (
    loan_id                       VARCHAR(15)   PRIMARY KEY,
    customer_id                   VARCHAR(15)   NOT NULL REFERENCES customers(customer_id),
    loan_type                     VARCHAR(30)   NOT NULL,
    loan_purpose                  VARCHAR(60)   NOT NULL,
    principal_amount              DECIMAL(14,2) NOT NULL CHECK (principal_amount > 0),
    outstanding_balance           DECIMAL(14,2) NOT NULL CHECK (outstanding_balance >= 0),
    interest_rate_pct             DECIMAL(5,2)  NOT NULL CHECK (interest_rate_pct > 0),
    term_months                   SMALLINT      NOT NULL CHECK (term_months > 0),
    monthly_payment               DECIMAL(12,2) NOT NULL,
    total_payable                 DECIMAL(14,2) NOT NULL,
    start_date                    DATE          NOT NULL,
    end_date                      DATE          NOT NULL,
    loan_status                   VARCHAR(20)   NOT NULL CHECK (loan_status IN ('Active','Closed','Defaulted','In Arrears')),
    credit_score_at_origination   SMALLINT      NOT NULL,
    origination_state             VARCHAR(10)   NOT NULL
);

-- ─────────────────────────────────────────────────────────────────────────────
-- TABLE 3: transactions  (Fact – Transaction Ledger)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE transactions (
    transaction_id   VARCHAR(15)   PRIMARY KEY,
    loan_id          VARCHAR(15)   NOT NULL REFERENCES loans(loan_id),
    customer_id      VARCHAR(15)   NOT NULL REFERENCES customers(customer_id),
    transaction_date DATE          NOT NULL,
    transaction_type VARCHAR(30)   NOT NULL,
    channel          VARCHAR(30)   NOT NULL,
    amount           DECIMAL(14,2) NOT NULL,
    running_balance  DECIMAL(14,2),
    is_successful    CHAR(3)       NOT NULL DEFAULT 'Yes',
    failure_reason   VARCHAR(60)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- INDEXES for analytical query performance
-- ─────────────────────────────────────────────────────────────────────────────
CREATE INDEX idx_loans_customer     ON loans(customer_id);
CREATE INDEX idx_loans_type         ON loans(loan_type);
CREATE INDEX idx_loans_status       ON loans(loan_status);
CREATE INDEX idx_loans_start_date   ON loans(start_date);
CREATE INDEX idx_tx_loan            ON transactions(loan_id);
CREATE INDEX idx_tx_customer        ON transactions(customer_id);
CREATE INDEX idx_tx_date            ON transactions(transaction_date);
CREATE INDEX idx_tx_type            ON transactions(transaction_type);

-- ─────────────────────────────────────────────────────────────────────────────
-- ANALYTICAL VIEW: Full Loan Performance Mart (optimised for Power BI)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW vw_loan_performance_mart AS
SELECT
    l.loan_id,
    l.loan_type,
    l.loan_purpose,
    l.loan_status,
    l.principal_amount,
    l.outstanding_balance,
    ROUND((l.outstanding_balance / NULLIF(l.principal_amount,0)) * 100, 2)   AS outstanding_pct,
    (l.principal_amount - l.outstanding_balance)                             AS amount_repaid,
    l.interest_rate_pct,
    l.term_months,
    l.monthly_payment,
    l.total_payable,
    ROUND(l.total_payable - l.principal_amount, 2)                           AS total_interest_earned,
    l.start_date,
    l.end_date,
    l.credit_score_at_origination,
    l.origination_state,
    -- Customer attributes
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.age,
    c.employment_type,
    c.annual_income,
    c.credit_score      AS current_credit_score,
    c.segment,
    c.city,
    c.state,
    -- Risk category (derived)
    CASE
        WHEN l.loan_status = 'Defaulted' THEN 'High Risk'
        WHEN l.loan_status = 'In Arrears' THEN 'Medium Risk'
        WHEN c.credit_score < 580 THEN 'Subprime'
        WHEN c.credit_score < 670 THEN 'Near-Prime'
        WHEN c.credit_score < 740 THEN 'Prime'
        ELSE 'Super-Prime'
    END AS risk_category,
    -- LTV proxy for mortgage loans
    CASE WHEN l.loan_type = 'Home Mortgage'
         THEN ROUND((l.outstanding_balance / NULLIF(l.principal_amount,0)) * 100, 2)
         ELSE NULL END AS ltv_ratio_pct
FROM loans l
JOIN customers c ON l.customer_id = c.customer_id;
