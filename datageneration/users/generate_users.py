import faker
import json
import os
from azure.storage.filedatalake import DataLakeFileClient, DataLakeServiceClient

# Get input parameters from environment
storageSas = os.getenv('USERS_SAS')
count = int(os.getenv('USERS_COUNT', 10000))

if not storageSas:
    print('Please provide storage connection string via USERS_SAS environmental variable')
    exit(1)

# Create Azure Data Lake Storage file handler
file = DataLakeFileClient(account_url=storageSas,file_system_name='users', file_path='users.json')
file.create_file()

# Initialize data generator
fake = faker.Faker(['cs_CZ'])

# Generate and write records
offset = 0
data = ""
length = 0
for index in range(count):  # Generate records
    entry = {}
    entry['id'] = index
    entry['name'] = fake.name()
    entry['city'] = fake.city()
    entry['street_address'] = fake.street_address()
    entry['phone_number'] = fake.phone_number()
    entry['birth_number'] = fake.birth_number()
    entry['user_name'] = fake.user_name()
    entry['administrative_unit'] = fake.administrative_unit()
    entry['description'] = fake.paragraph(nb_sentences=5, variable_nb_sentences=True)
    jobs = []
    jobs.append(fake.job())
    jobs.append(fake.job())
    jobs.append(fake.job())
    entry['jobs'] = jobs
    data = data + json.dumps(entry)+"\n"
    length = length + len(json.dumps(entry))+1
    if index % 1000 == 0:   # Every 1000 records, write to block
        file.append_data(data=data, offset=offset, length=length)
        offset = offset + length
        data = ""
        length = 0
        print(f'Record {index+1} of {count}')

# Finish
print(f'Record {index+1} of {count}')
file.append_data(data=data, offset=offset, length=length)   # Write remaining records
file.flush_data(offset+length)    # Commit all blocks