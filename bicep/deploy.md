az group create -n datademo -l westeurope
az bicep build -f main.bicep && az deployment group create -g datademo --template-file main.json