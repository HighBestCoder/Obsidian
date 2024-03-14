```
Virginia - OK
Arizona - Disabled
Central - OK
East - Disabled
Texas - Disabled
```


```

'usgovvirginia, usgovarizona, usgovtexas'.

 az account set --subscription 379448df-aa3c-467b-bd73-9d9a799e9750

az mysql flexible-server import create --data-source-type "mysql_single" --data-source "yoj-test-import" --resource-group "yoj-test-import" --location eastus --name "yoj-test-import57" --admin-user "yoj" --sku-name "Standard_D2ds_v4" --tier "GeneralPurpose" --public-access 0.0.0.0 --storage-size 128 --version 5.7 --storage-auto-grow Enabled
Changing administrator login name and password is currently not supported for single to flex migrations. Please use source single server administrator login name and password to connect after migration.
Checking the existence of the resource group 'yoj-test-import'...
Resource group 'yoj-test-import' exists ? : True
(NoRegisteredProviderFound) No registered resource provider found for location 'eastus' and API version '2021-12-01-preview' for type 'locations/checkNameAvailability'. The supported api-versions are '2021-05-01-preview, 2021-05-01, 2021-12-01-preview, 2022-01-01, 2023-06-01-preview, 2023-06-30, 2023-10-01-preview'. The supported locations are 'usgovvirginia, usgovarizona, usgovtexas'.
Code: NoRegisteredProviderFound
Message: No registered resource provider found for location 'eastus' and API version '2021-12-01-preview' for type 'locations/checkNameAvailability'. The supported api-versions are '2021-05-01-preview, 2021-05-01, 2021-12-01-preview, 2022-01-01, 2023-06-01-preview, 2023-06-30, 2023-10-01-preview'. The supported locations are 'usgovvirginia, usgovarizona, usgovtexas'.
ibizasqlautobot1 [ ~ ]$
ibizasqlautobot1 [ ~ ]$
```


```
az mysql flexible-server import create --data-source-type "mysql_single" --data-source "yoj-test-import" --resource-group "yoj-test-import" --location usgovvirginia --name "yoj-test-import57" --admin-user "yoj" --sku-name "Standard_D2ds_v4" --tier "GeneralPurpose" --public-access 0.0.0.0 --storage-size 128 --version 5.7 --storage-auto-grow Enabled
```


```
Changing administrator login name and password is currently not supported for single to flex migrations. Please use source single server administrator login name and password to connect after migration.
Checking the existence of the resource group 'yoj-test-import'...
Resource group 'yoj-test-import' exists ? : True
IOPS is 684 which is either your input or free(maximum) IOPS supported for your storage size and SKU.
Creating MySQL Server 'yoj-test-import57' in group 'yoj-test-import'...
Your server 'yoj-test-import57' is using sku 'Standard_D2ds_v4' (Paid Tier). Please refer to https://aka.ms/mysql-pricing for pricing details
Configuring server firewall rule, 'azure-access', to accept connections from all Azure resources...
Make a note of your password. If you forget, you would have to reset your password with'az mysql flexible-server update -n yoj-test-import57 -g yoj-test-import -p <new-password>'.
Try using az 'mysql flexible-server connect' command to test out connection.
{
  "connectionString": "mysql --host yoj-test-import57.mysql.database.usgovcloudapi.net --user yoj --password={password}",
  "firewallName": "AllowAllAzureServicesAndResourcesWithinAzureIps_2024-3-13_8-46-38",
  "host": "yoj-test-import57.mysql.database.usgovcloudapi.net",
  "id": "/subscriptions/379448df-aa3c-467b-bd73-9d9a799e9750/resourceGroups/yoj-test-import/providers/Microsoft.DBforMySQL/flexibleServers/yoj-test-import57",
  "location": "USGov Virginia",
  "password": "*****",
  "resourceGroup": "yoj-test-import",
  "skuname": "Standard_D2ds_v4",
  "username": "yoj",
  "version": "5.7"
}
ibizasqlautobot1 [ ~ ]$ mysql --host yoj-test-import57.mysql.database.usgovcloudapi.net --user yoj --password=fedora12@
mysql: [Warning] Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 7
Server version: 5.7.44-log MySQL Community Server (GPL)

Copyright (c) 2000, 2023, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> quit

az mysql flexible-server import create --data-source-type "mysql_single" --data-source "yoj-test-import-57-central" --resource-group "yoj-test-import" --location usgovvirginia --name "yoj-flex-import-57-central" --admin-user "yoj" --sku-name "Standard_D2ds_v4" --tier "GeneralPurpose" --public-access 0.0.0.0 --storage-size 128 --version 5.7 --storage-auto-grow Enabled

USGov Virginia - 5.7 [PASS]

```

```

az mysql flexible-server import create --data-source-type "mysql_single" --data-source "yoj-test-import-80" --resource-group "yoj-import" --location usgovvirginia --name "yoj-flex-import-80" --admin-user "yoj" --sku-name "Standard_D2ds_v4" --tier "GeneralPurpose" --public-access 0.0.0.0 --storage-size 128 --version 8.0 --storage-auto-grow Enabled
```