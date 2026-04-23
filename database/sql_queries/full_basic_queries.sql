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

-- 3. Check if any duplicate emails
SELECT email, COUNT(*) AS duplicate_count 
	FROM customers GROUP BY email 
	HAVING COUNT(*)>1;

-- 4. Customer who placed at least one order
SELECT CONCAT(first_name,' ',last_name) AS customer_name 
	FROM customers c WHERE EXISTS (
	SELECT 1 FROM orders o WHERE o.customer_id=c.customer_id
	);

-- 5. Customers with no orders
SELECT CONCAT(first_name,' ',last_name) AS customer_name 
	FROM customers c LEFT JOIN orders o ON c.customer_id=o.customer_id
	 WHERE o.order_id IS NULL;

-- 6. Top 10 customers by number of orders
SELECT CONCAT(c.first_name,' ',c.last_name) AS customer_name, 
	COUNT(o.order_id) AS total_order
	FROM customers c JOIN orders o ON c.customer_id=o.customer_id GROUP BY customer_name
	ORDER BY total_order DESC LIMIT 10;

-- 7. Top 10 customers by completed orders (Shipped and Delivered)
SELECT CONCAT(c.first_name,' ',c.last_name) AS customer_name, 
	COUNT(o.order_id) AS total_order
	FROM customers c JOIN orders o ON c.customer_id-o.customer_id 
	WHERE o.order_status IN ('Shipped','Delivered') GROUP BY customer_name
	ORDER BY total_order DESC LIMIT 10;

-- 8. Order per Year
SELECT YEAR(order_date) AS order_year, COUNT(order_id) AS total_orders 
	FROM orders WHERE order_status='Delivered'
	GROUP BY order_year ORDER BY order_year;

-- 9. Order per Month
SELECT DATE_FORMAT(order_date,'%Y-%m') AS order_year_month,COUNT(order_id) AS total_orders
	FROM orders WHERE order_status='Delivered' 
	GROUP BY order_year_month ORDER BY order_year_month;

-- 10. Orders with Free Shipping
SELECT order_status, COUNT(*) AS total_orders 
FROM orders WHERE shipping_fee=0.0 GROUP BY order_status;

-- 11. Number of Cancelled Orders
SELECT COUNT(order_id) AS cancelled_orders FROM orders WHERE order_status='Cancelled';

-- 12. Order Status Percentage
SELECT order_status, COUNT(order_id) AS total_orders, 
	ROUND(COUNT(order_id)*100.0/(SELECT COUNT(*) FROM orders),2) AS pct_order
	FROM orders GROUP BY order_status ORDER BY pct_order DESC;

-- 13. Average Order Value
SELECT ROUND(AVG(order_total),2) AS avg_order_value 
	FROM orders where order_status IN ('Shipped','Delivered');

-- 14. Orders with more than one product
SELECT order_id,COUNT(product_id) AS item_count 
	FROM order_items GROUP BY order_id 
	HAVING COUNT(product_id)>1;

-- 15. Average number of items per order
SELECT ROUND(AVG(item_count),2) AS avg_items_per_order
	FROM ( 
		SELECT order_id,COUNT(product_id) AS item_count 
		FROM order_items GROUP BY order_id) itemcount;

-- 16. Number of products per category
SELECT ca.category_name, COUNT(pr.product_id) AS total_products
	FROM products pr JOIN categories ca ON pr.category_id=ca.category_id
	GROUP BY ca.category_name;

-- 17. Cheapest product per category
SELECT ca.category_name, pr.product_name, pr.price
FROM products pr JOIN categories ca ON ca.category_id = pr.category_id
WHERE pr.price = (
    SELECT MIN(pr2.price)
    FROM products pr2
    WHERE pr2.category_id = pr.category_id
);

-- 18. Product never ordered
SELECT pr.product_name 
	FROM products pr LEFT JOIN order_items oi ON pr.product_id=oi.product_id
	WHERE oi.order_id IS NULL;

-- 19. Check if duplicate payments per order
SELECT order_id,COUNT(*) AS payment_count 
	FROM payments GROUP BY order_id
	HAVING COUNT(*)>1;

-- 20. Payments by method
SELECT method,SUM(amount) AS total_payments FROM payments GROUP BY method;

-- 21. Most used payment method
SELECT method,COUNT(*) AS total_number 
	FROM payments GROUP BY method 
	ORDER BY total_number DESC LIMIT 1;

-- 22. Average payment method
SELECT ROUND(AVG(amount),2) AS avg_payment_amount FROM payments;

-- 23. Delivered orders without payment
SELECT o.order_id FROM orders o 
	LEFT JOIN payments pa ON o.order_id=pa.order_id
	WHERE o.order_status='Delivered' AND pa.order_id IS NULL;

-- 24. Total number of returns
SELECT COUNT(*) AS total_returns FROM returns;

-- 25. Reasons for returns
SELECT reason,COUNT(*) AS total_returns 
FROM returns GROUP BY reason ORDER BY total_returns DESC;

-- 26. Orders that were returned vs not returned
SELECT  CASE
	WHEN r.order_id IS NOT NULL THEN 'Returned'
	ELSE 'Not Returned'
	END AS return_status,
	COUNT(o.order_id) AS total_orders FROM orders o LEFT JOIN
	returns r ON o.order_id=r.order_id WHERE o.order_status='Delivered'
	GROUP BY return_status;

-- 27. Return Rate
SELECT ROUND(COUNT(r.order_id)*100.0/COUNT(o.order_id),2) AS return_rate_pct
	FROM orders o LEFT JOIN returns r On o.order_id=r.order_id 
	WHERE o.order_status='Delivered';