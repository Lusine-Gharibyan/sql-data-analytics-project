/*
-------------------------------------------------------------------------------
Performance Analysis
-------------------------------------------------------------------------------
Purpose:
    - To measure the performance of products, customers, or regions over time.
    - To track yearly trends and growth.
-------------------------------------------------------------------------------
*/

/* Analyse the yearly performance of products by comparing their sales to both 
the average sales performance of the product and the previous year's sales */
WITH yearly_product_sales AS (
	SELECT 
	YEAR (s.order_date) AS order_year,
	p.product_name AS product_name,
	SUM (s.sales_amount) AS current_sales
	FROM gold.fact_sales AS s
	LEFT JOIN gold.dim_products AS p
	ON s.product_key = p.product_key
	WHERE s.order_date IS NOT NULL
	GROUP BY YEAR (s.order_date), p.product_name
)
SELECT 
order_year,
product_name,
current_sales,
AVG (current_sales) OVER (PARTITION BY product_name) AS average_sales,
current_sales - AVG (current_sales) OVER (PARTITION BY product_name) AS diff_avg,
LAG (current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS py_sales,
current_sales - LAG (current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS diff_py
FROM yearly_product_sales;

-- Detect products with 3 consecutive months of decreasing sales
WITH cte1 AS (
	SELECT 
	YEAR (s.order_date) AS order_year,
	MONTH (s.order_date) AS order_month,
	p.product_name AS product_name,
	p.product_key AS product_key,
	SUM (s.sales_amount) AS current_month_sales
	FROM gold.fact_sales AS s
	LEFT JOIN gold.dim_products AS p
	ON s.product_key = p.product_key
	WHERE s.order_date IS NOT NULL
	GROUP BY 
		p.product_name,
		p.product_key,
		YEAR (s.order_date),
		MONTH (s.order_date)
)
, cte2 AS (
	SELECT 
	order_year,
	order_month,
	product_name,
	current_month_sales,
	LAG (current_month_sales, 1) OVER (PARTITION BY product_key, order_year ORDER BY order_month) AS previous_month_sales,
	LAG (current_month_sales, 2) OVER (PARTITION BY product_key, order_year ORDER BY order_month) AS previous_2_month_sales
	FROM cte1
)
SELECT * 
FROM cte2
WHERE current_month_sales < previous_month_sales AND previous_month_sales < previous_2_month_sales

-- Pareto Analysis (80/20 Rule) – customer sales contribution per time period
WITH cte1 AS (
	SELECT 
	YEAR (s.order_date) AS order_year,
	c.customer_key AS customer_key,
	c.first_name AS first_name,
	c.last_name AS last_name,
	SUM (s.sales_amount) AS total_sales
	FROM gold.fact_sales AS s
	LEFT JOIN gold.dim_customers AS c
	ON s.customer_key = c.customer_key
	WHERE s.order_date IS NOT NULL
	GROUP BY 
		YEAR (s.order_date),
		c.customer_key,
		c.first_name,
		c.last_name
)
, cte2 AS (
	SELECT 
	order_year,
	customer_key,
	CONCAT (first_name, ' ', last_name) AS full_name,
	total_sales,
	ROW_NUMBER () OVER (PARTITION BY order_year ORDER BY total_sales DESC) AS ranking,
	SUM (total_sales) OVER (PARTITION BY order_year ORDER BY total_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales,
	SUM (total_sales) OVER (PARTITION BY order_year ORDER BY total_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / CAST (SUM (total_sales) OVER (PARTITION BY order_year) AS FLOAT) AS cumulative_sales_pct
	FROM cte1
)
SELECT 
order_year,
customer_key,
full_name,
total_sales,
ranking,
cumulative_sales,
cumulative_sales_pct,
CASE WHEN cumulative_sales_pct <= 0.8 THEN 'Top_80_Percent'
	 ELSE 'Remaining_20_Percent'
END pareto_flag
FROM cte2
