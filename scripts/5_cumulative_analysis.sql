/*
----------------------------------------------------------------------
Cumulative Analysis
----------------------------------------------------------------------
Purpose:
    - To calculate running totals or moving averages for key metrics.
    - To track performance over time cumulatively.
----------------------------------------------------------------------
*/

-- Running total of sales over time and moving average of price
SELECT 
order_date,
total_sales,
SUM (total_sales) OVER (ORDER BY order_date) AS running_total,
AVG (average_price) OVER (ORDER BY order_date) AS moving_average
FROM (
	SELECT 
	DATETRUNC (YEAR, order_date) AS order_date,
	SUM (sales_amount) AS total_sales,
	AVG (price) AS average_price
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATETRUNC (YEAR, order_date)
)t;

-- Yearly running total of sales per product
WITH cte AS (
	SELECT 
	YEAR (s.order_date) AS order_year,
	p.product_key AS product_key,
	p.product_name AS product_name,
	SUM (s.sales_amount) AS total_sales
	FROM gold.fact_sales AS s
	LEFT JOIN gold.dim_products AS p
	ON s.product_key = p.product_key
	WHERE s.order_date IS NOT NULL
	GROUP BY 
		YEAR (s.order_date),
		p.product_key,
		p.product_name
)
SELECT 
order_year,
product_key,
product_name,
total_sales,
SUM (total_sales) OVER (PARTITION BY product_key ORDER BY order_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM cte
ORDER BY product_name, order_year;

-- Rolling 3-month sales per product within the year
WITH cte AS (
	SELECT 
	YEAR (s.order_date) AS order_year,
	MONTH (s.order_date) AS order_month,
	p.product_key AS product_key,
	p.product_name AS product_name,
	SUM (s.sales_amount) AS total_sales
	FROM gold.fact_sales AS s
	LEFT JOIN gold.dim_products AS p
	ON s.product_key = p.product_key
	WHERE s.order_date IS NOT NULL
	GROUP BY 
		YEAR (s.order_date),
		MONTH (s.order_date),
		p.product_key,
		p.product_name
)
SELECT 
order_year,
order_month,
product_name,
total_sales,
SUM (total_sales) OVER (PARTITION BY product_key, order_year ORDER BY order_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3_month_sales
FROM cte;
