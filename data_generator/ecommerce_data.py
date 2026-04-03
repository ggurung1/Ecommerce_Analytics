#!/bin/env python3
""" Generates realistic e-commerce data for portfolio project """

import random 
from faker import Faker
from datetime import datetime,timedelta
import sys

#!/bin/env python3
""" Generates realistic e-commerce data for portfolio project """

import pandas as pd
import random 
from faker import Faker
from datetime import datetime,timedelta
import sys


#------------------CONFIG------------------
NUM_CUSTOMERS=5000 #int(input('ENTER THE NUMBER OF CUSTOMERS:'))
NUM_ORDERS=10000 #int(input(f'ENTER TOTAL NUMBER OF ORDERS:(> than number of customers {NUM_CUSTOMERS})'))
RETURN_RATE=0.15 # 15% of delivered orders
PENDING_TO_SHIPPED_RATE=0.75 # 75% of pending orders get shipped
SHIPPED_TO_DELIVERED_RATE=0.85 # 85 % of shipped orders get delivered

print(f"Generating {NUM_CUSTOMERS} customers and {NUM_ORDERS} orders...")

EMAIL_DOMAINS=["gmail.com","yahoo.com","hotmail.com"]
ORDER_STATUSES=["Pending","Shipped","Delivered","Cancelled"]
PAYMENT_METHODS=["Credit Card","PayPal","Bank Transfer","Apple Pay"]
COUNTRIES=['UK','USA','China','Germany','France','Japan','Australia','Canada']
RETURN_REASONS=["Damaged","Wrong Item","No Longer Needed","Size Issue"]

#--------------Date range for orders-------------
START_DATE=datetime(2020,1,1)
END_DATE=datetime.today()


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


#-----------------------
SEED=1234
random.seed(SEED)
fake=Faker()
fake.seed_instance(SEED)


def random_date(start,end):
	""" Generate random date between start and end"""
	delta=end-start
	return start+timedelta(days=random.randint(0,delta.days))

#----------------Generate customers---------------
customers=[]
emails = set()  # track unique emails
customer_id=1

while len(customers) < NUM_CUSTOMERS:
    first = fake.first_name()
    last = fake.last_name()
    email = f"{first.lower()}.{last.lower()}{random.randint(0,99)}@{random.choice(EMAIL_DOMAINS)}"
    
    # Ensure uniqueness
    if email not in emails:
        emails.add(email)
        country = random.choice(COUNTRIES)
        customers.append([customer_id,first, last,email,country])
        customer_id+=1

#============Generate products===============
category_names=list(categories.keys())
products=[]
product_id=1
for category, items in categories.items():
    category_id=items[0]
    for item in items[1:]:
        name=item[0]
        price=round(random.uniform(item[1],item[2]),2)
        products.append([product_id,name,price,category_id])
        product_id+=1


#------------------Generate Orders, Items, Payments, Returns---------------------
orders,order_items,payments,returns=[],[],[],[]
order_id=1
order_item_id=1
payment_id=1
return_id=1

for _ in range(NUM_ORDERS):
    cust_id=random.randint(1,NUM_CUSTOMERS)
    initial_order_status=random.choices(ORDER_STATUSES,weights=[0.28,0.35,0.27,0.10])[0]
    order_date=random_date(START_DATE,END_DATE)
    
    # Considering max of 5 items per order
    num_items=random.randint(1,5)
    subtotal=0
    items_for_return=[]
    for _ in range(num_items):
        product=random.choice(products)
        product_id=product[0]
        price=product[2]
        category_id=product[-1]

        if category_id==1:
            qty=random.randint(1,3)
        elif category_id in [2,3]:
            qty=random.randint(1,10)
        else:
            qty=random.randint(1,5)

        subtotal+=price*qty

        order_items.append([order_item_id,order_id,product_id,qty])
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
    final_order_status=initial_order_status
    
    if initial_order_status=="Pending":
        if random.random()<PENDING_TO_SHIPPED_RATE:
            final_order_status="Shipped"
            shipped_date=order_date+timedelta(days=random.randint(1,7))
        else:
            final_order_status="Pending" # remains pending
            
    if initial_order_status in ["Shipped","Delivered"] or final_order_status=="Shipped":
        if random.random()<SHIPPED_TO_DELIVERED_RATE or initial_order_status=="Delivered":
            final_order_status="Delivered"
            if shipped_date is None:
                shipped_date=order_date+timedelta(days=random.randint(0,5))
            delivered_date=shipped_date+timedelta(days=random.randint(2,12))
            
    days_since_order=(END_DATE-order_date).days
    
    #Max pending days be 25
    if final_order_status=="Pending" and days_since_order>25: 
        if random.random()<0.65: 
            shipped_date=order_date+timedelta(days=random.randint(5,15))
            delivered_date=shipped_date+timedelta(days=random.randint(3,12))
            final_order_status="Delivered"
        else:
            final_order_status="Cancelled"
    elif final_order_status=="Shipped" and days_since_order>45:
        if random.random()<0.8:
            if shipped_date is None:
                shipped_date = order_date + timedelta(days=random.randint(6, 10))
            delivered_date=shipped_date+timedelta(days=random.randint(5,25))
            final_order_status="Delivered"
        else:
            final_order_status="Cancelled"
            
    # Payments only for shipped/Delivered orders
    if final_order_status in ["Shipped","Delivered"]:
        payment_date=order_date+timedelta(days=random.randint(0,2))
        method=random.choice(PAYMENT_METHODS)
        payments.append([payment_id,order_id,total,method,payment_date.date()])
        payment_id+=1


	# RETURNS (only delivered)
    if final_order_status=="Delivered" and random.random()<RETURN_RATE:	 
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
        if (delivered_date-shipped_date).days>=10:
            reason='Late Delivery'
        else:
            reason=random.choice(RETURN_REASONS)
        returns.append([return_id,order_id,product_id_r,return_date.date(),refund,reason])
        return_id+=1
    
    orders.append([order_id,cust_id,order_date.date(),final_order_status,shipped_date,delivered_date,total])
    order_id+=1


#-- Shipped date and Delivered date are None so fix this for SQL
def sql_date(value):
    return f"'{value}'" if value else "NULL"


#-------- Write SQL file-----
with open("ecommerce_data.sql","w") as f:
	f.write(f"-- Generated e-commerce data with {NUM_CUSTOMERS} customers and {NUM_ORDERS} orders\n\n")

	#customers
	f.write("INSERT INTO customers (first_name,last_name,email,country) VALUES\n")
	f.write(",\n".join([f"('{c[0]}','{c[1]}','{c[2]}','{c[3]}')" for c in customers]))
	f.write(";\n\n")

	#categories
	f.write("INSERT INTO categories (category_id,category_name) VALUES\n")
	f.write(",\n".join([f"({cat_values[0]},'{cat_keys}')" for cat_keys,cat_values in categories.items()]))
	f.write(";\n\n")

	#products
	f.write("INSERT INTO products (product_name,price,category_id) VALUES\n")
	f.write(",\n".join([f"('{p[1]}',{p[2]},{p[3]})" for p in products]))
	f.write(";\n\n")

	#Orders
	f.write("INSERT INTO orders (customer_id,order_date,order_status,shipped_date,delivered_date,order_total) VALUES\n")
	f.write(",\n".join([f"({o[1]},'{o[2]}','{o[3]}',{sql_date(o[4])},{sql_date(o[5])},{o[6]})" for o in orders]))
	f.write(";\n\n")

	#order Items
	f.write("INSERT INTO order_items (order_id,product_id,quantity) VALUES\n")
	f.write(",\n".join([f"({oi[1]},{oi[2]},{oi[3]})" for oi in order_items]))
	f.write(";\n\n")


	#payments
	f.write("INSERT INTO payments (order_id,amount,method,payment_date) VALUES\n")
	f.write(",\n".join([f"({p[1]},{p[2]},'{p[3]}','{p[4]}')" for p in payments]))
	f.write(";\n\n")

	#returns
	f.write("INSERT INTO returns (order_id,product_id,return_date,refund_amount,reason) VALUES \n")
	f.write(",\n".join([f"({r[1]},{r[2]},'{r[3]}',{r[4]},'{r[5]}')" for r in returns]))
	f.write(";\n\n")


print("Ecommerce data generated successfully!")
