-- ===========================================================================
-- Banking KPI Dashboard – 10 Analytical SQL Queries
-- Skills: CTEs, Window Functions (LAG, DENSE_RANK, NTILE, PERCENT_RANK),
--         Cohorts, Running Totals, Risk Segmentation
-- ===========================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 1 ▸ Executive KPI Scorecard
-- One-row summary of the entire loan portfolio's health
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    COUNT(DISTINCT l.customer_id)                          AS total_customers,
    COUNT(l.loan_id)                                       AS total_loans,
    ROUND(SUM(l.principal_amount), 2)                      AS total_disbursed,
    ROUND(SUM(l.outstanding_balance), 2)                   AS total_outstanding,
    ROUND(SUM(l.total_payable - l.principal_amount), 2)    AS projected_interest_income,
    COUNT(CASE WHEN l.loan_status = 'Defaulted' THEN 1 END) AS defaulted_loans,
    ROUND(COUNT(CASE WHEN l.loan_status = 'Defaulted' THEN 1 END) * 100.0
          / COUNT(l.loan_id), 2)                           AS default_rate_pct,
    COUNT(CASE WHEN l.loan_status = 'In Arrears' THEN 1 END) AS in_arrears_loans,
    ROUND(AVG(l.interest_rate_pct), 2)                     AS avg_interest_rate,
    ROUND(AVG(c.credit_score), 0)                          AS avg_customer_credit_score
FROM loans l
JOIN customers c ON l.customer_id = c.customer_id;


-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 2 ▸ Monthly Disbursement Trend + MoM Growth (LAG window function)
-- ─────────────────────────────────────────────────────────────────────────────
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', start_date)        AS loan_month,
        TO_CHAR(start_date, 'YYYY-MM')         AS year_month,
        COUNT(loan_id)                         AS loans_issued,
        ROUND(SUM(principal_amount), 2)        AS disbursed_amount
    FROM loans
    GROUP BY DATE_TRUNC('month', start_date), TO_CHAR(start_date, 'YYYY-MM')
)
SELECT
    year_month,
    loans_issued,
    disbursed_amount,
    LAG(disbursed_amount) OVER (ORDER BY loan_month)       AS prev_month_disbursed,
    ROUND(
        (disbursed_amount - LAG(disbursed_amount) OVER (ORDER BY loan_month))
        / NULLIF(LAG(disbursed_amount) OVER (ORDER BY loan_month), 0) * 100, 2
    )                                                       AS mom_growth_pct,
    ROUND(SUM(disbursed_amount) OVER (ORDER BY loan_month), 2) AS running_total_disbursed
FROM monthly
ORDER BY loan_month;


-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 3 ▸ Loan Portfolio Breakdown by Type & Status
-- Revenue exposure and risk distribution across product lines
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    loan_type,
    loan_status,
    COUNT(loan_id)                                        AS loan_count,
    ROUND(SUM(principal_amount), 2)                       AS total_principal,
    ROUND(SUM(outstanding_balance), 2)                    AS total_outstanding,
    ROUND(AVG(interest_rate_pct), 2)                      AS avg_rate,
    ROUND(AVG(credit_score_at_origination), 0)            AS avg_credit_score,
    ROUND(SUM(principal_amount) * 100.0
          / SUM(SUM(principal_amount)) OVER (), 2)        AS pct_of_portfolio
FROM loans
GROUP BY loan_type, loan_status
ORDER BY loan_type, total_principal DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 4 ▸ Customer Risk Segmentation using NTILE Credit Score Quartiles
-- Identifies high-risk client cohorts for collections & risk management
-- ─────────────────────────────────────────────────────────────────────────────
WITH scored AS (
    SELECT
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        c.segment,
        c.credit_score,
        NTILE(4) OVER (ORDER BY c.credit_score DESC) AS credit_quartile,
        COUNT(l.loan_id)                             AS active_loans,
        ROUND(SUM(l.outstanding_balance), 2)         AS total_outstanding,
        COUNT(CASE WHEN l.loan_status IN ('Defaulted','In Arrears') THEN 1 END) AS at_risk_loans
    FROM customers c
    LEFT JOIN loans l ON c.customer_id = l.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.segment, c.credit_score
)
SELECT
    *,
    CASE credit_quartile
        WHEN 1 THEN 'Super-Prime (Top 25%)'
        WHEN 2 THEN 'Prime (50–75%)'
        WHEN 3 THEN 'Near-Prime (25–50%)'
        WHEN 4 THEN 'Subprime (Bottom 25%)'
    END AS risk_band
FROM scored
ORDER BY total_outstanding DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 5 ▸ State-Level Geographic Portfolio Heat Map
-- Supports regional risk management and branch expansion planning
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    c.state,
    COUNT(DISTINCT c.customer_id)                         AS total_customers,
    COUNT(l.loan_id)                                      AS total_loans,
    ROUND(SUM(l.principal_amount), 2)                     AS total_disbursed,
    ROUND(SUM(l.outstanding_balance), 2)                  AS total_outstanding,
    ROUND(AVG(c.credit_score), 0)                         AS avg_credit_score,
    COUNT(CASE WHEN l.loan_status = 'Defaulted' THEN 1 END) AS defaults,
    ROUND(COUNT(CASE WHEN l.loan_status = 'Defaulted' THEN 1 END) * 100.0
          / NULLIF(COUNT(l.loan_id), 0), 2)               AS default_rate_pct,
    DENSE_RANK() OVER (ORDER BY SUM(l.principal_amount) DESC) AS portfolio_rank
FROM customers c
LEFT JOIN loans l ON c.customer_id = l.customer_id
GROUP BY c.state
ORDER BY total_disbursed DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 6 ▸ Monthly Transaction Volume + Running Total
-- Cash flow analysis across all banking channels
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    TO_CHAR(transaction_date, 'YYYY-MM')                           AS year_month,
    transaction_type,
    channel,
    COUNT(transaction_id)                                          AS tx_count,
    ROUND(SUM(CASE WHEN is_successful='Yes' THEN amount ELSE 0 END), 2) AS successful_volume,
    COUNT(CASE WHEN is_successful='No' THEN 1 END)                 AS failed_transactions,
    ROUND(
        COUNT(CASE WHEN is_successful='No' THEN 1 END) * 100.0
        / NULLIF(COUNT(transaction_id), 0), 2
    )                                                              AS failure_rate_pct
FROM transactions
GROUP BY TO_CHAR(transaction_date, 'YYYY-MM'), transaction_type, channel
ORDER BY year_month, transaction_type;


-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 7 ▸ Top 10 Highest Value Customers (Loan Exposure Ranking)
-- Identifies VIP / most profitable clients
-- ─────────────────────────────────────────────────────────────────────────────
WITH cust_summary AS (
    SELECT
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        c.segment,
        c.state,
        c.credit_score,
        c.annual_income,
        COUNT(l.loan_id)                               AS total_loans,
        ROUND(SUM(l.principal_amount), 2)              AS total_borrowed,
        ROUND(SUM(l.outstanding_balance), 2)           AS total_outstanding,
        ROUND(SUM(l.total_payable - l.principal_amount), 2) AS total_interest_payable
    FROM customers c
    JOIN loans l ON c.customer_id = l.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.segment, c.state,
             c.credit_score, c.annual_income
)
SELECT
    DENSE_RANK() OVER (ORDER BY total_borrowed DESC) AS rank,
    *
FROM cust_summary
ORDER BY total_borrowed DESC
LIMIT 10;


-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 8 ▸ Non-Performing Loan (NPL) Deep-Dive
-- Full profile of all defaulted & in-arrears accounts for recovery teams
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    l.loan_id,
    l.loan_type,
    l.loan_purpose,
    l.loan_status,
    l.principal_amount,
    l.outstanding_balance,
    ROUND((l.outstanding_balance / NULLIF(l.principal_amount,0)) * 100, 2) AS recovery_exposure_pct,
    l.interest_rate_pct,
    l.start_date,
    l.end_date,
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.credit_score,
    c.annual_income,
    c.segment,
    c.state,
    -- Days past original end date (overdue indicator)
    GREATEST(0, CURRENT_DATE - l.end_date) AS days_overdue
FROM loans l
JOIN customers c ON l.customer_id = c.customer_id
WHERE l.loan_status IN ('Defaulted','In Arrears')
ORDER BY l.outstanding_balance DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 9 ▸ Interest Rate Band vs Default Rate Matrix
-- Answers: Do higher-rate products carry higher default risk?
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    CASE
        WHEN interest_rate_pct < 6   THEN 'A: Below 6%'
        WHEN interest_rate_pct < 10  THEN 'B: 6% – 10%'
        WHEN interest_rate_pct < 14  THEN 'C: 10% – 14%'
        WHEN interest_rate_pct < 18  THEN 'D: 14% – 18%'
        ELSE                              'E: 18%+'
    END                                                   AS rate_band,
    COUNT(loan_id)                                        AS loan_count,
    ROUND(AVG(credit_score_at_origination), 0)            AS avg_credit_score,
    ROUND(AVG(principal_amount), 2)                       AS avg_loan_size,
    COUNT(CASE WHEN loan_status = 'Active'    THEN 1 END) AS active,
    COUNT(CASE WHEN loan_status = 'Defaulted' THEN 1 END) AS defaulted,
    COUNT(CASE WHEN loan_status = 'In Arrears' THEN 1 END) AS in_arrears,
    ROUND(COUNT(CASE WHEN loan_status IN ('Defaulted','In Arrears') THEN 1 END)
          * 100.0 / COUNT(loan_id), 2)                   AS npl_rate_pct
FROM loans
GROUP BY rate_band
ORDER BY rate_band;


-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 10 ▸ Customer Income-to-Debt Ratio (Affordability Index)
-- Critical for responsible lending policy and stress testing
-- ─────────────────────────────────────────────────────────────────────────────
WITH customer_debt AS (
    SELECT
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        c.segment,
        c.annual_income,
        c.credit_score,
        SUM(l.monthly_payment) * 12                            AS annual_debt_obligation,
        ROUND(SUM(l.monthly_payment) * 12
              / NULLIF(c.annual_income, 0) * 100, 2)           AS debt_to_income_ratio_pct,
        PERCENT_RANK() OVER (
            ORDER BY SUM(l.monthly_payment) * 12
                     / NULLIF(c.annual_income, 0)
        )                                                       AS dti_percentile
    FROM customers c
    JOIN loans l ON c.customer_id = l.customer_id
    WHERE l.loan_status = 'Active'
    GROUP BY c.customer_id, c.first_name, c.last_name, c.segment,
             c.annual_income, c.credit_score
)
SELECT
    *,
    CASE
        WHEN debt_to_income_ratio_pct < 20 THEN 'Healthy (< 20%)'
        WHEN debt_to_income_ratio_pct < 36 THEN 'Moderate (20–36%)'
        WHEN debt_to_income_ratio_pct < 50 THEN 'Stressed (36–50%)'
        ELSE                                    'Overleveraged (> 50%)'
    END AS affordability_category
FROM customer_debt
ORDER BY debt_to_income_ratio_pct DESC;
