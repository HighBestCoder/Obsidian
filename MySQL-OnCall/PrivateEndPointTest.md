```
#!/bin/bash

if [[ $# -eq 2 ]]; then
    echo "Usage: ./test resource_group_name single_servername"
    exit -1
fi

RP=$1
SS_NAME=$2

az account set --subscription 2941a09d-7bcf-42fe-91ca-1765f521c829
az group create --name $RG --location centraluseuap
az network vnet create --name myVirtualNetwork --resource-group $RG --subnet-name mySubnet
az network vnet subnet update --name mySubnet --resource-group $RG --vnet-name myVirtualNetwork --disable-private-endpoint-network-policies true
az vm create --resource-group $RG --name myVm --image Win2019Datacenter --admin-username yoj --admin-password "LinuxKernel67&"
az mysql server create --name $SS_NAME --resource-group $RG --location centraluseuap --admin-user yoj --admin-password "fedora12@" --sku-name GP_Gen5_2
az network private-endpoint create --name myPrivateEndpoint --resource-group $RG --vnet-name myVirtualNetwork --subnet mySubnet --private-connection-resource-id $(az resource show -g $RG -n $SS_NAME --resource-type "Microsoft.DBforMySQL/servers" --query "id" -o tsv) --group-id mysqlServer --connection-name myConnection
az network private-dns zone create --resource-group $RG --name  "privatelink.mysql.database.azure.com"
az network private-dns link vnet create --resource-group $RG --zone-name  "privatelink.mysql.database.azure.com" --name MyDNSLink --virtual-network myVirtualNetwork --registration-enabled false
networkInterfaceId=$(az network private-endpoint show --name myPrivateEndpoint --resource-group $RG --query 'networkInterfaces[0].id' -o tsv)
az resource show --ids $networkInterfaceId --api-version 2019-04-01 -o json
az network private-dns record-set a create --name $SS_NAME --zone-name privatelink.mysql.database.azure.com --resource-group $RG
az network private-dns record-set a add-record --record-set-name $SS_NAME --zone-name privatelink.mysql.database.azure.com --resource-group $RG -a 10.0.0.5
```