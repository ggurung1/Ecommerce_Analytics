-- Basic SQL Queries: E-commerce Analytics

-- =====================
-- Revenue Analytics
-- =====================
 
-- Product sales value by Country
SELECT c.country, SUM(oi.quantity*pr.price) AS product_sale_value,
	SUM(o.order_total) AS gross_revenue
	FROM orders o JOIN order_items oi ON o.order_id=oi.order_id
	JOIN products pr ON oi.product_id=pr.product_id
	JOIN customers c ON c.customer_id=o.customer_id
	WHERE o.order_status='Delivered'
	GROUP BY c.country ORDER BY gross_revenue DESC;

-- Top 10 revenue generating products
SELECT pr.product_name,
	SUM(o.order_total) AS gross_revenue
	FROM products pr JOIN order_items oi ON oi.product_id=pr.product_id
	JOIN orders o ON o.order_id=oi.order_id
	WHERE o.order_status='Delivered'
	GROUP BY pr.product_name ORDER BY gross_revenue DESC LIMIT 10;


-- Revenue contributuion by category(%)
SELECT ca.category_name,
	ROUND(SUM(o.order_total)/(SELECT SUM(order_total) FROM orders WHERE order_status='Delivered')
			*100.0,2) AS category_pct
	FROM categories ca JOIN products pr ON ca.category_id=pr.category_id
	JOIN order_items oi ON oi.product_id=pr.product_id
	JOIN orders o ON o.order_id=oi.order_id
	WHERE o.order_status='Delivered'
	GROUP BY ca.category_name ORDER BY category_pct DESC;

-- Gross Revenue by payment method
SELECT pa.method,SUM(pa.amount) AS gross_revenue 
	FROM payments pa JOIN orders o ON pa.order_id=o.order_id
	WHERE o.order_status='Delivered'
	GROUP BY pa.method ORDER BY gross_revenue DESC;

-- Monthly Gross Revenue and Net Revenue
SELECT DATE_FORMAT(o.order_date,'%Y-%m') AS order_year_month,
	SUM(o.order_total) AS gross_revenue,
	SUM(o.order_total-IFNULL(r.refund_amount,0)) AS net_revenue
	FROM orders o LEFT JOIN returns r ON o.order_id=r.order_id
	WHERE o.order_status='Delivered' GROUP BY order_year_month
	ORDER BY order_year_month;

-- Average Revenue per Order
SELECT ROUND(AVG(order_total),2) AS avg_order_value 
	FROM orders WHERE order_status IN ('Delivered','Shipped');

-- Revenue growth % month over month
WITH monthly_revenue AS (
SELECT DATE_FORMAT(order_date,'%Y-%m') AS order_year_month,
	SUM(order_total) AS gross_revenue 
	FROM orders WHERE order_status='Delivered'
	GROUP BY order_year_month
)
SELECT order_year_month,gross_revenue,
	ROUND(AVG(gross_revenue) OVER(ORDER BY order_year_month
		ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),2
		) AS Rolling_avg_3_month_revenue,
	COALESCE(ROUND(
		(gross_revenue-LAG(gross_revenue) OVER (ORDER BY order_year_month))/
		LAG(gross_revenue) OVER (ORDER BY order_year_month)*100.0,2)) AS revenue_growth_pct
	FROM monthly_revenue ORDER BY order_year_month;

-- Refund impact on revenue(%)
WITH refund_per_order AS (
SELECT order_id,SUM(refund_amount) AS refund_amount
	FROM returns GROUP BY order_id)
SELECT SUM(o.order_total) AS gross_revenue,
	ROUND(COALESCE(SUM(rpo.refund_amount),0)/SUM(o.order_total)*100.0,2) AS refund_pct
	FROM orders o LEFT JOIN refund_per_order rpo ON o.order_id=rpo.order_id
	WHERE o.order_status='Delivered'


-- =====================
-- Customer Analytics
-- =====================

-- Top 5 customers by total spending
SELECT CONCAT(c.first_name,' ',c.last_name) AS customer_name,
	SUM(o.order_total) AS total_spending
    FROM customers c JOIN orders o ON c.customer_id=o.customer_id
    WHERE o.order_status IN ('Delivered','Shipped')
    GROUP BY customer_name ORDER BY total_spending DESC LIMIT 5;

 -- Average order per customer
SELECT ROUND(COUNT(DISTINCT order_id)/COUNT(DISTINCT customer_id),2) AS avg_orders_per_customer
	FROM orders WHERE order_status='Delivered' GROUP BY customer_id;

-- Customer Lifetime Value (CLV)
WITH refunds_per_order (
SELECT order_id,SUM(refund_amount) AS refund_amount
	FROM returns GROUP BY order_id
)
SELECT CONCAT(c.first_name,' ',c.last_name) AS customer_name,
	SUM(o.order_total-COALESE(rpo.refund_amount,0)) AS CLV
	FROM customers c JOIN orders o ON c.customer_id=o.order_id
	LEFT JOIN refund_per_order rpo ON rpo.order_id=o.order_id
	WHERE o.order_status='Delivered' 
	GROUP BY c.customer_id ORDER BY CLV DESC LIMIT 10;

--  Cohort CLV query
WITH first_order AS (
SELECT c.customer_id,MIN(o.order_date) AS first_order_date 
FROM customers c JOIN orders o ON c.customer_id=o.customer_id
WHERE o.order_status='Delivered' GROUP BY c.customer_id
),
customer_clv AS (
SELECT customer_id,SUM(order_total) AS clv 
FROM orders WHERE order_status='Delivered' GROUP BY customer_id)

SELECT DATE_FORMAT(first_order_date,'%Y-%m') AS cohort_month,
	COUNT(DISTINCT fo.customer_id) AS total_customer,
	ROUND(AVG(cc.clv),2) AS avg_clv
	FROM first_order fo JOIN customer_clv cc ON fo.customer_id=cc.customer_id
	GROUP BY cohort_month ORDER BY cohort_month

-- Repeat vs one-time
WITH customer_orders AS(
SELECT customer_id,COUNT(DISTINCT order_id) AS order_count
	FROM orders WHERE order_status='Delivered' GROUP BY customer_id
)

SELECT CASE
		WHEN order_count=1 THEN 'One-time'
		ELSE 'Repeat'
	END AS customer_type,
	COUNT(*) AS total_customer
	FROM customer_oders GROUP BY customer_type


-- Customers revenue by country
WITH country_revenue AS (
SELECT c.country, SUM(o.order_total) AS gross_revenue,
		COUNT(DISTINCT c.customer_id) AS customer_count
		FROM customers c JOIN orders o ON c.customer_id=o.customer_id
		WHERE o.order_status='Delivered' 
		GROUP BY c.country
)

SELECT country,gross_revenue, 
		ROUND(gross_revenue/SUM(gross_revenue) OVER()*100,2) AS country_revenue_pct,
		ROUND(gross_revenue/customer_count,2) AS avg_revenue_per_customer
		FROM country_revenue ORDER BY gross_revenue DESC;


-- Customer return rate
WITH customer_orders AS (
    SELECT
        o.customer_id,
        COUNT(DISTINCT o.order_id) AS total_orders,
        COUNT(DISTINCT r.order_id) AS returned_orders
    FROM orders o
    LEFT JOIN returns r 
        ON o.order_id = r.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY o.customer_id
)

SELECT
    customer_id,
    ROUND(returned_orders / total_orders, 2) AS return_rate
FROM customer_orders
ORDER BY return_rate DESC;


-- ===============================
-- Order & Fulfillment Analytics
-- ===============================

-- Average delivery time
SELECT ROUND(AVG(DATEDIFF(delivered_date,order_date)),2) AS avg_delivery_days 
	FROM orders WHERE order_status='Delivered';l

-- On-time vs late delivery rate
SELECT CASE 
		WHEN DATEDIFF(delivered_date,order_date) <=7 THEN 'On timme'
		ELSE 'Late' END AS delivery_status,
		COUNT(*) AS order_counts,
		ROUND(COUNT(*)/SUM(COUNT(*) OVER()*100,2) AS  pct_of_orders
		FROM orders WHERE o.order_status='Delivered' GROUP BY delivery_status;


-- Return rate by delivery time
WITH delivery_clasification AS (
SELECT order_id,
		CASE 
		WHEN DATEDIFF(delivered_date,order_date)<=7 THEN 'On time'
		ELSE 'Late' END AS delivery_status
		FROM orders WHERE order_status='Delivered'
)

SELECT dc.delivery_status,
		ROUND(COUNT(DISTINCT r.order_id)/COUNT(DISTINCT dc.order_id),2) AS return_rate
		FROM delivery_clasification dc LEFT JOIN returns r ON r.order_id=dc.order_id
		GROUP BY dc.delivery_status ORDER BY return_rate DESC;


-- Orders by status trend over time
SELECT DATE_FORMAT(o.order_date,'%Y-%m') AS order_year_month,
	o.order_status, COUNT(*) AS order_counts
	FROM orders o GROUP BY order_year_month,o.order_status
	ORDER BY order_year_month,o.order_status;


-- Delivery Status trend over time
WITH delivery_clasification AS (
SELECT order_id, DATE_FORMAT(order_date,'%Y-%m') AS order_year_month,
		CASE
		WHEN DATEDIFF(delivered_date,order_date)<=7 THEN 'On time'
		ELSE 'Late' END AS delivery_status
		FROM orders WHERE order_status='Delivered'
)
SELECT dc.order_year_month,delivery_status, 
		ROUND(COUNT(DISTINCT r.order_id)/COUNT(DISTINCT dc.order_id),2) AS return_rate
		FROM delivery_clasification dc LEFT JOIN returns r ON r.order_id=dc.order_id
		GROUP BY dc.order_year_month,dc.delivery_status ORDER BY dc.order_year_month;
-- Free shipping usage impact

SELECT CASE
		WHEN shipping_fee=0 THEN 'Free Shipping'
		ELSE 'Paid Shipping'
	END AS shipping_type,
	COUNT(*) AS orders,
	ROUND(AVG(order_total),2) AS avg_order_value,
	ROUND(COUNT(DISTINCT r.order_id)/COUNT(DISTINCT o.order_id),2) AS return_rate
	FROM orders o LEFT JOIN returns r ON r.order_id=o.order_id
	WHERE o.order_status='Delivered'
	GROUP BY shipping_type;
-- Cancelled order percentage
SELECT ROUND(
	SUM(CASE WHEN order_status='Cancelled' THEN 1 ELSE 0 END)/COUNT(*)*100
	,2) AS cancelled_order_pct
FROM orders;

-- ==============================
-- Product & Category Analytics
-- ==============================

-- Top 5 best-selling products by quantity (Completed orders)
SELECT pr.product_name, SUM(oi.quantity) AS total_quantity
    FROM products pr JOIN order_items oi ON pr.product_id=oi.product_id
    JOIN orders o ON o.order_id=oi.order_id
    WHERE o.order_status IN ('Delivered','Shipped')
    GROUP BY pr.product_name ORDER BY total_quantity DESC LIMIT 5;


-- Best selling Categories by revenue
SELECT ca.category_name,SUM(oi.quantity*pr.price) AS gross_revenue
	FROM categories ca JOIN products pr ON ca.category_id=pr.category_id
	JOIN order_items oi ON oi.product_id=pr.product_id 
	JOIN orders o ON o.order_id=oi.order_id
	WHERE o.order_status IN ('Delivered','Shipped')
	GROUP BY ca.category_name ORDER BY gross_revenue DESC;

-- Category-wise return rate
SELECT ca.category_name, 
	ROUND(COUNT(DISTINCT r.order_id)/COUNT(DISTINCT o.order_id),2) AS return_rate
	FROM categories ca JOIN products pr ON ca.category_id=pr.category_id
	JOIN order_items oi ON oi.product_id=pr.product_id 
	JOIN orders o ON o.order_id=oi.order_id
	WHERE o.order_status='Delivered'
	GROUP BY ca.category_name ORDER BY return_rate DESC;


-- Low-selling but high-refund products
WITH product_metrics AS (
	SELECT pr.product_id,pr.product_name,
		SUM(oi.quantity) AS units_sold,
		COUNT(DISTINCT r.order_id) AS returned_orders
		FROM products pr JOIN order_items oi ON pr.product_id=oi.product_id
		JOIN orders o ON o.order_id=oi.order_id
		LEFT JOIN returns r ON r.order_id=o.order_id
		WHERE o.order_status='Delivered'
		GROUP BY pr.product_id,pr.product_name
	)

SELECT * FROM product_metrics WHERE units_sold <50 AND returned_orders>5 
	ORDER BY returned_orders DESC;


-- Products with zero returns
SELECT pr.product_id,pr.product_name,
		SUM(oi.quantity) AS units_sold
		FROM products pr JOIN order_items oi ON pr.product_id=oi.product_id
		JOIN orders o ON o.order_id=oi.order_id
		LEFT JOIN returns r ON r.order_id=o.order_id
		WHERE o.order_status='Delivered'
		GROUP BY pr.product_id,pr.product_name
		HAVING COUNT(r.order_id)=0
		ORDER BY units_sold DESc;


-- Revenue vs quantity comparison
SELECT
    pr.product_name,
    SUM(oi.quantity) AS units_sold,
    SUM(oi.quantity * pr.price) AS revenue
	FROM products pr JOIN order_items oi ON pr.product_id = oi.product_id
	JOIN orders o ON o.order_id = oi.order_id
	WHERE o.order_status = 'Delivered'
	GROUP BY pr.product_name
	ORDER BY revenue DESC;


-- Price vs return correlation
SELECT pr.price,
    ROUND(COUNT(DISTINCT r.order_id) / COUNT(DISTINCT o.order_id),
     2) AS return_rate
	FROM products pr JOIN order_items oi ON pr.product_id = oi.product_id
	JOIN orders o ON o.order_id = oi.order_id
	LEFT JOIN returns r ON r.order_id = o.order_id
	WHERE o.order_status = 'Delivered'
	GROUP BY pr.price ORDER BY pr.price;

-- 💡 Example prompt:
-- “Which category has the highest refund impact?”

SELECT
    ca.category_name,
    ROUND(SUM(r.refund_amount), 2) AS total_refunds,
    ROUND(SUM(o.order_total), 2) AS revenue,
    ROUND(
        SUM(r.refund_amount) / SUM(o.order_total) * 100,
        2
    ) AS refund_impact_pct
FROM categories ca
JOIN products pr ON ca.category_id = pr.category_id
JOIN order_items oi ON oi.product_id = pr.product_id
JOIN orders o ON o.order_id = oi.order_id
JOIN returns r ON r.order_id = o.order_id
WHERE o.order_status = 'Delivered'
GROUP BY ca.category_name
ORDER BY refund_impact_pct DESC;


-- ============================
-- Payment & Refund Analytics
-- ============================

-- Refund rate by payment method
SELECT
    pa.method,
    ROUND(
        COUNT(DISTINCT r.order_id) / COUNT(DISTINCT o.order_id),
        2
    ) AS refund_rate
FROM orders o JOIN payments pa ON o.order_id=pa.order_id
LEFT JOIN returns r ON r.order_id = o.order_id
WHERE o.order_status = 'Delivered'
GROUP BY pa.method;

-- Average refund amount
SELECT
    ROUND(AVG(refund_amount), 2) AS avg_refund_amount
FROM returns;


-- Payment method revenue share
SELECT
    pa.method,
    ROUND(
        SUM(o.order_total) / SUM(SUM(o.order_total)) OVER () * 100,
        2
    ) AS revenue_share_pct
FROM orders o JOIN payments pa ON o.order_id=pa.order_id
WHERE o.order_status = 'Delivered'
GROUP BY pa.method;

-- Orders without payment (data quality)
SELECT COUNT(*) AS orders_without_payment
FROM orders o LEFT JOIN payments pa ON o.order_id=pa.order_id
WHERE pa.method IS NULL
   OR o.order_total = 0;

-- Refund lag (days between delivery & return)
SELECT
    ROUND(AVG(DATEDIFF(r.return_date, o.delivered_date)), 2) AS avg_refund_lag_days
FROM returns r
JOIN orders o ON r.order_id = o.order_id
WHERE o.order_status = 'Delivered';

-- Products with zero returns
SELECT pr.product_id,pr.product_name,
		SUM(oi.quantity) AS units_sold
		FROM products pr JOIN order_items oi ON pr.product_id=oi.product_id
		JOIN orders o ON o.order_id=oi.order_id
		LEFT JOIN returns r ON r.order_id=o.order_id
		WHERE o.order_status='Delivered'
		GROUP BY pr.product_id,pr.product_name
		HAVING COUNT(r.order_id)=0
		ORDER BY units_sold DESC;

