import faker
import json
import os
import time
from azure.storage.filedatalake import DataLakeFileClient, DataLakeServiceClient

# Get input parameters from environment
storageSas = os.getenv('STORAGE_SAS')
count = int(os.getenv('COUNT', 100))
sleep_time = 1 / int(os.getenv('RATE', 1))

if not storageSas:
    print('Please provide storage connection string via PRODUCTS_SAS environmental variable')
    exit(1)

# Initialize data generator
fake = faker.Faker(['cs_CZ'])

# Generate and write product files
for index in range(count):
    filename = f'product_{index}.json'
    file = DataLakeFileClient(account_url=storageSas,file_system_name='products', file_path=filename)
    file.create_file()
    entry = {}
    entry['id'] = index
    entry['name'] = f'product_{index}'
    entry['description'] = fake.paragraph(nb_sentences=1, variable_nb_sentences=False)
    pages = []
    pages.append(fake.url())
    pages.append(fake.url())
    pages.append(fake.url())
    entry['pages'] = pages
    data = json.dumps(entry)
    file.append_data(data=data, offset=0, length=len(data))
    file.flush_data(len(data))
    print(f'Record {index} of {count}')
    time.sleep(sleep_time)
