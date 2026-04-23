#!/bin/env python3

import pandas as pd

def build_dimensions(stg):
	dim_customer=stg["customers"]
	dim_category=stg["categories"]
	dim_product=stg["products"]
	dim_date=stg["date"]

	return {
        "dim_customer": dim_customer,
        "dim_category": dim_category,
        "dim_product": dim_product,
        "dim_date": dim_date
    }

def build_facts(stg):
    fact_order = stg["orders"]

    fact_order_item = stg["order_items"]
    fact_order_item["subtotal"] = (fact_order_item["quantity"] * 			
    					fact_order_item["unit_price"])

    fact_payment = stg["payments"]

    fact_return = stg["returns"]

    return {
        "fact_order": fact_order,
        "fact_order_item": fact_order_item,
        "fact_payment": fact_payment,
        "fact_return": fact_return
    }