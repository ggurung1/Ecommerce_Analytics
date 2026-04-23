import mysql.connector

def load_to_mysql(dims, facts):

    conn = mysql.connector.connect(
        host="localhost",
        user="root",
        password="your_password",
        database="ecommerce_dw"
    )

    cursor = conn.cursor()

    def insert_df(table, df):
        cols = ",".join(df.columns)
        placeholders = ",".join(["%s"] * len(df.columns))
        query = f"INSERT INTO {table} ({cols}) VALUES ({placeholders})"

        for row in df.itertuples(index=False):
            cursor.execute(query, tuple(row))

    # Load Dimensions
    insert_df("dim_customer", dims["dim_customer"])
    insert_df("dim_category", dims["dim_category"])
    insert_df("dim_product", dims["dim_product"])
    insert_df("dim_date", dims["dim_date"])

    # Load Facts
    insert_df("fact_order", facts["fact_order"])
    insert_df("fact_order_item", facts["fact_order_item"])
    insert_df("fact_payment", facts["fact_payment"])
    insert_df("fact_return", facts["fact_return"])

    conn.commit()
    cursor.close()
    conn.close()

    print("Data loaded into MySQL successfully 🚀")