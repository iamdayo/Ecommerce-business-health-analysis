-- ACT 5: WHO ARE OUR BEST CUSTOMERS?
-- RFM (Recency, Frequency, Monetary) scoring and segmentation
-- Each customer is scored 1-5 on three dimensions using  NTILE(5), then assigned to a behavioural segment


-- How NTILE(5) works here:
--
-- NTILE(5) splits all customers into 5 equal buckets (1-5)
-- The ORDER BY direction determines who gets the highest score:
--
-- Recency  -> ORDER BY days_since_last_purchase DESC
--             More days = worse, so DESC puts the more(worst) days first
--             and they receive bucket 1, 
--             while fewer days (more recent) end up last and receive bucket 5
--
-- Frequency -> ORDER BY frequency ASC
--             Fewest orders are first on the list and get a bucket 1,
--             most orders are last on the list and get a bucket 5
--
-- Monetary  -> ORDER BY monetary ASC
--             Lowest spenders are first on the list and receive bucket 1, 
--             highest spenders are last on the list and get a bucket 5


CREATE VIEW customer_rfm AS

WITH rfm_base AS (
    SELECT
        customer_id,
        MAX(event_date)                    AS last_transaction,
        CURRENT_DATE - MAX(event_date)     AS days_since_last_purchase,
        COUNT(*)                           AS frequency,
        SUM(net_revenue_usd)               AS monetary
    FROM events
    WHERE is_refunded = false
    GROUP BY customer_id
),

rfm_scores AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY days_since_last_purchase DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)                 AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)                  AS m_score
    FROM rfm_base
)

SELECT
    customer_id,
    last_transaction,
    days_since_last_purchase,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    r_score + f_score + m_score AS rfm_total,

    CASE
        WHEN r_score >= 4 AND f_score >= 4 THEN 'Champion'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customer'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
        ELSE 'Potential'
    END AS rfm_segment -- Segment logic uses individual score combinations
                       -- to catch behavioural patterns that a summed score, would average out and misclassify
FROM rfm_scores;


-- Full customer RFM view
SELECT
    customer_id,
    last_transaction,
    days_since_last_purchase,
    frequency   AS total_orders,
    monetary    AS total_revenue,
    r_score,
    f_score,
    m_score,
    rfm_total,
    rfm_segment AS customer_class
FROM customer_rfm
ORDER BY days_since_last_purchase DESC;


-- RFM segment summary
SELECT
    rfm_segment AS customer_class,
    COUNT(*) AS total_customers
FROM customer_rfm
GROUP BY customer_class
ORDER BY total_customers DESC;
-- 779 customers are classified as Champions
-- 788 customers are classified as Lost
-- 812 customers are classified as At Risk
-- These are warm customers who went quiet, and are more likely to respond to re-engagement campaigns than new customer acquisition efforts