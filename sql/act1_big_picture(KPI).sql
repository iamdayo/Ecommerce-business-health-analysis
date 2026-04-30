-- ACT 1: THE BIG PICTURE
-- Revenue totals, order volumes, AOV over time.
-- 2024 vs 2025 monthly comparison.

-- Total revenue
SELECT
    SUM(net_revenue_usd) AS total_revenue
FROM events; -- This business generated ~$31.8M total since opening

-- Total revenue by year
SELECT
    EXTRACT(YEAR FROM event_date) AS years,
    SUM(net_revenue_usd) AS total_revenue
FROM events
GROUP BY years; -- with 2025 being the highest year at ~$17.3M

-- Total revenue by month
SELECT
    EXTRACT(MONTH FROM event_date) AS months,
    SUM(net_revenue_usd) AS total_revenue
FROM events
GROUP BY months
ORDER BY months;

-- Revenue comparison: 2024 vs 2025 by month
SELECT
    EXTRACT(MONTH FROM event_date) AS months,
    SUM(CASE WHEN EXTRACT(YEAR FROM event_date) = 2024 THEN net_revenue_usd END) AS total_revenue_2024,
    SUM(CASE WHEN EXTRACT(YEAR FROM event_date) = 2025 THEN net_revenue_usd END) AS total_revenue_2025
FROM events
GROUP BY months
ORDER BY months; -- Data gaps in Jan-Mar 2024 and Nov-Dec 2025 reflect when the business started recording its data

-- Total orders
SELECT
    COUNT(*) AS total_orders
FROM events; -- ~48,000 orders between early 2024 and late 2025

-- Total orders by year
SELECT
    EXTRACT(YEAR FROM event_date) AS years,
    COUNT(*) AS total_orders
FROM events
GROUP BY years; 

-- Total orders by month
SELECT
    EXTRACT(MONTH FROM event_date) AS months,
    COUNT(*) AS total_orders
FROM events
GROUP BY months
ORDER BY months; -- There have been stable order volumes from April to October across both years


-- Average Order Value (AOV) - overall
SELECT
    SUM(net_revenue_usd) AS total_revenue,
    COUNT(*) AS total_orders,
    ROUND(SUM(net_revenue_usd) / COUNT(*), 2) AS avg_order_value
FROM events; -- Each order brings in an average of $663.17


-- AOV by month
SELECT
    EXTRACT(MONTH FROM event_date) AS months,
    ROUND(SUM(net_revenue_usd) / COUNT(*), 2) AS avg_order_value
FROM events
GROUP BY months
ORDER BY months;
-- The business has a flat trend between $600-$700 per month, this is the stabilisation phase of the business
-- The business is neither growing nor declining