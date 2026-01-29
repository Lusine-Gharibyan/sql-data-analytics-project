/*
------------------------------------------------------------------------------------------------
Product Report
------------------------------------------------------------------------------------------------
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    3. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue
------------------------------------------------------------------------------------------------
*/

IF OBJECT_ID ('gold.report_products', 'V') IS NOT NULL
    DROP VIEW gold.report_products;
GO

CREATE VIEW gold.report_products AS
WITH base_query AS (
    SELECT
    p.product_key,
    p.product_name,
    p.category,
    p.subcategory,
    p.cost,
    s.customer_key,
    s.order_number,
    s.sales_amount,
    s.quantity,
    s.order_date
    FROM gold.fact_sales AS s
    LEFT JOIN gold.dim_products AS p
    ON s.product_key = p.product_key
    WHERE order_date IS NOT NULL
)

, product_aggregation AS (
    SELECT 
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    COUNT (DISTINCT customer_key) AS total_customers,
    COUNT (DISTINCT order_number) AS total_orders,
    SUM (sales_amount) AS total_sales,
    SUM (quantity) AS total_quantity,
    DATEDIFF (MONTH, MIN (order_date), MAX (order_date)) AS lifespan,
    MAX (order_date) AS last_sale_date
    FROM base_query
    GROUP BY    
        product_key,
        product_name,
        category,
        subcategory,
        cost
)
SELECT 
product_key,
product_name,
category,
subcategory,
cost,
last_sale_date,
DATEDIFF (MONTH, last_sale_date, GETDATE()) AS recency,
CASE WHEN total_sales > 50000 THEN 'High-Performer'
     WHEN total_sales >= 10000 THEN 'Mid-Range'
     ELSE 'Low-Performer'
END AS product_segment,
lifespan,
total_orders,
total_sales,
total_quantity,
total_customers,
CASE WHEN total_orders = 0 THEN 0
     ELSE total_sales / total_orders
END AS avg_order_revenue,
CASE WHEN lifespan = 0 THEN total_sales
     ELSE total_sales / lifespan
END avg_monthly_revenue
FROM product_aggregation
