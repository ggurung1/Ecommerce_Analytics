#!/bin/env python3
""" Generates realistic e-commerce data for portfolio project """

import random 
import pandas as pd
from faker import Faker
from datetime import datetime,timedelta
import sys

#------------------CONFIG------------------
NUM_CUSTOMERS=50 #int(input('ENTER THE NUMBER OF CUSTOMERS:'))
NUM_ORDERS=100 #int(input(f'ENTER TOTAL NUMBER OF ORDERS:(> than number of customers {NUM_CUSTOMERS})'))
RETURN_RATE=0.15 # 15% of delivered orders

#-----------------------
SEED=1234
random.seed(SEED)
fake=Faker()
fake.seed_instance(SEED)

print(f"Generating {NUM_CUSTOMERS} customers and {NUM_ORDERS} orders...")

EMAIL_DOMAINS=["gmail.com","yahoo.com","hotmail.com"]
ORDER_STATUSES=["Pending","Shipped","Delivered","Cancelled"]
PAYMENT_METHODS=["Credit Card","PayPal","Bank Transfer","Apple Pay"]
COUNTRIES=['UK','USA','China','Germany','France','Japan','Australia','Canada']
RETURN_REASONS=["Damaged","Wrong Item","No Longer Needed","Size Issue"]

#--------------Date range for orders-------------
START_DATE=datetime(2020,1,1)
END_DATE=datetime(2025,12,31)


#---------Using product catalog with category Id,[product_1, min price,max price]--------
categories = {
    "Electronics":(1,["Phone",600,1500],["Laptop",800,3000],["Tablet",300,1200], 
    				["Headphones",50,1000], ["Smartwatch",80,500],["Monitor",100,900],
                    ["Camera",400,1800], ["Speaker",20,600]),
    "Clothing":(2,["T-Shirt",10,100],["Jeans",50,120],["Jacket",25,1200],
    			["Dress",60,500],["Shoes",40,800], ["Sweater",25,500], 
                ["Hoodie",20,300]),
    "Books":(3,["Anime",15,200],["Novel",15,300],["Poem",10,100], 
    		["Story",10,100], ["Series",50,500], ["Essay",10,100]),
    "Furniture":(4,["Sofa",40,1500],["Chair",30,400],["Table",40,600], 
    			["Desk",50,800],["Bed",80,1000],["Wardrobe",80,1000], 
                ["Bookshelf",10,300],["Couch",100,1200]),
    "Sports":(5,["Football",30,100],["Tennis Racket",20,400],["Basketball",30,200],
    			["Yoga Mat",10,100],["Bicycle",80,1000], ["Helmet",30,200]),
    "Toys":(6,["Legos",10,300],[ "Puzzle",10,80], ["Doll",10,200], 
    	["Vehiclemodel",10,300])
}



def random_date(start,end):
	""" Generate random date between start and end"""
	delta=end-start
	return start+timedelta(days=random.randint(0,delta.days))

def sql_date(value):
    return f"'{value}'" if value else "NULL"

#----------------Generate customers---------------
customers=[]
emails = set()  # track unique emails
customer_id=0
while len(customers) < NUM_CUSTOMERS:
	first = fake.first_name()
	last = fake.last_name()
	email = f"{first.lower()}.{last.lower()}{random.randint(0,99)}@{random.choice(EMAIL_DOMAINS)}"

	# Ensure uniqueness
	if email not in emails:
		customer_id+=1
		emails.add(email)
		country = random.choice(COUNTRIES)
		customers.append((customer_id,first, last, email, country))

df_customers=pd.DataFrame(customers,columns=["customer_id","first_name","last_name","email","country"])



#============Generate products===============

category_names=list(categories.keys())
category_list=[];products=[]
product_id=1
for category, items in categories.items():
    category_id=items[0]
    category_list.append((category_id,category))
    for item in items[1:]:
        name=item[0]
        price=round(random.uniform(item[1],item[2]),2)
        products.append((product_id,name,price,category_id))
        product_id+=1

df_categories=pd.DataFrame(category_list,columns=["category_id","category_name"])
df_products=pd.DataFrame(products,columns=["product_id","product_name","price","category_id"])

#------------------Generate Orders, Items, Payments, Returns---------------------
orders,order_items,payments,returns=[],[],[],[]
order_id=order_item_id=payment_id=return_id=1

for _ in range(NUM_ORDERS):
	cust_id=random.randint(1,NUM_CUSTOMERS)
	order_status=random.choices(ORDER_STATUSES,weights=[0.25,0.35,0.30,0.10])[0]
	order_date=random_date(START_DATE,END_DATE)

	
	# Considering max of 5 items per order
	num_items=random.randint(1,5)
	subtotal=0
	items_for_return=[]
	
	for _ in range(num_items):
		product=random.choice(products)
		product_id=product[0]
		price=product[2]
		category_id=product[3]

		# Quantity depends on category
		if category_id==1: # Electronics
			qty=random.randint(1,3)
		elif category_id in [2,3]: # Clothing, Books
			qty=random.randint(1,10)
		else: #Furniture,Sports,Toys
			qty=random.randint(1,5)

		subtotal +=price*qty

		order_items.append((order_item_id,order_id,product_id,qty,price))
		items_for_return.append((product_id,qty,price))

		order_item_id+=1

	if subtotal>=80:
		shipping=0
	else:
		shipping=random.choice([5.0,8.0,10.0,15.0])
	

	#discount up to 15%
	discount_rate=random.choice([0.0,0.05,0.10,0.15]) 
	discount=round(subtotal*discount_rate,2)
	discounted_subtotal=subtotal-discount

	#tax fix to 8%, can be improved depending on country
	tax=round(discounted_subtotal*0.08,2) 

	total=round(discounted_subtotal+tax+shipping,2)

	shipped_date=None
	delivered_date=None
	# Payments only for shipped/Delivered orders
	if order_status in ["Shipped","Delivered"]:
		payment_date=order_date+timedelta(days=random.randint(0,2))
		shipped_date=payment_date
		method=random.choice(PAYMENT_METHODS)
		payments.append((payment_id,order_id,total,method,payment_date.date()))
		payment_id+=1

	if order_status=="Delivered":
		delivery_time=random.randint(1,15)
		delivered_date=shipped_date+timedelta(days=delivery_time)

	# RETURNS (only delivered)
	if order_status=="Delivered" and random.random()<RETURN_RATE:	 
		product_id_r,qty_r,price_r=random.choice(items_for_return)
		qty_returned=random.randint(1,qty_r)

		item_value=price_r*qty_returned
		item_ratio=item_value/subtotal

		refund_item_value=item_value-discount*item_ratio
		refund_tax=tax*item_ratio
		refund_shipping=0.0

		refund=round(refund_item_value+refund_tax+refund_shipping,2)
		#--- return allowed within 30 days of payment_date-----
		return_date=delivered_date+timedelta(days=random.randint(2,30))
		if delivery_time>=10:
			reason='Late Delivery'
		else:
			reason=random.choice(RETURN_REASONS)
		returns.append((return_id,order_id,product_id_r,return_date.date(),refund,
				reason))
		return_id+=1

	orders.append((order_id,cust_id,order_date.date(),order_status,shipped_date,delivered_date,tax,shipping,discount,total))
	order_id+=1

df_orders=pd.DataFrame(orders,columns=["order_id","customer_id","order_date","order_status",
									"shipped_date","delivered_date","discount","tax","shipping","order_total"])

df_order_items=pd.DataFrame(order_items,columns=["order_item_id","order_id","product_id","quantity","unit_price"])
df_payments=pd.DataFrame(order_items,columns=["payment_id","order_id","amount","method","payment_date"])
df_returns=pd.DataFrame(returns,columns=["return_id","order_id","product_id","return_date","refund_amount","reason"])

# Create dim date

dates=pd.date_range(start=START_DATE,end=END_DATE)

df_date=pd.DataFrame({"date_id":range(1,len(dates)+1),
					"date":dates,
					"day":dates.day,
					"month":dates.month,
					"year":dates.year,
					"quarter":dates.quarter,
					"weekday":dates.weekday
					})


def get_data():
	return {
        "customers": df_customers,
        "categories": df_categories,
        "products": df_products,
        "orders": df_orders,
        "order_items": df_order_items,
        "payments": df_payments,
        "returns": df_returns,
        "date": df_date
    }