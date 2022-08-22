# Generating data
As part of demo I am going to generate different types of data:
- Users is JSON lines flat file with user details and contains one array attribute (list of jobs) pushed to Data Lake
- Products are many JSON files, one for each product pushed to Data Lake
- Pageviews and stars are pushed to respective Event Hubs
- Orders stored in two relational tables in Azure SQL:
  - Order table consisting of orderId, userId, orderDate and orderValue
  - Items table consisting of orderId, rowId and productId 

# Deployment
Everything is automated as part of data perparation Terraform module. Each generator/streamer runs as Azure Container Instance. To modify ammount of data generated you can change module inputs in main.tf file.

# Dev
For code changes or running generators locally here are few notes and commands.

```bash
# Install Anaconda
curl https://repo.anaconda.com/archive/Anaconda3-2022.05-Linux-x86_64.sh -o anaconda.sh
bash anaconda.sh

# Create environment
conda env create -f environment.yml

# Active environment
conda activate users   # or products, pageviews, orders

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

# Stream pageviews adn stars
export EVENTHUB_NAMESPACE="myeventhubnamespace"
export EVENTHUB_CONNECTION_STRING_PAGEVIEWS=$(az eventhubs eventhub authorization-rule keys list -g data-demo --namespace-name $EVENTHUB_NAMESPACE --eventhub-name pageviews -n pageviewsSender --query primaryConnectionString -o tsv)
export EVENTHUB_CONNECTION_STRING_STARS=$(az eventhubs eventhub authorization-rule keys list -g data-demo --namespace-name $EVENTHUB_NAMESPACE --eventhub-name stars -n starsSender --query primaryConnectionString -o tsv)
python stream.py

# Generate orders
export SQL_SERVER="tkwngxfscwrl.database.windows.net"
export SQL_DATABASE="orders"
export SQL_USER="tomas"
export SQL_PASSWORD='fu!>us7NmW5F7H4b'
export COUNT=10000000
export USER_MAX_ID=999999
export PRODUCT_MAX_ID=999999

# Build image
docker login -u tkubica12 ghcr.io
docker build -t ghcr.io/tkubica12/generate_users:latest .
docker build -t ghcr.io/tkubica12/generate_products:latest .
docker build -t ghcr.io/tkubica12/stream_pageviews:latest .
docker build -t ghcr.io/tkubica12/generate_orders:latest .
docker push ghcr.io/tkubica12/generate_users:latest
docker push ghcr.io/tkubica12/generate_products:latest
docker push ghcr.io/tkubica12/stream_pageviews:latest
docker push ghcr.io/tkubica12/generate_orders:latest

# Running containers locally
docker run -it --rm -e STORAGE_SAS=$STORAGE_SAS -e COUNT=100 -e VIP_COUNT=10 ghcr.io/tkubica12/generate_users:latest
docker run -it --rm -e STORAGE_SAS=$STORAGE_SAS -e COUNT=100 ghcr.io/tkubica12/generate_users:latest
docker run -it --rm -e EVENTHUB_CONNECTION_STRING_PAGEVIEWS=$EVENTHUB_CONNECTION_STRING_PAGEVIEWS -e EVENTHUB_CONNECTION_STRING_STARS=$EVENTHUB_CONNECTION_STRING_STARS -e EVENTHUB_NAMESPACE=$EVENTHUB_NAMESPACE ghcr.io/tkubica12/stream_pageviews:latest
docker run --rm -it -e SQL_SERVER=$SQL_SERVER \
    -e SQL_DATABASE=$SQL_DATABASE \
    -e SQL_USER=$SQL_USER \
    -e SQL_PASSWORD=$SQL_PASSWORD \
    -e COUNT=$COUNT \
    -e USER_MAX_ID=$USER_MAX_ID \
    -e PRODUCT_MAX_ID=$PRODUCT_MAX_ID \
    ghcr.io/tkubica12/generate_orders:latest

# Running containers in Azure Container Instance
az container create -n generateusers -g data-demo --image ghcr.io/tkubica12/generate_users:latest --restart-policy Never --secure-environment-variables STORAGE_SAS=$STORAGE_SAS COUNT=1000000
az container create -n generatepproducts -g data-demo --image ghcr.io/tkubica12/generate_products:latest --restart-policy Never --secure-environment-variables STORAGE_SAS=$STORAGE_SAS COUNT=1
az container create -n streampageviews -g data-demo --image ghcr.io/tkubica12/stream_pageviews:latest --restart-policy Always --secure-environment-variables EVENTHUB_NAMESPACE=$EVENTHUB_NAMESPACE EVENTHUB_CONNECTION_STRING=$EVENTHUB_CONNECTION_STRING
az container create -n generateorders -g data-demo --image ghcr.io/tkubica12/generate_orders:latest \
    --restart-policy Never \
    --secure-environment-variables SQL_SERVER=$SQL_SERVER \
    SQL_DATABASE=$SQL_DATABASE \
    SQL_USER=$SQL_USER \
    SQL_PASSWORD=$SQL_PASSWORD \
    COUNT=$COUNT \
    USER_MAX_ID=$USER_MAX_ID \
    PRODUCT_MAX_ID=$PRODUCT_MAX_ID
```


