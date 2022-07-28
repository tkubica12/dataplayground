

# Generate data
```bash
# Get SAS token
export STORAGE_ACCOUNT_NAME=$(az deployment group show -g datademo -n main --query properties.outputs.storageAccountName.value -o tsv)
export CONTAINER_NAME=bronze
export CONTAINER_SAS=$(az storage container generate-sas -n $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --expiry 2037-12-31T23:59:59Z --permissions rwl --https-only -o tsv)
export USERS_SAS=https://$STORAGE_ACCOUNT_NAME.dfs.core.windows.net/${CONTAINER_NAME}?${CONTAINER_SAS}
export PRODUCTS_SAS=https://$STORAGE_ACCOUNT_NAME.dfs.core.windows.net/${CONTAINER_NAME}?${CONTAINER_SAS}

# Create resource group
az group create -n datageneration -l westeurope

# Generate users
az container create -n generateusers -g datageneration --image ghcr.io/tkubica12/generate_users:latest --restart-policy Never --secure-environment-variables USERS_SAS=$USERS_SAS USERS_COUNT=1000000

# Generate products
az container create -n generatepproducts -g datageneration --image ghcr.io/tkubica12/generate_products:latest --restart-policy Never --secure-environment-variables PRODUCTS_SAS=$USERS_SAS PRODUCTS_COUNT=1

# Destroy environment
az group delete -n datageneration -y
```

# Dev

```bash
# Install Anaconda
curl https://repo.anaconda.com/archive/Anaconda3-2022.05-Linux-x86_64.sh -o anaconda.sh
bash anaconda.sh

# Create environment
conda env create -f environment.yaml

# Active environment
conda activate users

# Get SAS token
export STORAGE_ACCOUNT_NAME=$(az deployment group show -g datademo -n main --query properties.outputs.storageAccountName.value -o tsv)
export CONTAINER_NAME=bronze
export CONTAINER_SAS=$(az storage container generate-sas -n $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --expiry 2037-12-31T23:59:59Z --permissions rwl --https-only -o tsv)

# Generate users
export USERS_SAS=https://$STORAGE_ACCOUNT_NAME.dfs.core.windows.net/${CONTAINER_NAME}?${CONTAINER_SAS}
export USERS_COUNT=100
python generate_users.py

# Generate products
export PRODUCTS_SAS=https://$STORAGE_ACCOUNT_NAME.dfs.core.windows.net/${CONTAINER_NAME}?${CONTAINER_SAS}
export PRODUCTS_COUNT=100
python generate_products.py

# Build image
docker login -u tkubica12 ghcr.io
docker build -t ghcr.io/tkubica12/generate_users:latest .
docker build -t ghcr.io/tkubica12/generate_products:latest .
docker push ghcr.io/tkubica12/generate_users:latest
docker push ghcr.io/tkubica12/generate_products:latest

# Running containers locally
docker run --rm -e USERS_SAS=$USERS_SAS -e USERS_COUNT=100 ghcr.io/tkubica12/generate_users:latest
docker run --rm -e PRODUCTS_SAS=$USERS_SAS -e PRODUCTS_COUNT=100 ghcr.io/tkubica12/generate_users:latest
```


