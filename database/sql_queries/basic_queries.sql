-- Basic SQL Queries: E-commerce Analytics
-- Purpose: MySQL joins,aggregations, and others

USE ecommerce_db;

-- 1. Total customers by country
SELECT country, COUNT(customer_id) AS total_customers 
	FROM customers GROUP BY country 
	ORDER BY total_customers DESC;

-- 2. Customers from USA
SELECT CONCAT(first_name,' ',last_name) AS name 
	FROM customers WHERE country='USA';

-- 3. Top 10 customers by number of orders
SELECT CONCAT(c.first_name,' ',c.last_name) AS customer_name, 
	COUNT(o.order_id) AS total_order
	FROM customers c JOIN orders o ON c.customer_id=o.customer_id GROUP BY customer_name
	ORDER BY total_order DESC LIMIT 10;

-- 4. Order per Month
SELECT DATE_FORMAT(order_date,'%Y-%m') AS order_year_month,COUNT(order_id) AS total_orders
	FROM orders WHERE order_status='Delivered' 
	GROUP BY order_year_month ORDER BY order_year_month;

-- 5. Number of Cancelled Orders
SELECT COUNT(order_id) AS cancelled_orders FROM orders WHERE order_status='Cancelled';

-- 6. Average Order Value
SELECT ROUND(AVG(order_total),2) AS avg_order_value 
	FROM orders where order_status IN ('Shipped','Delivered');

-- 7. Number of products per category
SELECT ca.category_name, COUNT(pr.product_id) AS total_products
	FROM products pr JOIN categories ca ON pr.category_id=ca.category_id
	GROUP BY ca.category_name;

-- 8. Most used payment method
SELECT method,COUNT(*) AS total_number 
	FROM payments GROUP BY method 
	ORDER BY total_number DESC LIMIT 1;

-- 9. Total number of returns
SELECT COUNT(*) AS total_returns FROM returns;

-- 10. Reasons for returns
SELECT reason,COUNT(*) AS total_returns 
	FROM returns GROUP BY reason ORDER BY total_returns DESC;

-- 11. Orders that were returned vs not returned
SELECT  CASE
		WHEN r.order_id IS NOT NULL THEN 'Returned'
		ELSE 'Not Returned'
	END AS return_status,
	COUNT(o.order_id) AS total_orders FROM orders o LEFT JOIN
	returns r ON o.order_id=r.order_id WHERE o.order_status='Delivered'
	GROUP BY return_status;

-- 12. Return Rate
SELECT ROUND(COUNT(r.order_id)*100.0/COUNT(o.order_id),2) AS return_rate_pct
	FROM orders o LEFT JOIN returns r On o.order_id=r.order_id 
	WHERE o.order_status='Delivered';

-- 13. Average refund amount
SELECT ROUND(AVG(refund_amount), 2) AS avg_refund_amount
	FROM returns;

-- 14. Average delivery time
SELECT ROUND(AVG(DATEDIFF(delivered_date,order_date)),2) AS avg_delivery_days
        FROM orders WHERE order_status='Delivered';
