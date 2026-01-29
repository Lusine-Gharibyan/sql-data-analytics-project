/*
-------------------------------------------------------------------------------
Data Segmentation Analysis
-------------------------------------------------------------------------------
Purpose:
    - To group data into meaningful categories for targeted insights.
    - For customer segmentation, product categorization, or regional analysis.
-------------------------------------------------------------------------------
*/

-- Segment products into cost ranges and count how many products fall into each segment
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

-- Customer Purchase Frequency Buckets
WITH cte AS (
	SELECT 
	c.customer_key AS customer_key,
	c.first_name AS first_name,
	c.last_name AS last_name,
	COUNT (DISTINCT s.order_number) AS order_count
	FROM gold.fact_sales AS s
	LEFT JOIN gold.dim_customers AS c
	ON s.customer_key = c.customer_key
	GROUP BY 
		c.customer_key,
		c.first_name,
		c.last_name
)
SELECT 
customer_key,
CONCAT (first_name, ' ', last_name) AS full_name,
order_count,
CASE WHEN order_count = 1 THEN '1 purchase'
	 WHEN order_count BETWEEN 2 AND 3 THEN '2–3 purchases'
	 WHEN order_count BETWEEN 4 AND 10 THEN '4-10 purchases'
	 WHEN order_count > 10 THEN '10+ purchases'
END purchase_frequency
FROM cte
ORDER BY order_count DESC;
