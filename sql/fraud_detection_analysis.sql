-- ================================================
-- FRAUD DETECTION ANALYTICS — SQL ANALYSIS
-- Author: Nikhil Krishna Kurella
-- Dataset: Fraud Detection Dataset (50 transactions,
--          15 customers, 10 merchants)
-- Tools: MySQL
-- ================================================

-- Q1: Fraud transactions at blacklisted merchants
-- Business purpose: Identify high-risk merchant exposure

SELECT 
    t.transaction_id,
    t.transaction_amount,
    c.customer_name,
    m.merchant_name,
    m.is_blacklisted
FROM transactions t
JOIN customers c ON c.customer_id = t.customer_id
JOIN merchants m ON m.merchant_id = t.merchant_id
WHERE m.is_blacklisted = 1;

-- Q2: Customers with highest fraud exposure
-- Business purpose: Risk tier customer portfolio

SELECT 
    c.customer_name,
    c.risk_category,
    COUNT(t.transaction_id) AS fraud_count,
    SUM(t.transaction_amount) AS total_fraud_amount
FROM customers c
JOIN transactions t ON c.customer_id = t.customer_id
WHERE t.is_fraud = 1
GROUP BY c.customer_id, c.customer_name, c.risk_category
ORDER BY total_fraud_amount DESC;

-- Q3: Fraud rate by country
-- Business purpose: Identify high-risk geographies

SELECT 
    c.country,
    COUNT(t.transaction_id) AS total_transactions,
    SUM(CASE WHEN t.is_fraud = 1 THEN 1 ELSE 0 END) AS fraud_transactions,
    ROUND(SUM(CASE WHEN t.is_fraud = 1 THEN 1 ELSE 0 END) * 100.0 / 
        COUNT(t.transaction_id), 2) AS fraud_rate_pct
FROM customers c
JOIN transactions t ON c.customer_id = t.customer_id
GROUP BY c.country
ORDER BY fraud_rate_pct DESC;

-- Q4: Structuring pattern detection
-- Business purpose: Identify potential BSA violations

SELECT 
    c.customer_name,
    COUNT(t.transaction_id) AS transfer_count,
    SUM(t.transaction_amount) AS total_amount,
    MAX(t.transaction_amount) AS max_single_transfer
FROM customers c
JOIN transactions t ON c.customer_id = t.customer_id
WHERE t.transaction_type = 'transfer'
AND t.transaction_amount < 50000
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(t.transaction_id) >= 3
ORDER BY total_amount DESC;

-- Q5: PEP customers with high value transactions
-- Business purpose: EDD trigger identification

SELECT 
    c.customer_name,
    c.is_pep,
    SUM(t.transaction_amount) AS total_amount,
    COUNT(t.transaction_id) AS transaction_count
FROM customers c
JOIN transactions t ON c.customer_id = t.customer_id
WHERE c.is_pep = 1
GROUP BY c.customer_id, c.customer_name, c.is_pep
ORDER BY total_amount DESC;

-- Q6: Analyst performance dashboard
-- Business purpose: SLA and productivity tracking

SELECT 
    f.assigned_to,
    COUNT(f.alert_id) AS alerts_handled,
    SUM(CASE WHEN f.status = 'closed_fraud' THEN 1 ELSE 0 END) AS confirmed_fraud,
    SUM(CASE WHEN f.status = 'closed_legitimate' THEN 1 ELSE 0 END) AS false_positives,
    SUM(t.transaction_amount) AS total_amount_investigated
FROM fraud_alerts f
JOIN transactions t ON t.transaction_id = f.transaction_id
GROUP BY f.assigned_to
ORDER BY alerts_handled DESC;

-- Q7: Potential mule accounts
-- Business purpose: Low risk customers at blacklisted merchants

SELECT 
    c.customer_name,
    c.risk_category,
    m.merchant_name,
    m.is_blacklisted,
    t.transaction_amount,
    r.risk_score
FROM customers c
JOIN transactions t ON c.customer_id = t.customer_id
JOIN merchants m ON m.merchant_id = t.merchant_id
JOIN risk_scores r ON r.customer_id = c.customer_id
WHERE c.risk_category = 'low'
AND m.is_blacklisted = 1;

-- Q8: Late night high value transactions
-- Business purpose: Time-based fraud pattern detection

SELECT 
    t.transaction_id,
    c.customer_name,
    t.transaction_amount,
    t.transaction_time,
    HOUR(t.transaction_time) AS transaction_hour
FROM transactions t
JOIN customers c ON c.customer_id = t.customer_id
WHERE HOUR(t.transaction_time) BETWEEN 0 AND 4
AND t.transaction_amount > 10000
ORDER BY t.transaction_amount DESC;
