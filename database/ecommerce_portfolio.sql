-- Database: ecommerce_db
DROP DATABASE IF EXISTS ecommerce_db;
-- CREATE DATABASE IF NOT EXISTS ecommerce_db;

CREATE DATABASE ecommerce_db;
USE ecommerce_db;

-- Customers Table
DROP TABLE IF EXISTS customers;
CREATE TABLE customers ( 
	customer_id INT AUTO_INCREMENT PRIMARY KEY,
	first_name VARCHAR(50) NOT NULL,
	last_name VARCHAR(50) NOT NULL,
	email VARCHAR(100) UNIQUE NOT NULL,
	country VARCHAR(50) NOT NULL
);

-- Categories table
DROP TABLE IF EXISTS categories;
CREATE TABLE categories (
	category_id INT PRIMARY KEY,
	category_name VARCHAR(50) NOT NULL UNIQUE
);

-- Products table
DROP TABLE IF EXISTS products;
CREATE TABLE products (
	product_id INT AUTO_INCREMENT PRIMARY KEY,
	product_name VARCHAR(100) NOT NULL,
	price DECIMAL(10,2) NOT NULL,
	category_id INT NOT NULL,
	FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

-- Orders table
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
	order_id INT AUTO_INCREMENT PRIMARY KEY,
	customer_id INT NOT NULL,
	order_date DATE NOT NULL,
	order_status ENUM('Pending','Shipped','Delivered','Cancelled') DEFAULT 'Pending',
	shipped_date DATE NULL,
	delivered_date DATE NULL,
	tax_amount DECIMAL(10,2) NOT NULL,
	shipping_fee DECIMAL(10,2) NOT NULL,
	discount_amount DECIMAL(10,2) NOT NULL,
	order_total DECIMAL(10,2) NOT NULL,	
	FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Order Items table
DROP TABLE IF EXISTS order_items;
CREATE TABLE order_items (
	order_item_id INT AUTO_INCREMENT PRIMARY KEY,
	order_id INT NOT NULL,
	product_id INT NOT NULL,
	quantity INT NOT NULL,
	FOREIGN KEY (order_id) REFERENCES orders(order_id),
	FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Payments table
DROP TABLE IF EXISTS payments;
CREATE TABLE payments (
	payment_id INT AUTO_INCREMENT PRIMARY KEY,
	order_id INT NOT NULL,
	amount DECIMAL(10,2) NOT NULL,
	method ENUM('Credit Card','PayPal','Bank Transfer','Apple Pay') NOT NULL,
	payment_date DATE NOT NULL,
	FOREIGN KEY (order_id) REFERENCES orders(order_id)
);


-- RETURNS TABLE
CREATE TABLE returns (
	return_id INT AUTO_INCREMENT PRIMARY KEY,
	order_id INT NOT NULL,
	product_id INT NOT NULL,
	return_date DATE NOT NULL,
	refund_amount DECIMAL(10,2) NOT NULL,
	reason VARCHAR(100) NOT NULL,
	FOREIGN KEY (order_id) REFERENCES orders(order_id),
	FOREIGN KEY (product_id) REFERENCES products(product_id)
);


-- ===================================
-- INDEXES FOR ANALYTICAL PERFORMANCE
-- ===================================

-- Customers
CREATE INDEX idx_customers_country ON customers(country);

-- Orders
CREATE INDEX idx_orders_customer ON orders(customer_id);

CREATE INDEX idx_orders_date ON orders(order_date);

CREATE INDEX idx_orders_status ON orders(order_status);

-- Following composite index useful for customer lifetime value, customer cohort analysis, retention over time
CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date);

-- Order Items
CREATE INDEX idx_order_items_order ON order_items(order_id);

CREATE INDEX idx_order_items_product ON order_items(product_id);

-- Useful for order-level product breakdowns
CREATE INDEX idx_order_items_order_product ON order_items(order_id, product_id);

-- Products
CREATE INDEX idx_products_category ON products(category_id);

-- Payments
CREATE INDEX idx_payments_order ON payments(order_id);

CREATE INDEX idx_payments_date ON payments(payment_date);

-- Returns
CREATE INDEX idx_returns_order ON returns(order_id);

CREATE INDEX idx_returns_product ON returns(product_id);

CREATE INDEX idx_returns_date ON returns(return_date);



-- Insert Sample Data
-- ===================================================================
-- NOTE:
-- 1. Run this schema file first
-- 2. Then Import ecommerce_data.sql
-- ===================================================================

