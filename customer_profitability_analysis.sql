-- ============================================================
-- CUSTOMER PROFITABILITY & LIFETIME VALUE ANALYTICS
-- PostgreSQL + Excel
-- Dataset: 113K+ e-commerce transactions
-- ============================================================


-- ============================================================
-- 01. DATA QUALITY CHECK
-- ============================================================

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(DISTINCT product_name) AS unique_products,
    COUNT(DISTINCT category_name) AS unique_categories
FROM ecommerce_raw;


-- Check missing values

SELECT
    COUNT(*) AS total_rows,

    COUNT(*) FILTER (
        WHERE customer_id IS NULL
    ) AS missing_customer_id,

    COUNT(*) FILTER (
        WHERE order_id IS NULL
    ) AS missing_order_id,

    COUNT(*) FILTER (
        WHERE product_name IS NULL
    ) AS missing_product,

    COUNT(*) FILTER (
        WHERE sales_per_order IS NULL
    ) AS missing_sales,

    COUNT(*) FILTER (
        WHERE profit_per_order IS NULL
    ) AS missing_profit

FROM ecommerce_raw;


-- ============================================================
-- 02. DATA CLEANING
-- ============================================================

DROP TABLE IF EXISTS ecommerce_clean;

CREATE TABLE ecommerce_clean AS
SELECT
    customer_id,
    customer_first_name,
    customer_last_name,
    category_name,
    product_name,
    customer_segment,
    customer_city,
    customer_state,
    customer_country,
    customer_region,
    delivery_status,

    CASE
        WHEN order_date LIKE '%-%'
        THEN TO_DATE(order_date, 'DD-MM-YYYY')
        ELSE TO_DATE(order_date, 'MM/DD/YYYY')
    END AS order_date,

    order_id,

    CASE
        WHEN ship_date LIKE '%-%'
        THEN TO_DATE(ship_date, 'DD-MM-YYYY')
        ELSE TO_DATE(ship_date, 'MM/DD/YYYY')
    END AS ship_date,

    shipping_type,
    days_for_shipment_scheduled,
    days_for_shipment_real,
    order_item_discount,
    sales_per_order,
    order_quantity,
    profit_per_order,

    CASE
        WHEN sales_per_order <> 0
        THEN ROUND(
            (profit_per_order / sales_per_order * 100)::numeric,
            2
        )
    END AS profit_margin_pct,

    days_for_shipment_real
    - days_for_shipment_scheduled
    AS shipping_delay_days

FROM ecommerce_raw;


-- Verify cleaned table

SELECT COUNT(*) AS clean_records
FROM ecommerce_clean;


-- ============================================================
-- 03. CUSTOMER PROFITABILITY
-- ============================================================

DROP TABLE IF EXISTS customer_profitability;

CREATE TABLE customer_profitability AS

SELECT
    customer_id,

    COUNT(DISTINCT order_id) AS total_orders,

    ROUND(
        SUM(sales_per_order)::numeric,
        2
    ) AS total_sales,

    ROUND(
        SUM(profit_per_order)::numeric,
        2
    ) AS total_profit,

    SUM(order_quantity) AS total_quantity,

    ROUND(
        AVG(sales_per_order)::numeric,
        2
    ) AS average_order_value,

    MIN(order_date) AS first_order,

    MAX(order_date) AS last_order,

    MAX(order_date) - MIN(order_date)
        AS lifetime_days,

    CURRENT_DATE - MAX(order_date)
        AS recency_days,

    ROUND(
        (
            SUM(profit_per_order)
            / NULLIF(SUM(sales_per_order), 0)
            * 100
        )::numeric,
        2
    ) AS profit_margin_pct

FROM ecommerce_clean

GROUP BY customer_id;


-- Top 10 profitable customers

SELECT
    customer_id,
    total_orders,
    total_sales,
    total_profit,
    average_order_value,
    lifetime_days,
    recency_days,
    profit_margin_pct

FROM customer_profitability

ORDER BY total_profit DESC

LIMIT 10;


-- ============================================================
-- 04. OVERALL BUSINESS KPIs
-- ============================================================

SELECT
    COUNT(DISTINCT customer_id)
        AS total_customers,

    COUNT(DISTINCT order_id)
        AS total_orders,

    ROUND(
        SUM(sales_per_order)::numeric,
        2
    ) AS total_sales,

    ROUND(
        SUM(profit_per_order)::numeric,
        2
    ) AS total_profit,

    ROUND(
        (
            SUM(sales_per_order)
            / COUNT(DISTINCT order_id)
        )::numeric,
        2
    ) AS average_order_value,

    ROUND(
        (
            SUM(profit_per_order)
            / NULLIF(
                SUM(sales_per_order),
                0
            )
            * 100
        )::numeric,
        2
    ) AS profit_margin_pct

FROM ecommerce_clean;


-- ============================================================
-- 05. REPEAT CUSTOMER ANALYSIS
-- ============================================================

SELECT
    COUNT(*) AS total_customers,

    COUNT(*) FILTER (
        WHERE total_orders > 1
    ) AS repeat_customers,

    ROUND(
        COUNT(*) FILTER (
            WHERE total_orders > 1
        )::numeric
        / COUNT(*) * 100,
        2
    ) AS repeat_customer_pct

FROM customer_profitability;


-- ============================================================
-- 06. RFM CUSTOMER SEGMENTATION
-- ============================================================

WITH rfm AS (

    SELECT
        customer_id,
        recency_days,
        total_orders,
        total_sales,
        total_profit,

        NTILE(5) OVER (
            ORDER BY recency_days DESC
        ) AS r_score,

        NTILE(5) OVER (
            ORDER BY total_orders
        ) AS f_score,

        NTILE(5) OVER (
            ORDER BY total_sales
        ) AS m_score

    FROM customer_profitability
),

segmented AS (

    SELECT
        *,

        CASE

            WHEN r_score >= 4
             AND f_score >= 4
             AND m_score >= 4
                THEN 'Champions'

            WHEN r_score >= 3
             AND f_score >= 4
                THEN 'Loyal Customers'

            WHEN r_score >= 4
             AND f_score <= 2
                THEN 'Potential / New'

            WHEN r_score <= 2
             AND f_score >= 3
                THEN 'At Risk'

            WHEN r_score <= 2
             AND f_score <= 2
                THEN 'Lost / Inactive'

            ELSE 'Regular Customers'

        END AS customer_segment

    FROM rfm
)

SELECT
    customer_segment,

    COUNT(*) AS customers,

    ROUND(
        SUM(total_sales)::numeric,
        2
    ) AS total_sales,

    ROUND(
        SUM(total_profit)::numeric,
        2
    ) AS total_profit,

    ROUND(
        AVG(total_sales)::numeric,
        2
    ) AS avg_customer_sales

FROM segmented

GROUP BY customer_segment

ORDER BY total_profit DESC;


-- ============================================================
-- 07. PRODUCT PROFITABILITY
-- ============================================================

SELECT
    product_name,

    COUNT(DISTINCT order_id)
        AS orders,

    SUM(order_quantity)
        AS quantity_sold,

    ROUND(
        SUM(sales_per_order)::numeric,
        2
    ) AS sales,

    ROUND(
        SUM(profit_per_order)::numeric,
        2
    ) AS profit,

    ROUND(
        (
            SUM(profit_per_order)
            / NULLIF(
                SUM(sales_per_order),
                0
            )
            * 100
        )::numeric,
        2
    ) AS profit_margin_pct

FROM ecommerce_clean

GROUP BY product_name

ORDER BY profit DESC

LIMIT 20;


-- ============================================================
-- 08. CATEGORY PROFITABILITY
-- ============================================================

SELECT
    category_name,

    COUNT(DISTINCT order_id)
        AS orders,

    SUM(order_quantity)
        AS quantity_sold,

    ROUND(
        SUM(sales_per_order)::numeric,
        2
    ) AS sales,

    ROUND(
        SUM(profit_per_order)::numeric,
        2
    ) AS profit,

    ROUND(
        (
            SUM(profit_per_order)
            / NULLIF(
                SUM(sales_per_order),
                0
            )
            * 100
        )::numeric,
        2
    ) AS profit_margin_pct

FROM ecommerce_clean

GROUP BY category_name

ORDER BY profit DESC;


-- ============================================================
-- 09. MONTHLY SALES & PROFIT
-- ============================================================

WITH monthly AS (

    SELECT
        DATE_TRUNC(
            'month',
            order_date
        )::date AS month,

        SUM(sales_per_order) AS sales,

        SUM(profit_per_order) AS profit,

        COUNT(DISTINCT order_id)
            AS orders,

        COUNT(DISTINCT customer_id)
            AS customers

    FROM ecommerce_clean

    GROUP BY 1
)

SELECT
    month,

    ROUND(
        sales::numeric,
        2
    ) AS sales,

    ROUND(
        profit::numeric,
        2
    ) AS profit,

    orders,

    customers,

    ROUND(
        (
            (
                sales
                - LAG(sales)
                  OVER (
                      ORDER BY month
                  )
            )
            / NULLIF(
                LAG(sales)
                OVER (
                    ORDER BY month
                ),
                0
            )
            * 100
        )::numeric,
        2
    ) AS mom_growth_pct

FROM monthly

ORDER BY month;


-- ============================================================
-- 10. REGIONAL PROFITABILITY
-- ============================================================

SELECT
    customer_region,

    COUNT(DISTINCT customer_id)
        AS customers,

    COUNT(DISTINCT order_id)
        AS orders,

    ROUND(
        SUM(sales_per_order)::numeric,
        2
    ) AS sales,

    ROUND(
        SUM(profit_per_order)::numeric,
        2
    ) AS profit,

    ROUND(
        (
            SUM(profit_per_order)
            / NULLIF(
                SUM(sales_per_order),
                0
            )
            * 100
        )::numeric,
        2
    ) AS profit_margin_pct

FROM ecommerce_clean

GROUP BY customer_region

ORDER BY profit DESC;


-- ============================================================
-- 11. DISCOUNT ANALYSIS
-- ============================================================

SELECT

    CASE

        WHEN order_item_discount = 0
            THEN '0%'

        WHEN order_item_discount <= 0.10
            THEN '1-10%'

        WHEN order_item_discount <= 0.20
            THEN '11-20%'

        WHEN order_item_discount <= 0.30
            THEN '21-30%'

        ELSE '30%+'

    END AS discount_bucket,

    COUNT(DISTINCT order_id)
        AS orders,

    ROUND(
        SUM(sales_per_order)::numeric,
        2
    ) AS sales,

    ROUND(
        SUM(profit_per_order)::numeric,
        2
    ) AS profit,

    ROUND(
        (
            SUM(profit_per_order)
            / NULLIF(
                SUM(sales_per_order),
                0
            )
            * 100
        )::numeric,
        2
    ) AS profit_margin_pct

FROM ecommerce_clean

GROUP BY discount_bucket

ORDER BY
    MIN(order_item_discount);


-- ============================================================
-- 12. SHIPPING ANALYSIS
-- ============================================================

SELECT
    shipping_type,

    delivery_status,

    COUNT(DISTINCT order_id)
        AS orders,

    ROUND(
        AVG(shipping_delay_days)::numeric,
        2
    ) AS avg_shipping_delay_days,

    ROUND(
        SUM(sales_per_order)::numeric,
        2
    ) AS sales,

    ROUND(
        SUM(profit_per_order)::numeric,
        2
    ) AS profit

FROM ecommerce_clean

GROUP BY
    shipping_type,
    delivery_status

ORDER BY avg_shipping_delay_days DESC;


-- ============================================================
-- 13. HIGH REVENUE / LOW MARGIN CUSTOMERS
-- ============================================================

SELECT
    customer_id,

    total_orders,

    ROUND(
        total_sales::numeric,
        2
    ) AS total_sales,

    ROUND(
        total_profit::numeric,
        2
    ) AS total_profit,

    profit_margin_pct

FROM customer_profitability

WHERE total_sales >
    (
        SELECT AVG(total_sales)
        FROM customer_profitability
    )

AND profit_margin_pct <
    (
        SELECT AVG(profit_margin_pct)
        FROM customer_profitability
    )

ORDER BY total_sales DESC

LIMIT 20;