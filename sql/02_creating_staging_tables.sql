-- STAGING TABLES
-- Casts all columns to correct types.
-- NULLIF() handles empty strings cleanly without errors.
-- Raw tables are preserved so no changes are made to source data.
--------------------------------------------------------------

-- Events staging
CREATE TABLE events AS
SELECT
    event_id,
    event_type,
    NULLIF(event_date, '')::TIMESTAMP AS event_date,
    customer_id,
    product_id,
    country,
    region,
    channel,
    payment_method,
    currency,
    NULLIF(quantity, '')::INTEGER AS quantity,
    NULLIF(unit_price_local, '')::NUMERIC AS unit_price_local,
    discount_code,
    NULLIF(discount_local, '')::NUMERIC AS discount_local,
    NULLIF(tax_local, '')::NUMERIC AS tax_local,
    NULLIF(net_revenue_local, '')::NUMERIC AS net_revenue_local,
    NULLIF(fx_rate_to_usd, '')::NUMERIC AS fx_rate_to_usd,
    NULLIF(net_revenue_usd, '')::NUMERIC AS net_revenue_usd,
    NULLIF(is_refunded, '')::BOOLEAN AS is_refunded,
    NULLIF(refund_datetime, '')::TIMESTAMP AS refund_datetime,
    refund_reason
FROM events_raw;

-- Products staging
CREATE TABLE products AS
SELECT
    product_id,
    product_name,
    category,
    CAST(is_subscription AS BOOLEAN) AS is_subscription,
    billing_cycle,
    CAST(base_price_usd AS NUMERIC) AS base_price_usd,
    CAST(first_release_date AS TIMESTAMP) AS first_release_date,
    vendor,
    resale_model,
    brand_safe_name,
    product_name_orig,
    CAST(base_price_usd_orig AS NUMERIC) AS base_price_usd_orig,
    base_key,
    product_version
FROM products_raw;

-- Customers staging
CREATE TABLE customers AS
SELECT
    customer_id,
    CAST(signup_date AS TIMESTAMP) AS signup_date,
    region,
    currency_preference,
    segment,
    acquisition_channel,
    age_band,
    country,
    CAST(country_latitude AS NUMERIC) AS country_latitude,
    CAST(country_longitude AS NUMERIC) AS country_longitude
FROM customers_raw;
