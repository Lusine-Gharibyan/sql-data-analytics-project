/*
-------------------------------------------------------------------------------------
Ranking Analysis
-------------------------------------------------------------------------------------
Purpose:
    - To rank items (e.g., products, customers) based on performance or other metrics.
    - To identify top performers or laggards.
-------------------------------------------------------------------------------------
*/

-- Top 5 products generating the highest revenue
SELECT TOP 5
	p.product_name,
	SUM (s.sales_amount) AS revenue
FROM gold.fact_sales AS s
LEFT JOIN gold.dim_products AS p
ON s.product_key = p.product_key
GROUP BY p.product_name
ORDER BY revenue DESC;

-- Top 5 products generating the highest revenue (WITH SUBQUERY)
SELECT * 
FROM (
	SELECT
		p.product_name,
		SUM (s.sales_amount) AS revenue,
		ROW_NUMBER () OVER (ORDER BY SUM (s.sales_amount) DESC) AS ranking
	FROM gold.fact_sales AS s
	LEFT JOIN gold.dim_products AS p
	ON s.product_key = p.product_key
	GROUP BY p.product_name
)t
WHERE ranking <= 5;

-- 5 worst-performing products
SELECT TOP 5
	p.product_name,
	SUM (s.sales_amount) AS revenue
FROM gold.fact_sales AS s
LEFT JOIN gold.dim_products AS p
ON s.product_key = p.product_key
GROUP BY p.product_name
ORDER BY revenue ASC;

-- Top 10 customers generating the highest revenue
SELECT TOP 10
	c.customer_id,
	c.first_name,
	c.last_name,
SUM (s.sales_amount) AS total_revenue
FROM gold.fact_sales AS s
LEFT JOIN gold.dim_customers AS c
ON s.customer_key = c.customer_key
GROUP BY
	c.customer_id,
	c.first_name,
	c.last_name
ORDER BY total_revenue DESC;

-- 3 customers with the fewest orders placed
SELECT TOP 3
	c.customer_id,
	c.first_name,
	c.last_name,
COUNT (DISTINCT order_number) AS total_orders
FROM gold.fact_sales AS s
LEFT JOIN gold.dim_customers AS c
ON s.customer_key = c.customer_key
GROUP BY
	c.customer_id,
	c.first_name,
	c.last_name
ORDER BY total_orders ASC;
