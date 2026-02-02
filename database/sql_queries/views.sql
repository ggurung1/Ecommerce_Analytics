-- Create Views: E-commerce Analytics

CREATE OR REPLACE VIEW vs_sales_fact AS
SELECT o.order_id,o.order_date,o.customer_id,
	c.country,oi.product_id,pr.product_name,
	ca.category_id,oi.quantity,pr.price,
	(oi.quantity*pr.price) AS revenue,
	o.tax_amount,o.shipping_fee,o.discount_amount,
	o.order_total,o.delivered_date
	FROM orders o JOIN customers c ON c.customer_id=o.customer_id
	JOIN order_items oi ON o.order_id=oi.order_id
	JOIN products pr ON oi.product_id=pr.product_id
	JOIN categories ca ON pr.category_id=ca.category_id
	WHERE o.order_status='Delivered';

CREATE OR REPLACE VIEW vw_customer_orders AS
SELECT c.customer_id, CONCAT(c.first_name,' ',c.last_name) AS customer_name,
	c.country,
	COUNT(DISTINCT o.order_id) AS total_orders,
	SUM(o.order_total) AS total_spent
	FROM customers c JOIN orders o ON c.customer_id=o.customer_id
	WHERE o.order_status='Delivered'
	GROUP BY c.customer_id,customer_name,c.country;

CREATE OR REPLACE VIEW vw_returns_summary AS
SELECT order_id,
	COUNT(*) AS return_count,
	SUM(refund_amount) AS total_refund_amount,
	MIN(return_date) AS first_return_date
	FROM returns GROUP BY order_id;

CREATE OR REPLACE VIEW vw_delivery_performance AS
SELECT order_id,order_date,shipped_date,delivered_date,
	CASE
		WHEN delivered_date IS NULL THEN 'Not Delivered'
		WHEN DATEDIFF(delivered_date,order_date)<=7 THEN ' On Time'
		ELSE 'Late'
	END AS delivery_status
	FROM orders WHERE order_status='Delivered';

CREATE OR REPLACE VIEW vw_monthly_revenue AS
SELECT DATE_FORMAT(order_date, '%Y-%m') AS order_year_month,
	SUM(order_total) AS gross_revenue
	FROM orders WHERE order_status='Delivered'
	GROUP BY order_year_month;
