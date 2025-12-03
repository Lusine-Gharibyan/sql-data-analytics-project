/*
----------------------------------------------------------------------------------------------
Change over time analysis: to track trends, growth, and changes in key metrics over time
Cumulative analysis: to calculate running totals or moving averages for key metrics
Performance analysis: to measure the performance of products, customers, or regions over time
Part to whole analysis: to evaluate differences between categories
Data segmentation analysis: to group data into meaningful categories for targeted insights
----------------------------------------------------------------------------------------------
*/

-- Change over time analysis
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

-- Cumulative analysis
-- Calculate running total of sales over time and moving average of price

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

-- Performance analysis
/* Analyse the yearly performance of products by comparing their sales 
to both the average sales performance of the product and the previous year's sales */

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

-- Part to whole analysis
-- Which categories contribute the most to overall sales?

WITH category_sales AS (
	SELECT 
	category,
	SUM (sales_amount) AS total_sales_per_cat
	FROM gold.fact_sales AS s
	LEFT JOIN gold.dim_products AS p
	ON s.product_key = p.product_key
	GROUP BY category
)
SELECT 
category,
total_sales_per_cat,
SUM (total_sales_per_cat) OVER () AS total_sales,
ROUND ((CAST (total_sales_per_cat AS FLOAT) / SUM (total_sales_per_cat) OVER ()) * 100, 2) AS percentage_of_total
FROM category_sales
ORDER BY total_sales_per_cat DESC;

-- Data segmentation analysis
/*Segment products into cost ranges and 
count how many products fall into each segment*/

WITH product_segment AS (
	SELECT 
	product_key,
	product_name,
	cost,
	CASE WHEN cost < 100 THEN 'Below 100'
		 WHEN cost BETWEEN 100 AND 500 THEN '100-500'
		 WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
		 ELSE 'Above 1000'
	END AS cost_range
	FROM gold.dim_products
)
SELECT 
cost_range,
COUNT (product_key) AS total_products
FROM product_segment
GROUP BY cost_range
ORDER BY total_products DESC;
