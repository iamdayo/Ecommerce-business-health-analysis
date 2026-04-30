-- RAW TABLES
-- All columns ingested as TEXT to avoid import failures.
-- No transformations applied here — source data is preserved.

CREATE TABLE events_raw (
    event_id TEXT,
    event_type TEXT,
    event_date TEXT,
    customer_id TEXT,
    product_id TEXT,
    country TEXT,
    latitude TEXT,
    longitude TEXT,
    region TEXT,
    channel TEXT,
    payment_method TEXT,
    currency TEXT,
    quantity TEXT,
    unit_price_local TEXT,
    discount_code TEXT,
    discount_local TEXT,
    tax_local TEXT,
    net_revenue_local TEXT,
    fx_rate_to_usd TEXT,
    net_revenue_usd TEXT,
    is_refunded TEXT,
    refund_datetime TEXT,
    refund_reason TEXT
);

CREATE TABLE products_raw (
    product_name TEXT,
    category TEXT,
    is_subscription TEXT,
    billing_cycle TEXT,
    base_price_usd TEXT,
    first_release_date TEXT,
    vendor TEXT,
    resale_model TEXT,
    brand_safe_name TEXT,
    product_name_orig TEXT,
    base_price_usd_orig TEXT,
    base_key TEXT,
    product_version TEXT
);

CREATE TABLE customers_raw (
    customer_id TEXT,
    signup_date TEXT,
    region TEXT,
    currency_preference TEXT,
    segment TEXT,
    acquisition_channel TEXT,
    age_band TEXT,
    country TEXT,
    country_latitude TEXT,
    country_longitude TEXT
);
