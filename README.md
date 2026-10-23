# 🏦 Banking KPI Dashboard

An end-to-end Finance & Banking Analytics project built using SQL, Microsoft Excel, Power BI, and an Interactive Web Dashboard — analyzing loan portfolios, customer risk, and transaction trends across 2 years of banking data.

---

## 📌 What I Built

This project simulates a real-world banking analytics system. I created 3 datasets from scratch, wrote advanced SQL queries to extract business KPIs, built an interactive 5-page dashboard, and designed a full Power BI data model with DAX measures.

---

## 🗂️ Datasets

### customers.xlsx — 300 rows
Customer profiles with age, income, credit score (300–850), banking segment (Retail / Premium / SME / Private Banking), employment type, and account joining date.

### loans.xlsx — 600 rows
Loan accounts across 6 product types — Personal Loan, Home Mortgage, Auto Loan, Business Loan, Education Loan, Credit Card. Includes principal amount, outstanding balance, interest rate, loan term, and loan status (Active / Closed / Defaulted / In Arrears).

### transactions.xlsx — 3,000 rows
Two years (2023–2024) of banking transactions across 5 channels — Mobile App, Online Banking, ATM, Branch, and Phone. Includes transaction type, amount, success/failure status, and failure reason.

---

## 🛢️ SQL — What I Did

Wrote 10 advanced SQL queries in PostgreSQL using:
- LAG() — Month-over-Month disbursement growth
- DENSE_RANK() — Top customers & state-level ranking
- NTILE(4) — Customer risk segmentation into quartiles
- PERCENT_RANK() — Debt-to-Income affordability index
- CTEs + Window Functions — Running totals, portfolio share %
- CASE bucketing — Interest rate band vs default rate matrix

Also created a full database schema with Primary Keys, Foreign Keys, Indexes, and an Analytical View joining all 3 tables optimized for Power BI.

---

## 📊 Interactive Dashboard


5 Pages | 16 Charts:

Overview — KPI cards, monthly disbursement bar chart (2023 vs 2024), loan type donut, state portfolio bar, loan status pie

Loans — Interest rate by loan type, term distribution histogram, loan summary table

Transactions — Monthly volume line chart, channel breakdown donut, transaction type bar, failure reasons

Risk Analysis — NPL rate by loan type, credit score histogram, rate vs default combo chart, risk band table

Customers — Segment donut, employment bar, income distribution, acquisition trend, top 10 customers table

---

## 🖥️ Power BI

Designed a Star Schema data model connecting all 3 tables. Built 15+ DAX measures including:
- Default Rate %
- NPL Rate %
- Repayment Rate %
- MoM Disbursement Growth %
- Debt-to-Income Ratio
- Total Projected Interest Income

---

##  Tech Stack

SQL (PostgreSQL) — Schema design, 10 analytical KPI queries
Microsoft Excel — Dataset source files with formatting
Power BI Desktop — Star schema, DAX measures, 4-page report
Chart.js — Interactive browser dashboard
HTML / CSS — Dashboard front-end
Node.js — Synthetic dataset generation


## Key Numbers

- 300 Customers
- 600 Loans | ~$124.6M Total Disbursed
- 3,000 Transactions | 96.1% Success Rate
- 9.2% Default Rate
- 694 Avg Credit Score
- ~$29.1M Projected Interest Income

---

