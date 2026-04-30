-- ACT 2: WHERE IS THE MONEY COMING FROM?
-- Revenue by country, region, channel, category,
-- product, vendor, billing cycle, and subscription type.


-- Revenue by country
SELECT
    country,
    SUM(net_revenue_usd) AS total_revenue
FROM events
GROUP BY country
ORDER BY total_revenue DESC;
-- US brings in the most (~$8.6M, ~27% of total revenue)
-- Brazil accounts for the least (~$1.5M, ~4.7%)


-- Revenue share percentage by country
WITH country_rev AS (
    SELECT
        country,
        SUM(net_revenue_usd) AS total_country_rev
    FROM events
    GROUP BY country
),
total_rev AS (
    SELECT
        *,
        SUM(total_country_rev) OVER() AS total_revenue
    FROM country_rev
)
SELECT
    country,
    total_country_rev AS total_revenue,
    ROUND(total_country_rev * 100.0 / total_revenue, 2) AS prcnt_rev
FROM total_rev
ORDER BY prcnt_rev DESC;


-- Revenue by region
SELECT
    region,
    SUM(net_revenue_usd) AS total_revenue
FROM events
GROUP BY region
ORDER BY total_revenue DESC;


-- Revenue share percentage by region
WITH region_rev AS (
    SELECT
        region,
        SUM(net_revenue_usd) AS total_region_rev
    FROM events
    GROUP BY region
),
total_rev AS (
    SELECT
        *,
        SUM(total_region_rev) OVER() AS total_revenue
    FROM region_rev
)
SELECT
    region,
    total_region_rev AS total_revenue,
    ROUND(total_region_rev * 100.0 / total_revenue, 2) AS prcnt_rev
FROM total_rev
ORDER BY prcnt_rev DESC; -- Europe leads at ~43% despite fewer orders than North America
-- This raises the question of 'which region has the higher AOV?'


-- Orders by region (this is used to compare against revenue share)
SELECT
    region,
    COUNT(*) AS total_orders
FROM events
GROUP BY region
ORDER BY total_orders DESC;


-- AOV by region
SELECT
    region,
    SUM(net_revenue_usd) AS total_revenue,
    COUNT(*) AS total_orders,
    ROUND(SUM(net_revenue_usd) / COUNT(*), 2) AS avg_order_value
FROM events
GROUP BY region
ORDER BY total_orders DESC;
-- NA has more orders across all regions, but EU has significantly higher AOV
-- EU wins on value, NA wins on volume


-- Revenue by channel
SELECT
    channel,
    SUM(net_revenue_usd) AS total_revenue,
    COUNT(*) AS total_orders,
    ROUND(SUM(net_revenue_usd) / COUNT(*), 2) AS avg_order_value
FROM events
GROUP BY channel; -- Website generates ~$14M and no other channel comes close


-- Revenue share percentage by channel
WITH channel_rev AS (
    SELECT
        channel,
        SUM(net_revenue_usd) AS total_revenue,
        COUNT(*) AS total_orders,
        ROUND(SUM(net_revenue_usd) / COUNT(*), 2) AS avg_order_value
    FROM events
    GROUP BY channel
),
total_rev AS (
    SELECT
        channel,
        total_orders,
        total_revenue AS revenue,
        SUM(total_revenue) OVER() AS total_revenue
    FROM channel_rev
)
SELECT
    channel,
    revenue,
    ROUND(revenue * 100.00 / total_revenue, 2) AS prcnt_of_revenue
FROM total_rev
ORDER BY prcnt_of_revenue DESC;
-- 45% of all revenue comes from the Website channel


-- Revenue by product category
SELECT
    p.category AS product_category,
    COUNT(*) AS total_orders,
    SUM(e.net_revenue_usd) AS total_revenue,
    ROUND(SUM(e.net_revenue_usd) / COUNT(*), 2) AS avg_order_value
FROM events e
JOIN products p ON e.product_id = p.product_id
GROUP BY product_category
ORDER BY total_revenue DESC;
-- Developer Tools has the most revenue
-- Productivity Suite has the highest AOV
-- Design has most orders but if also has low AOV, this was flagged for investigation


-- Revenue by product, ranked by AOV
SELECT
    p.product_name,
    p.category,
    COUNT(*) AS total_orders,
    SUM(e.net_revenue_usd) AS total_revenue,
    ROUND(SUM(e.net_revenue_usd) / COUNT(*), 2) AS avg_order_value
FROM events e
JOIN products p ON e.product_id = p.product_id
GROUP BY product_name, category
ORDER BY avg_order_value DESC
LIMIT 10;
-- The top 10 products by average order value are all annual billing
-- Microsoft 365 Business Standard Annual leads significantly compared to other products

-- Revenue by product, ranked by total orders
SELECT
    p.product_name,
    p.category,
    COUNT(*) AS total_orders,
    SUM(e.net_revenue_usd) AS total_revenue,
    ROUND(SUM(e.net_revenue_usd) / COUNT(*), 2) AS avg_order_value
FROM events e
JOIN products p ON e.product_id = p.product_id
GROUP BY product_name, category
ORDER BY total_orders DESC;


-- Subscription vs non-subscription
SELECT
    CASE
        WHEN p.is_subscription = TRUE THEN 'Subscription'
        ELSE 'Non-Subscription'
    END AS subscription_type,
    COUNT(*) AS total_orders,
    SUM(e.net_revenue_usd) AS total_revenue
FROM events e
JOIN products p ON e.product_id = p.product_id
GROUP BY subscription_type; -- ~98% of orders are subscription-based


-- How many products are subscription vs non-subscription?
SELECT
    CASE
        WHEN is_subscription = TRUE THEN 'Subscription'
        ELSE 'Non-Subscription'
    END AS subscription_type,
    COUNT(*) AS number_of_products
FROM products
GROUP BY subscription_type; --99 out of 101 products are subscription based products


-- Revenue by billing cycle
SELECT
    p.billing_cycle,
    COUNT(*) AS total_orders,
    SUM(e.net_revenue_usd) AS total_revenue,
    ROUND(SUM(e.net_revenue_usd) / COUNT(*), 2) AS avg_order_value
FROM events e
JOIN products p ON e.product_id = p.product_id
GROUP BY billing_cycle
ORDER BY avg_order_value DESC;
-- Annual billing cycle brings in the highest revenue and AOV
-- Annual orders are nearly equal to monthly by count, since annual renews once per year vs monthly every month,
-- this means customers are actively choosing to commit annually



-- Revenue by vendor
SELECT
    p.vendor,
    COUNT(*) AS total_orders,
    SUM(e.net_revenue_usd) AS total_revenue,
    ROUND(SUM(e.net_revenue_usd) / COUNT(*), 2) AS avg_order_value
FROM events e
JOIN products p ON e.product_id = p.product_id
GROUP BY vendor
ORDER BY total_revenue DESC;
-- Microsoft leads; AI Tools is second this is driven by AI demand
-- This raises the question: which AI products specifically?

-- Revenue breakdown within AI Tools vendor
SELECT
    p.product_name,
    COUNT(*) AS total_orders,
    SUM(e.net_revenue_usd) AS total_revenue,
    ROUND(SUM(e.net_revenue_usd) / COUNT(*), 2) AS avg_order_value
FROM events e
JOIN products p ON e.product_id = p.product_id
WHERE vendor = 'AI Tools'
GROUP BY product_name
ORDER BY total_revenue DESC;
-- ChatGPT leads; the business should consider adding Claude, Grok, Gemini, and Deepseek to get the growing AI demand
