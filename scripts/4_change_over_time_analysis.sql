/*
---------------------------------------------------------------------
Change Over Time Analysis
---------------------------------------------------------------------
Purpose:
    - To track trends, growth, and changes in key metrics over time.
    - For time-series analysis and identifying seasonality.
---------------------------------------------------------------------
*/

-- Analyse sales performance over time
SELECT 
YEAR (order_date) AS order_year,
MONTH (order_date) AS order_month,
SUM (sales_amount) AS total_sales,
COUNT (DISTINCT customer_key) AS total_customers,
SUM (quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR (order_date), MONTH (order_date)
ORDER BY YEAR (order_date), MONTH (order_date);

-- YoY growth by category
WITH cte AS (
    SELECT 
    YEAR (s.order_date) AS order_year,
    p.category AS category,
    SUM (s.sales_amount) AS current_year_sales
    FROM gold.fact_sales AS s
    LEFT JOIN gold.dim_products AS p
    ON s.product_key = p.product_key
    WHERE s.order_date IS NOT NULL
    GROUP BY 
        YEAR (s.order_date), 
        p.category
)
SELECT 
order_year,
category,
current_year_sales,
LAG (current_year_sales) OVER (PARTITION BY category ORDER BY order_year) AS previous_year_sales,
(current_year_sales - LAG (current_year_sales) OVER (PARTITION BY category ORDER BY order_year)) / CAST (LAG (current_year_sales) OVER (PARTITION BY category ORDER BY order_year) AS FLOAT) AS yoy_growth
FROM cte;
