import faker
import json
import os
import random
import time
from confluent_kafka import Producer

# Get input parameters from environment
user_max_id = int(os.getenv('USER_MAX_ID', 999999))
eventhub_connection_string_pageviews = os.getenv('EVENTHUB_CONNECTION_STRING_PAGEVIEWS')
eventhub_connection_string_stars = os.getenv('EVENTHUB_CONNECTION_STRING_STARS')
eventhub_endpoint = f"{os.getenv('EVENTHUB_NAMESPACE')}.servicebus.windows.net:9093"

if not eventhub_connection_string_pageviews or not eventhub_connection_string_stars:
    print('Please provide Event Hub connection string via EVENTHUB_CONNECTION_STRING_PAGEVIEWS and EVENTHUB_CONNECTION_STRING_STARS environmental variable')
    exit(1)

# Initialize data generator
fake = faker.Faker(['cs_CZ'])

# Kafka configuration
conf_pageviews = {'bootstrap.servers': eventhub_endpoint,
         'security.protocol': 'SASL_SSL',
         'sasl.mechanisms': 'PLAIN',
         'sasl.username': "$ConnectionString",
         'sasl.password': eventhub_connection_string_pageviews,
         'client.id': 'client'}
conf_stars = {'bootstrap.servers': eventhub_endpoint,
         'security.protocol': 'SASL_SSL',
         'sasl.mechanisms': 'PLAIN',
         'sasl.username': "$ConnectionString",
         'sasl.password': eventhub_connection_string_stars,
         'client.id': 'client'}

producer_pageviews = Producer(conf_pageviews)
producer_stars = Producer(conf_stars)

# Run forever
while True:
    time.sleep(abs(random.gauss(10,5)))   # Wait for random time centered around 10s
    user_id = fake.pyint(min_value=0, max_value=user_max_id)    # Get new user id
    client_ip = fake.ipv4()   
    user_agent = fake.user_agent()
    for index in range(random.randint(1,30)):   # Generate random ammount of pageviews
        message = {}
        message['user_id'] = user_id
        message['http_method'] = fake.http_method()
        message['uri'] = fake.uri()

        if random.randint(1,100) != 100:
            message['client_ip'] = client_ip
        else:
            message['client_ip'] =  ""   # Make data missing from time to time

        message['user_agent'] = user_agent

        if random.randint(1,100) != 100:
            message['latency'] = abs(random.gauss(200, 50))
        else:
            message['latency'] =  random.randint(500,5000)   # Generate outlier from time to time

        message_json = json.dumps(message)
        print(message_json)
        producer_pageviews.produce('pageviews', message_json)
        producer_pageviews.flush()

    if random.randint(1,50) == 50:   # For some sessions users are giving stars on social media
        message = {}
        message['user_id'] = user_id
        message['stars'] = random.randint(1,5)
        message_json = json.dumps(message)
        print("USER STARS: " + message_json)
        producer_stars.produce('stars', message_json)
        producer_stars.flush()
