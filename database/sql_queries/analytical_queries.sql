-- Analytical SQL Queries: E-commerce Analytics

USE ecommerce_db;

-- 1. Product sales value by Country
-- Business Question (BQ): Which countries generate the highest product sales value?
SELECT c.country, SUM(oi.quantity*pr.price) AS product_sale_value
	FROM orders o JOIN order_items oi ON o.order_id=oi.order_id
	JOIN products pr ON oi.product_id=pr.product_id
	JOIN customers c ON c.customer_id=o.customer_id
	WHERE o.order_status='Delivered'
	GROUP BY c.country ORDER BY product_sale_value DESC;

-- 2. Top 10 Revenue Generating Products
-- BQ: Which products generate the highest revenue?
SELECT pr.product_name,
	SUM(o.order_total) AS gross_revenue
	FROM products pr JOIN order_items oi ON oi.product_id=pr.product_id
	JOIN orders o ON o.order_id=oi.order_id
	WHERE o.order_status='Delivered'
	GROUP BY pr.product_name ORDER BY gross_revenue DESC LIMIT 10;

-- 3. Best Selling Categories by Revenue
-- BQ: Which product categories drive the most revenue?
SELECT ca.category_name,SUM(oi.quantity*pr.price) AS gross_revenue
        FROM categories ca JOIN products pr ON ca.category_id=pr.category_id
        JOIN order_items oi ON oi.product_id=pr.product_id
        JOIN orders o ON o.order_id=oi.order_id
        WHERE o.order_status IN ('Delivered','Shipped')
        GROUP BY ca.category_name ORDER BY gross_revenue DESC;

-- 4. Top 5 Customers by Total Spending
-- BQ: Who are the highest-value customers?
SELECT CONCAT(c.first_name,' ',c.last_name) AS customer_name,
        SUM(o.order_total) AS total_spending
    FROM customers c JOIN orders o ON c.customer_id=o.customer_id
    WHERE o.order_status IN ('Delivered','Shipped')
    GROUP BY customer_name ORDER BY total_spending DESC LIMIT 5;

-- 5. Revenue Contributuion by Category(%)
-- BQ: What percentage of total revenue does each category contribute?
SELECT ca.category_name,
	ROUND(SUM(o.order_total)/(SELECT SUM(order_total) FROM orders WHERE order_status='Delivered')
			*100.0,2) AS category_pct
	FROM categories ca JOIN products pr ON ca.category_id=pr.category_id
	JOIN order_items oi ON oi.product_id=pr.product_id
	JOIN orders o ON o.order_id=oi.order_id
	WHERE o.order_status='Delivered'
	GROUP BY ca.category_name ORDER BY category_pct DESC;

-- 6. Monthly Gross Revenue and Net Revenue
-- BQ: How does revenue trend over time after refunds?
SELECT DATE_FORMAT(o.order_date,'%Y-%m') AS order_year_month,
	SUM(o.order_total) AS gross_revenue,
	SUM(o.order_total-IFNULL(r.refund_amount,0)) AS net_revenue
	FROM orders o LEFT JOIN returns r ON o.order_id=r.order_id
	WHERE o.order_status='Delivered' GROUP BY order_year_month
	ORDER BY order_year_month;

-- 7. Customer Lifetime Value (CLV)
-- BQ: What is the lifetime value of each customer?
WITH refunds_per_order (
	SELECT order_id,SUM(refund_amount) AS refund_amount
	FROM returns GROUP BY order_id
)
SELECT CONCAT(c.first_name,' ',c.last_name) AS customer_name,
	SUM(o.order_total-COALESCE(rpo.refund_amount,0)) AS CLV
	FROM customers c JOIN orders o ON c.customer_id=o.customer_id
	LEFT JOIN refunds_per_order rpo ON rpo.order_id=o.order_id
	WHERE o.order_status='Delivered' 
	GROUP BY c.customer_id ORDER BY CLV DESC LIMIT 10;

-- 8. Repeat vs One-Time Customers
-- BQ: How many customers are repeat vs one-time buyers?
WITH customer_orders AS(
SELECT customer_id,COUNT(DISTINCT order_id) AS order_count
	FROM orders WHERE order_status='Delivered' GROUP BY customer_id
)
SELECT CASE
		WHEN order_count=1 THEN 'One-time'
		ELSE 'Repeat'
	END AS customer_type,
	COUNT(*) AS total_customer
	FROM customer_orders GROUP BY customer_type

-- 9. Customer Return Rate
-- BQ: What is the return rate per customer?
WITH customer_orders AS (
    SELECT o.customer_id, COUNT(DISTINCT o.order_id) AS total_orders,
        COUNT(DISTINCT r.order_id) AS returned_orders
    FROM orders o LEFT JOIN returns r ON o.order_id = r.order_id
    WHERE o.order_status = 'Delivered' GROUP BY o.customer_id
)
SELECT customer_id,
    ROUND(returned_orders / total_orders, 2) AS return_rate
    FROM customer_orders ORDER BY return_rate DESC;

-- 10. On-Time vs Late Delivery Rate
-- BQ: How often are orders delivered on time?
SELECT CASE 
		WHEN DATEDIFF(delivered_date,order_date) <=7 THEN 'On time'
		ELSE 'Late' 
	END AS delivery_status,
	COUNT(*) AS order_counts,
	ROUND(COUNT(*)/SUM(COUNT(*)) OVER()*100,2) AS  pct_of_orders
	FROM orders WHERE o.order_status='Delivered' GROUP BY delivery_status;

-- 11. Orders by Status Trend Over Time
-- BQ: How do order statuses change over time?
SELECT DATE_FORMAT(o.order_date,'%Y-%m') AS order_year_month,
	o.order_status, COUNT(*) AS order_counts
	FROM orders o GROUP BY order_year_month,o.order_status
	ORDER BY order_year_month,o.order_status;

-- 12. Revenue vs Quantity Comparison
-- BQ: DO high-volume products also generate high revenue?
SELECT pr.product_name,
	SUM(oi.quantity) AS units_sold,
	SUM(oi.quantity * pr.price) AS revenue
	FROM products pr JOIN order_items oi ON pr.product_id = oi.product_id
	JOIN orders o ON o.order_id = oi.order_id
	WHERE o.order_status = 'Delivered' GROUP BY pr.product_name
	ORDER BY revenue DESC;

-- 13. Average Refund Lag (days between delivery & return)
-- BQ: How long after delivery do customers typically return items?
SELECT
    ROUND(AVG(DATEDIFF(r.return_date, o.delivered_date)), 2) AS avg_refund_lag_days
	FROM returns r JOIN orders o ON r.order_id = o.order_id 
	WHERE o.order_status = 'Delivered';
