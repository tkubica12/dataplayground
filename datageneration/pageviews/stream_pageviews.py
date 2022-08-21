import faker
import json
import os
import random
import time
from confluent_kafka import Producer

# Get input parameters from environment
user_max_id = int(os.getenv('USER_MAX_ID', 999999))
eventhub_connection_string = os.getenv('EVENTHUB_CONNECTION_STRING')
eventhub_endpoint = f"{os.getenv('EVENTHUB_NAMESPACE')}.servicebus.windows.net:9093"

if not eventhub_connection_string:
    print('Please provide Event Hub connection string via EVENTHUB_CONNECTION_STRING environmental variable')
    exit(1)

# Initialize data generator
fake = faker.Faker(['cs_CZ'])

# Kafka configuration
conf = {'bootstrap.servers': eventhub_endpoint,
         'security.protocol': 'SASL_SSL',
         'sasl.mechanisms': 'PLAIN',
         'sasl.username': "$ConnectionString",
         'sasl.password': eventhub_connection_string,
         'client.id': 'client'}

producer = Producer(conf)

# Run forever
user_id_store = 0
while True:
    time.sleep(abs(random.gauss(1,0.5)))
    message = {}
    if random.randint(1,5) != 5:   # Most of the time generate new User ID
        user_id_store =  fake.pyint(min_value=0, max_value=user_max_id)   # Generate new User ID
    message['user_id'] = user_id_store
    message['http_method'] = fake.http_method()
    message['client_ip'] = fake.ipv4()

    if random.randint(1,100) != 100:
        message['client_ip'] = fake.ipv4()
    else:
        message['client_ip'] =  ""   # Make data missing from time to time

    message['user_agent'] = fake.user_agent()
    if random.randint(1,100) != 100:
        message['latency'] = abs(random.gauss(200, 50))
    else:
        message['latency'] =  random.randint(500,5000)   # Generate outlier from time to time

    message_json = json.dumps(message)
    print(message_json)
    producer.produce('pageviews', message_json)
    producer.flush()

