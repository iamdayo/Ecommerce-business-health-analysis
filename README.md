# Are We a Healthy Business Right Now?
## Global Software Reseller - Sales Analytics (SQL Project)
**Tool:** PostgreSQL | **By:** Temidayo Olubayo

The business is generating revenue, orders are coming in, and the product catalogue is growing. But generating revenue and building a healthy business are not the same thing.

This analysis examines $31.8M+ in transactions across 20+ countries to answer one question with data:

> **Are we a healthy business right now?**

## Table of Contents

1. [Business Context](#business-context)
2. [Dataset Overview](#dataset-overview)
3. [Data Preparation](#data-preparation)
4. [Analysis Structure](#analysis-structure)
5. [Key Findings](#key-findings)
6. [Business Health Summary](#business-health-summary)
7. [Recommendations](#recommendations)
8. [Limitations](#limitations)
9. [Tools Used](#tools-used)

## Business Context

A software reseller operates in a uniquely competitive space. Unlike a product business, margins are thin and the ability to grow depends heavily on the right products, the right customers, and the right channels - not just raw volume.

The business sells a mix of subscription and one-time software products across multiple countries and channels. At first glance, the numbers look stable. But stability can mean two very different things: a healthy business holding its ground, or a stagnating one that hasn't noticed the cracks yet.

This analysis moves beyond totals and asks where the revenue actually comes from, how clean that revenue is, and whether the customers generating it are the kind worth keeping.


## Dataset Overview

The analysis draws from three tables representing the full commercial picture of the business.

### Events Table
Transaction-level data - one row per order. Includes product, channel, country, payment method, revenue in local currency and USD, discount applied, and refund status.

### Products Table
The full product catalogue. Includes category, vendor, billing cycle (monthly, annual, one-time), subscription flag, and base pricing.

### Customers Table
Customer profiles linked to each transaction. Includes segment (Consumer, SMB, Enterprise), age band, acquisition channel, region, and signup date.

These three tables were joined throughout the analysis to answer questions that no single table could answer alone - for example, which age group prefers annual billing, or which acquisition channel produces the most refunds.

## Data Preparation

Both raw and clean versions of all three tables were maintained. Raw tables were ingested with every column as `TEXT` to avoid type-related import failures, then cast to correct types in a separate staging step.

Key preparation steps included:

- **Type casting**: Dates, numerics, booleans, and timestamps were cast explicitly using `NULLIF()` to handle empty strings cleanly without errors
- **Date simplification**: `event_date` was converted from `TIMESTAMP` to `DATE` - time-of-day carries no analytical value here
- **Region gaps**: Rows from the United States and Canada were missing region labels. These were filled as `'NA'` using an `UPDATE` statement
- **Discount code nulls**: The value `'N/A'` appeared in the discount code column instead of a true null. These were converted to `NULL` to allow proper filtering and aggregation
- **Duplicate check**: No duplicate `event_id` values were found
- **Column removal**: Latitude, longitude, and product version columns were dropped - not relevant to this analysis

All raw tables were preserved. No transformations were applied to the source data directly.

## Analysis Structure

The analysis was built across five layers, each answering a progressively deeper question about the business.

### Act 1 - The Big Picture
Revenue totals, order volumes, and Average Order Value (AOV) across time. Monthly and yearly breakdowns. A side-by-side 2024 vs 2025 monthly comparison to understand directional trends.

```sql
SELECT
    EXTRACT(MONTH FROM event_date) AS months,
    SUM(CASE WHEN EXTRACT(YEAR FROM event_date) = 2024 THEN net_revenue_usd END) AS revenue_2024,
    SUM(CASE WHEN EXTRACT(YEAR FROM event_date) = 2025 THEN net_revenue_usd END) AS revenue_2025
FROM events
GROUP BY months
ORDER BY months;
```

### Act 2 - Where Is the Money Coming From?
Revenue broken down by country, region, channel, product category, vendor, and billing cycle. Identifies which markets, products, and channels are actually driving performance - and which ones only appear to be.

```sql
SELECT
    region,
    SUM(net_revenue_usd)                      AS total_revenue,
    COUNT(*)                                   AS total_orders,
    ROUND(SUM(net_revenue_usd) / COUNT(*), 2) AS avg_order_value
FROM events
GROUP BY region
ORDER BY total_orders DESC;
```

### Act 3 - Who Are the Customers?
Revenue and orders by customer segment, age band, and acquisition channel. Includes a billing cycle breakdown per segment to understand what different customer types are actually choosing to buy.

```sql
SELECT
    c.segment,
    COUNT(*)                                                   AS total_orders,
    SUM(CASE WHEN p.billing_cycle = 'Annual'   THEN 1 END)    AS annual_count,
    SUM(CASE WHEN p.billing_cycle = 'Monthly'  THEN 1 END)    AS monthly_count,
    SUM(CASE WHEN p.billing_cycle = 'One-time' THEN 1 END)    AS one_time_count
FROM events e
JOIN customers c ON e.customer_id = c.customer_id
JOIN products  p ON e.product_id  = p.product_id
GROUP BY c.segment
ORDER BY total_orders DESC;
```

### Act 4 - How Healthy Is That Revenue?
Refund rate analysis - overall, by category, by country, and by channel. Refund reason breakdown. Discount code analysis covering cost, usage frequency, and revenue generated per code. Gross vs net revenue comparison.

```sql
SELECT
    country,
    COUNT(*)                                                                 AS total_orders,
    SUM(CASE WHEN is_refunded = TRUE THEN 1 ELSE 0 END)                     AS total_refunds,
    ROUND(SUM(CASE WHEN is_refunded = TRUE THEN 1 ELSE 0 END) * 100.0
          / COUNT(*), 2)                                                     AS refund_rate_pct
FROM events
GROUP BY country
ORDER BY refund_rate_pct DESC;
```

### Act 5 - Who Are Our Best Customers?
RFM (Recency, Frequency, Monetary) scoring to segment every customer by behaviour. Customers are scored 1–5 on each dimension using `NTILE(5)` and assigned to one of five tiers: Champion, Loyal, Potential, At Risk, or Lost.

```sql
WITH rfm_base AS (
    SELECT
        customer_id,
        MAX(event_date)                  AS last_transaction,
        CURRENT_DATE - MAX(event_date)   AS days_since_last_purchase,
        COUNT(*)                         AS frequency,
        SUM(net_revenue_usd)             AS monetary
    FROM events
    WHERE is_refunded = false
    GROUP BY customer_id
)
SELECT
    *,
    NTILE(5) OVER (ORDER BY days_since_last_purchase DESC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency ASC)                 AS f_score,
    NTILE(5) OVER (ORDER BY monetary ASC)                  AS m_score
FROM rfm_base;
```

Full query set available in the `/sql` folder, organized by analysis stage.

## Key Findings

### 1. The business is stable - but not growing

The business has generated **~$31.8M in total revenue** across approximately 48,000 orders since opening, with 2025 being the highest revenue year at ~$17.3M. Monthly AOV sits consistently between $600–$700 with minimal variance.

The business is not declining, but it is not visibly accelerating either. Stabilization at this stage is a signal worth paying attention to.

**AOV per Month:**

<img width="807" height="474" alt="image" src="https://github.com/user-attachments/assets/e4b673c1-be79-454c-b3e2-86258d72924f" />

### 2. Revenue is geographically concentrated - and the pattern is not what it looks like

The United States is the single largest country by revenue at approximately $8.6M (~27% of total). 

**Revenue Per Country:**

<img width="752" height="452" alt="image" src="https://github.com/user-attachments/assets/619c91b1-b78c-47d0-9e9e-b073257057b4" />

<br>

But at the regional level, **Europe generates ~43% of total revenue** despite having fewer total orders than North America.

**Revenue Contribution Per Region:**

<img width="751" height="452" alt="image" src="https://github.com/user-attachments/assets/4e6697ab-11d0-4936-972e-6f86d432973e" />

<br>

Europe's Average Order Value is substantially higher than North America's - meaning NA is winning on volume, but EU is winning on value. These are two meaningfully different customer bases and likely require different strategies.

**AOV Per Region:**

<img width="752" height="451" alt="image" src="https://github.com/user-attachments/assets/8b477453-a785-4ec3-8100-aa5f1f171bc9" />

<br>

### 3. The Website is the engine - and also the biggest concentration risk

**45% of all revenue flows through the Website channel.** No other channel comes close. The website also generates the most revenue from discounted orders at ~$4.7M - significantly ahead of every other channel - meaning it is not just the volume leader, it is also where discount strategy has the most commercial impact.

**Revenue Contribution by Channel:**

<img width="752" height="452" alt="image" src="https://github.com/user-attachments/assets/6355601b-e654-42bb-9d64-689a65c0ace9" />

<br>

That concentration is a strength while the channel is performing. It becomes a vulnerability if anything disrupts it.

### 4. Customers are choosing annual - and that is meaningful

Annual billing products dominate the top 10 by revenue. When broken down by segment, annual order counts are nearly equal to monthly order counts across all customer types - despite annual subscriptions renewing once every 12 months versus monthly renewals every month.

Equal order counts between annual and monthly means annual is being chosen at a significantly higher rate per customer. **Customers see enough value to commit upfront for the full year.**

### 5. The Design category is a problem hiding in plain sight

Design is one of the highest order-volume categories - but carries a low AOV and the **highest refund rate** of any category. It also accounts for the highest share of dissatisfaction-related refunds specifically, separate from billing errors or accidents.

This is not a volume story. Customers are buying Design products, finding them unsatisfactory, and asking for their money back. The product selection in this category needs review.



### 6. Refund rates are low overall - but the reasons matter more than the rate

The overall refund rate is **~2.1%** across 1,005 refunded orders - healthy by most measures. But the leading causes are billing errors and accidental purchases, not product dissatisfaction.

These are operational failures, not product failures. They are fixable with clearer pricing communication, renewal reminders, and a confirmation step at checkout - none of which require changes to the product catalogue.



### 7. Discounts are working - but one code is quietly driving the most revenue

Customers have saved a combined **~$1.26M** through discount codes, approximately 4% of total revenue. The `BFCM20` code delivered the highest per-use savings at $125 per use. But when measuring revenue generated from discounted orders, `NEWCUSTOMER10` leads - responsible for **~$1.77M in revenue** across 2,700 uses. A code designed to acquire new customers is quietly one of the most commercially valuable tools the business has.
<br>

<img width="948" height="452" alt="image" src="https://github.com/user-attachments/assets/58d7a6c6-666c-43fe-ba94-fe129b7a9ec6" />

<br>

### 8. AI Tools is the second-largest vendor - and the catalogue is too narrow

Microsoft leads vendor revenue by a significant margin. But **AI Tools is the second-largest vendor**, driven almost entirely by ChatGPT subscriptions - notable given that many AI products can be used for free at a basic level. Customers are actively choosing to pay for premium access.

The business currently carries no Claude, Grok, Gemini, or Deepseek products. Given that AI Tools is already the second-largest revenue category with a narrow selection, expanding this section is a direct, low-risk growth opportunity.


### 9. A significant portion of the customer base is disengaged

RFM scoring reveals that a meaningful share of customers fall into the **At Risk** and **Lost** segments - customers who have purchased before but are showing clear signs of disengagement. Every customer in this dataset has purchased at least twice, confirmed by data. These are not cold leads - they are warm customers who went quiet, making re-engagement more viable than acquiring entirely new ones from scratch.


<img width="752" height="452" alt="image" src="https://github.com/user-attachments/assets/76fc3151-4004-4d94-b552-4401ab2c9553" />


## Business Health Summary

To answer the central question directly - the analysis was evaluated across four dimensions of business health.

### 🟢 Financial Health
- Total revenue of **~$31.8M** with 2025 being the strongest year at ~$17.3M
- Stable AOV of **~$663** with no signs of revenue decline
- ~98% of orders are subscription-based, creating a strong recurring revenue foundation

The business shows solid top-line financial performance with no immediate signs of instability.

### 🟡 Structural Health
- Revenue is heavily concentrated - **45% from the Website**, **43% from Europe**
- A small number of vendors, categories, and products drive a disproportionate share of revenue
- Annual subscriptions dominate, which is healthy but creates renewal dependency

Revenue is strong, but it is not evenly distributed. The business is dependent on a small set of key drivers.

### 🟡 Customer Health
- Strong repeat purchase behaviour - every customer in the dataset has bought at least twice
- Highest value age group is **25–34**, highest performing acquisition channel is **Organic**
- However, **800+ customers are classified as Lost** and another large segment is actively At Risk

The customer base is valuable but retention risk is present and growing.

### 🟡 Risk Signals
- Refund rate of **~2.1%** - within acceptable range but driven by preventable operational causes
- Discounts account for **~4% of revenue** - controlled and not dangerously eroding margin
- Design category showing both high refund rates and dissatisfaction signals

Operational risks are controlled but not negligible, particularly around billing experience and category-level product quality.



### Final Verdict

> **The business is revenue-healthy but structurally imbalanced.**

Strong financial performance and stable recurring demand are real positives. But revenue concentration, customer disengagement, and a few unresolved operational signals mean the business is more fragile than the top-line numbers suggest. It is stable in the short term, scalable with the right optimisations, and vulnerable to structural risks if left unaddressed.



## Recommendations

**1. Investigate the Design category before expanding it**

High order volume combined with the highest refund rate and the highest dissatisfaction rate is a specific signal. Before adding more Design products, the business should understand why the existing ones are underperforming.

**2. Expand the AI Tools catalogue**

AI Tools is already the second-largest revenue-generating vendor with a narrow product selection. Adding Claude, Grok, Gemini, or Deepseek products would directly address existing demand from a customer base already willing to pay for AI subscriptions.

**3. Fix the operational refund causes first**

Billing errors and accidental purchases are the top two refund reasons. Clearer pricing, renewal reminder emails, and a checkout confirmation step would reduce refund volume without touching the product catalogue.

**4. Double down on the NEWCUSTOMER10 code**

This code generates more revenue from discounted orders than any other code in the catalogue. Understanding which customers use it, what they buy, and whether they return is a worthwhile next step before adjusting the discount strategy.

**5. Build a re-engagement strategy for At Risk and Lost customers**

These customers have already demonstrated willingness to purchase more than once. A targeted campaign - especially around renewal periods or new product launches - is a more efficient use of marketing budget than pure new customer acquisition.

**6. Treat Europe and North America as separate strategic markets**

Higher AOV in Europe but higher order volume in North America suggests meaningfully different customer behaviour. A blanket approach to pricing, promotions, and channel strategy across both regions leaves value on the table.



## Limitations

- **No cost or margin data is available.** This analysis can speak to revenue health but not profitability. High revenue from a category does not confirm it is the most valuable category if costs are unknown.
- **The dataset minimum purchase count is 2 per customer.** Single-purchase customer behaviour is not represented in this dataset.
- **FX conversion uses a single `fx_rate_to_usd` value per transaction.** All multi-currency revenue is converted to USD at the rate recorded at time of transaction. Fluctuating rates over time may affect the precision of aggregate USD figures.
- **Data covers early 2024 through mid-2025.** Months at the start of 2024 and the end of 2025 have incomplete data, likely reflecting when the business began systematic recording. Year-over-year comparisons are limited to months where both years have data.

These limitations do not invalidate the findings but should inform how conclusions are applied - particularly at the country level where small absolute numbers can produce large-looking percentages.


## Tools Used
 
All SQL queries are in the `/sql` folder, organised by stage.
 
| Tool | Purpose |
|---|---|
| PostgreSQL | Data staging, cleaning, transformation, and all analysis |
| SQL | CTEs, window functions, conditional aggregation, multi-table joins |
| DBeaver | Query execution and result inspection |



**Temidayo Olubayo**  
Data Analytics | SQL | PostgreSQL
