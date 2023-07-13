import faker
import json
import os
import pyodbc
import random
from datetime import datetime
import time

# Get input parameters from environment
sql_server = os.getenv('SQL_SERVER')
sql_user = os.getenv('SQL_USER')
sql_password = os.getenv('SQL_PASSWORD')
sql_database = os.getenv('SQL_DATABASE')
user_max_id = int(os.getenv('USER_MAX_ID', 999999))
product_max_id = int(os.getenv('PRODUCT_MAX_ID', 999999))
count = int(os.getenv('COUNT', 10000000))
sleep_time = 100 / int(os.getenv('RATE', 1))

if not sql_server or not sql_user or not sql_password or not sql_database:
    print('Please provide SQL access parameters SQL_SERVER, SQL_USER, SQL_PASSWORD, SQL_DATABASE')
    exit(1)

conn = pyodbc.connect('DRIVER={ODBC Driver 18 for SQL Server};SERVER='+sql_server+';DATABASE='+sql_database+';UID='+sql_user+';PWD='+sql_password)
cursor = conn.cursor()

print(f'Connected to {sql_server}')

# Drop table if exists
command = """
    IF OBJECT_ID(N'dbo.orders', N'U') IS NOT NULL  
        DROP TABLE [dbo].[orders];  
    IF OBJECT_ID(N'dbo.items', N'U') IS NOT NULL  
        DROP TABLE [dbo].[items];  
    """
cursor.execute(command)
conn.commit()

# Create tables
command = """
    CREATE TABLE orders (
        orderId int PRIMARY KEY,
        userId int,
        orderDate datetime,
        orderValue float
    );
    CREATE TABLE items (
        orderId int,
        rowId int,
        productId int,
        PRIMARY KEY (orderId, rowId)
    );
    """
cursor.execute(command)
conn.commit()

print("Tables created")

# Generate data
orderCommand = ""
itemCommand = ""
for index in range(count):
    orderId = index + 1
    userId = random.randint(1, user_max_id)
    dateEpoch = random.randint(1281707537, 1660398760)
    date = datetime.datetime.fromtimestamp(dateEpoch).strftime("%Y-%m-%d %H:%M:%S")
    value = random.randint(1, 100000)
    if orderCommand == "":
        orderCommand = f'INSERT INTO orders (orderId, userId, orderDate, orderValue) VALUES '
    else:
        orderCommand = orderCommand + f'({orderId}, {userId}, \'{date}\', {value}),'
    for items in range(random.randint(1, 10)):
        productId = random.randint(1, product_max_id)
        rowId = items + 1
        if itemCommand == "":
            itemCommand = f'INSERT INTO items (orderId, rowId, productId) VALUES '
        else:
            itemCommand = itemCommand + f'({orderId}, {rowId}, {productId}),'
    if index % 100 == 99:   # Every 100 orders send commands, commit and print info
        cursor.execute(orderCommand[:-1])
        orderCommand = ""
        cursor.execute(itemCommand[:-1])
        itemCommand = ""
        conn.commit()
        print(f'{datetime.now().strftime("%H:%M:%S")} Created {index+1} of {count} orders')
        time.sleep(sleep_time)