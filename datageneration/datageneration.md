# Generating data
As part of demo I am going to generate different types of data:
- Users is JSON lines flat file with user details and contains one array attribute (list of jobs) pushed to Data Lake
- Products are many JSON files, one for each product pushed to Data Lake
- Page views are referencing user ID and streamed one record per second to Event Hub

# Deployment
Everything is automated as part of data perparation Terraform module. Each generator/streamer runs as Azure Container Instance.

# Dev
For code changes or running generators locally here are few notes and commands.

```bash
# Install Anaconda
curl https://repo.anaconda.com/archive/Anaconda3-2022.05-Linux-x86_64.sh -o anaconda.sh
bash anaconda.sh

# Create environment
conda env create -f environment.yaml

# Active environment
conda activate users

# Get SAS token
export STORAGE_ACCOUNT_NAME="mystorageaccount"
export CONTAINER_NAME=bronze
export CONTAINER_SAS=$(az storage container generate-sas -n $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --expiry 2037-12-31T23:59:59Z --permissions rwl --https-only -o tsv)
export STORAGE_SAS=https://$STORAGE_ACCOUNT_NAME.dfs.core.windows.net/${CONTAINER_NAME}?${CONTAINER_SAS}

# Generate users
export COUNT=1000
python generate_users.py

# Generate products
export COUNT=100
python generate_products.py

# Stream pageviews
export EVENTHUB_NAMESPACE="myeventhubnamespace"
export EVENTHUB_CONNECTION_STRING=$(az eventhubs eventhub authorization-rule keys list -g datademo --namespace-name $EVENTHUB_NAMESPACE --eventhub-name pageviews -n pageviewsSender --query primaryConnectionString -o tsv)
python stream_pageviews.py

# Build image
docker login -u tkubica12 ghcr.io
docker build -t ghcr.io/tkubica12/generate_users:latest .
docker build -t ghcr.io/tkubica12/generate_products:latest .
docker build -t ghcr.io/tkubica12/stream_pageviews:latest .
docker push ghcr.io/tkubica12/generate_users:latest
docker push ghcr.io/tkubica12/generate_products:latest
docker push ghcr.io/tkubica12/stream_pageviews:latest

# Running containers locally
docker run --rm -e STORAGE_SAS=$STORAGE_SAS -e COUNT=100 ghcr.io/tkubica12/generate_users:latest
docker run --rm -e STORAGE_SAS=$STORAGE_SAS -e COUNT=100 ghcr.io/tkubica12/generate_users:latest
docker run --rm -e EVENTHUB_CONNECTION_STRING=$EVENTHUB_CONNECTION_STRING -e EVENTHUB_NAMESPACE=$EVENTHUB_NAMESPACE ghcr.io/tkubica12/stream_pageviews:latest

# Running containers in Azure Container Instance
az container create -n generateusers -g datademo --image ghcr.io/tkubica12/generate_users:latest --restart-policy Never --secure-environment-variables STORAGE_SAS=$STORAGE_SAS COUNT=1000000
az container create -n generatepproducts -g datademo --image ghcr.io/tkubica12/generate_products:latest --restart-policy Never --secure-environment-variables STORAGE_SAS=$STORAGE_SAS COUNT=1
az container create -n streampageviews -g datademo --image ghcr.io/tkubica12/stream_pageviews:latest --restart-policy Always --secure-environment-variables EVENTHUB_NAMESPACE=$EVENTHUB_NAMESPACE EVENTHUB_CONNECTION_STRING=$EVENTHUB_CONNECTION_STRING
```


