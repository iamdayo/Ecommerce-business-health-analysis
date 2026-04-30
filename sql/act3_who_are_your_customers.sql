-- ACT 3: WHO ARE THE CUSTOMERS?
-- Revenue by segment, age band, acquisition channel.
-- Billing cycle preference per segment.
-- New vs repeat customer analysis.


-- Revenue by customer segment
SELECT
    c.segment,
    COUNT(*) AS total_orders,
    SUM(e.net_revenue_usd) AS total_revenue,
    ROUND(SUM(e.net_revenue_usd) / COUNT(*), 2) AS avg_order_value
FROM events e
JOIN customers c ON e.customer_id = c.customer_id
GROUP BY segment
ORDER BY total_revenue DESC; -- Individual consumers drive the most orders and revenue


-- Billing cycle preference by segment
SELECT
    c.segment,
    COUNT(*) AS total_orders,
    SUM(e.net_revenue_usd) AS total_revenue,
    SUM(CASE WHEN p.billing_cycle = 'Annual'   THEN 1 END) AS annual_count,
    SUM(CASE WHEN p.billing_cycle = 'Monthly'  THEN 1 END) AS monthly_count,
    SUM(CASE WHEN p.billing_cycle = 'One-time' THEN 1 END) AS one_time_count
FROM events e
JOIN customers c ON e.customer_id = c.customer_id
JOIN products  p ON e.product_id  = p.product_id
GROUP BY segment
ORDER BY total_revenue DESC;
-- Annual and monthly billing cycle order counts are nearly equal across all
-- segments, but annual billing cycle renews once per year vs monthly cycle which is every
-- month, meaning customers are actively choosing annual billing cycles


-- Revenue by acquisition channel
SELECT
    c.acquisition_channel,
    COUNT(*) AS total_orders,
    SUM(e.net_revenue_usd) AS total_revenue,
    ROUND(SUM(e.net_revenue_usd) / COUNT(*), 2) AS avg_order_value
FROM events e
JOIN customers c ON e.customer_id = c.customer_id
GROUP BY acquisition_channel
ORDER BY total_revenue DESC;
-- Organic is the top customer acquisition channel which the business earns its traffic
-- Paid Search follows after, which is worth monitoring for ROI


-- Revenue by age band
SELECT
    c.age_band,
    COUNT(*) AS total_orders,
    SUM(e.net_revenue_usd) AS total_revenue
FROM events e
JOIN customers c ON e.customer_id = c.customer_id
GROUP BY age_band
ORDER BY age_band;
-- 25-34 is the highest value age group, this is mostly due to early career
-- professionals and new business owners starting out
-- 18-24 is low, but it has good opportunity for targeted student discounts


-- New vs repeat customers
WITH total_order AS (
    SELECT
        customer_id,
        COUNT(*) AS total_orders
    FROM events
    WHERE is_refunded = FALSE
    GROUP BY customer_id
)
SELECT
    SUM(CASE WHEN total_orders = 1 THEN 1 END) AS new_customers,
    SUM(CASE WHEN total_orders > 1 THEN 1 END) AS repeat_customers
FROM total_order;
-- Every customer has purchased more than once, so there are no true one-time customers.
--  This is confirmed by minimum order count check below

-- Confirm minimum order count per customer
SELECT
    customer_id,
    COUNT(*) AS total_orders,
    SUM(net_revenue_usd) AS total_revenue
FROM events
GROUP BY customer_id
ORDER BY total_orders ASC;
-- The Result: lowest order count is 2, which shows there are no true one-time customers