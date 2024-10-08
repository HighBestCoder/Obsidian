<#
.SYNOPSIS
   Sets the value of a single parameter.

.DESCRIPTION
   The YOJ-SetSingleParameter function sets the value of a configuration parameter for the specified server.

.PARAMETER ServerName
   The name of the server.

.PARAMETER ConfigName
   The name of the configuration parameter.

.PARAMETER ConfigValue
   The value of the configuration parameter.

.EXAMPLE
   YOJ-SetSingleParameter -ServerName "myserver" -ConfigName "myconfig" -ConfigValue "myvalue"
#>
function YOJ-SetSingleParameter {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ServerName,

        [Parameter(Mandatory=$true)]
        [string]$ConfigName,

        [Parameter(Mandatory=$true)]
        [string]$ConfigValue
    )

    $info = Get-ElasticServerInstance2 -ServerName $ServerName -IncludeFabricProperties -State *
    $info | Get-ElasticServerConfig -ConfigName $ConfigName
    $info | Set-ElasticServerConfig -ConfigName $ConfigName -ConfigValue $configValue -ConfigType UserConfiguration
    $info | Get-ElasticServerConfig -ConfigName $ConfigName
}

<#
.SYNOPSIS
   Restarts a specific server.

.DESCRIPTION
   The YOJ-RestartSingleServer function restarts the specified server.

.PARAMETER ServerName
   The name of the server.

.EXAMPLE
   YOJ-RestartSingleServer -ServerName "myserver"
#>
function YOJ-RestartSingleServer {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ServerName
    )

    $info = Get-ElasticServerInstance2 -ServerName $ServerName -IncludeFabricProperties

    Get-FabricNode -NodeName $info.FabricNodeName -NodeClusterName $info.TenantRingName | Kill-Process -ProcessName "DkMon.exe" -ApplicationNameUri $info.FabricApplicationUri
}

<#
.SYNOPSIS
   Retrieves the SAS token for a server.

.DESCRIPTION
   The YOJ-MERUSASToken function retrieves the SAS token for the specified server.

.PARAMETER ServerName
   The name of the server.

.EXAMPLE
   YOJ-MERUSASToken -ServerName "myserver"
#>
function YOJ-MERUSASToken {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ServerName
    )

    $info = Get-MySqlServer -ServerName $ServerName
    $info | Get-MySqlServerSasToken -StorageKind PremiumFileShare  -Minutes 600 -Permissions rwdl
}

function YOJ-MERUSASTokenBlob {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ServerName
    )

    $info = Get-MySqlServer -ServerName $ServerName
    $info | Get-MySqlServerSasToken -StorageKind BlobContainer  -Minutes 600 -Permissions rwdl
}

<#
.SYNOPSIS
   Retrieves the SAS token for a single server.

.DESCRIPTION
   The YOJ-SingleServerSASToken function retrieves the SAS token for the specified server using the server's ElasticServerId.

.PARAMETER ServerName
   The name of the server.

.EXAMPLE
   YOJ-SingleServerSASToken -ServerName "mc2-il5-prd-mysql-01"
#>
function YOJ-SingleServerSASToken {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ServerName
    )

    $info = Get-ElasticServerinstance2 -ServerName $ServerName
    Get-ElasticServerSasTokenById -ServerName $ServerName -ElasticServerId $info.ElasticServerId -Minutes 360 -Backup $false -Permissions rwdl -StorageType FileShare
}


<#
.SYNOPSIS
   Computes the number of rows needed in each table to reach a specified storage size.

.DESCRIPTION
   The YOJ-ComputeTableRows function calculates the number of rows that should be inserted into each table
   to reach the specified total storage size. The calculation is based on the schema of the table and the
   storage characteristics of the InnoDB storage engine in MySQL.

.PARAMETER TableNumber
   The number of tables in the database.

.PARAMETER StorageSize
   The total storage size in GB that the tables should reach.

.EXAMPLE
   $RowsPerTable = YOJ-ComputeTableRows -TableNumber 10000 -StorageSize 10
   Write-Output "Each table should have approximately $RowsPerTable rows"

   This example calculates the number of rows that should be inserted into each of 10,000 tables so that
   the total storage size of the tables is approximately 10 GB.

.NOTES
   This function provides a rough estimate of the number of rows needed. The actual number of rows may vary
   depending on a variety of factors, including the actual size of the data, the fill factor of the pages,
   the presence of additional indexes, and so on. For more accurate results, you should perform testing in
   your actual environment.

#>
function YOJ-ComputeTableRows {
    param(
        [Parameter(Mandatory=$true)]
        [int64]
        $TableNumber,

        [Parameter(Mandatory=$true)]
        [int64]
        $StorageSize
    )

    # StorageSize is in GB, convert it to MB first
    $StorageSizeMB = $StorageSize * 1024

    # Compute table size in MB
    $TableSizeMB = $StorageSizeMB / $TableNumber

    # Convert table size to bytes
    $TableSizeBytes = $TableSizeMB * 1024 * 1024

    # Define the size of InnoDB page and the size of each row
    $InnoDBPageSizeBytes = 16 * 1024
    $RowSizeBytes = 188

    # Compute the number of rows in each page
    $RowsPerPage = [Math]::Floor(($InnoDBPageSizeBytes - 100) / $RowSizeBytes)

    # Compute the number of pages in each table
    $PagesPerTable = [Math]::Floor($TableSizeBytes / $InnoDBPageSizeBytes)

    # Compute the number of rows in each table
    $RowsPerTable = $RowsPerPage * $PagesPerTable

    return $RowsPerTable
}

<#
.SYNOPSIS
    Resizes the storage of a MERU server.

.DESCRIPTION
    The YOJ-MERUStorageResize function resizes the storage of a MERU server. It first gets the server information using the Get-MySqlServer2 function, and then sets the new storage size using the Set-MySqlServer function.

.PARAMETER ServerName
    The name of the server to be resized.

.PARAMETER StorageSizeInMB
    The new storage size in MB.

.EXAMPLE
    YOJ-MERUStorageResize -ServerName "your_server_name" -StorageSizeInMB 131072

    This command resizes the storage of the server named "your_server_name" to 131072 MB.

.NOTES
    Make sure the Get-MySqlServer2 and Set-MySqlServer functions are defined in your environment before using this function.

.LINK
    For more information, see: http://your_documentation_link_here
#>
function YOJ-MERUStorageResize {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ServerName,

        [Parameter(Mandatory=$true)]
        [int]$StorageSizeInMB
    )

    $info = Get-MySqlServer2 -ServerName $ServerName
    $info | Set-MySqlServer -SizeInMb $StorageSizeInMB -ServerVersion $info.ServerVersion -Location $info.Location
}

<#
.SYNOPSIS
This function performs a dry run of a point-in-time restore operation on a single server.

NOTE: If you do not know how to set target date, you can get a SAS token, and find the timestamp from the snapshot time.
Or you can use below time as an example:

<PointInTime>2024-02-16T10:37:02Z</PointInTime>

.DESCRIPTION
YOJ-SingleServerPITRDryRun is a function that accepts three parameters: ServerName, TargetDateStr, and TargetServerName. 
It converts the TargetDateStr (a date string in a specific format) into a DateTime object, and then converts the DateTime object into a specific format of English date string. 
Afterwards, it performs some operations including retrieving server information and executing a restore operation.

.PARAMETER ServerName
The name of the server.

.PARAMETER TargetDateStr
The target date in string format. The format should be "yyyy-MM-ddTHH:mm:ss.fffffffZ".

.PARAMETER TargetServerName
The name of the target server.

.EXAMPLE
YOJ-SingleServerPITRDryRun -ServerName "server1" -TargetDateStr "2024-02-16T10:37:02.0000000Z" -TargetServerName "server2"
#>
function YOJ-SingleServerPITRDryRun {
   param (
       [Parameter(Mandatory=$true)] [string]$ServerName,
       [Parameter(Mandatory=$true)] [string]$TargetDateStr,
       [Parameter(Mandatory=$true)] [string]$TargetServerName
   )
   $targetDate = $TargetDateStr
   # Perform other operations
   $info = Get-ElasticServerInstance2 -ServerName $ServerName
   Restore-ElasticServer2 -SubscriptionId $info.SubscriptionId -ServerType $info.ServerType -SourceResourceGroup $info.ResourceGroup -SourceServerName $info.ServerName -TargetServerName $TargetServerName -PointInTimeUtc $targetDate -TargetResourceGroup $info.ResourceGroup
}


<#
.SYNOPSIS
This function generates two specific directory paths and prints them.

.DESCRIPTION
The function YOJ-GenerateDirectoryPaths takes a ServerName as input, retrieves the server information using the Get-ElasticServerInstance2 function, and generates two specific directory paths based on the extracted information. The paths are then printed to the console.

.PARAMETER ServerName
The name of the server from which to retrieve information.

.EXAMPLE
YOJ-GenerateDirectoryPaths -ServerName "ne-prd-spark-mysql-01-cloud-shell-deleteme-dryrun2"

#>
function YOJ-GetJitMySqlConnectionStringSingleServer {
   param(
       [Parameter(Mandatory=$true)]
       [string]$ServerName
   )

   # Get the server information
   $info = Get-ElasticServerInstance2 -ServerName $ServerName -IncludeFabricProperties

   # Extract the required information from the SuperAdminConnectCommand
   if ($info.SuperAdminConnectCommand -match "(_App\\)(.*?)\\(MySQL.Code.*?)(\\Monitor.*) (-P\d+)") {
       $AppInfo = $Matches[2]
       $MySQLCode = $Matches[3]
       $PortInfo = $Matches[5]

       # Generate the directory paths
       $path1 = "S:\WFRoot\_App\Worker.PAL.MySQL_$AppInfo\work\Sandbox\work"
       $path2 = "S:\WFRoot\_App\__shared\Store\Worker.PAL.MySQL\MySQL.$MySQLCode\Packages\MySQL.8.0.0.0\x64\content\mysql\bin\mysql.exe"

       # Print the directory paths
       Write-Output "Path 1: $path1"
       Write-Output "Path 2: $path2"
   }
   else {
       Write-Error "Unable to parse command."
   }
}

<#
.SYNOPSIS
This function generates two specific directory paths, a command, and prints them along with manual operation steps.

.DESCRIPTION
The function YOJ-GenerateDirectoryPathsAndCommand takes a ServerName as input, retrieves the server information using the Get-ElasticServerInstance2 function, and generates two specific directory paths and a command based on the extracted information. The paths, command, and manual operation steps are then printed to the console.

.PARAMETER ServerName
The name of the server from which to retrieve information.

.EXAMPLE
YOJ-GenerateDirectoryPathsAndCommand -ServerName "ne-prd-spark-mysql-01-cloud-shell-deleteme-dryrun2"

#>
function YOJ-GenerateDirectoryPathsAndCommand {
   param(
       [Parameter(Mandatory=$true)]
       [string]$ServerName
   )

   # Get the server information
   $info = Get-ElasticServerInstance2 -ServerName $ServerName -IncludeFabricProperties

   # Extract the required information from the SuperAdminConnectCommand
   if ($info.SuperAdminConnectCommand -match "(_App\\)(.*?)\\(MySQL.Code.*?)(\\Monitor.*) (-P\d+)") {
       $AppInfo = $Matches[2]
       $MySQLCode = $Matches[3]
       $PortInfo = $Matches[5]

       $MySQLCode = $MySQLCode -replace "\.lk$", ""

       # Generate the directory paths
       $path1 = "S:\WFRoot\_App\$AppInfo\work\Sandbox\work"
       $path2 = "S:\WFRoot\_App\__shared\Store\Worker.PAL.MySQL\$MySQLCode\Packages\MySQL.8.0.0.0\x64\content\mysql\bin\mysql.exe"

       # Generate the command
       $command = "$path2 -u azure_superuser $PortInfo --ssl-cert=.\\cert.pem --ssl-key=.\key.pem --ssl-ca=.\ca.pem"

       # Print the directory paths, command, and manual operation steps
       Write-Output "Path 1: $path1"
       Write-Output "Manual steps for Path 1:"
       Write-Output "1. Open cmd in Administrator mode."
       Write-Output "2. Switch to S drive and run 'start .'"
       Write-Output "3. Open the directories in explorer."
       Write-Output "4. After opening '$path1', run 'cmd .' in explorer to open a new cmd window."

       Write-Output "Path 2: $path2"
       Write-Output "Manual steps for Path 2:"
       Write-Output "1. Open cmd in Administrator mode."
       Write-Output "2. Switch to S drive and run 'start .'"
       Write-Output "3. Open the directories in explorer."

       Write-Output "Command: $command"
   }
   else {
       Write-Error "Unable to parse command."
   }
}

<#
.SYNOPSIS
Generates a URL for remote access to a VM based on server information.

.DESCRIPTION
The YOJ-FlexVMJITUrl function generates a URL for remote access to a VM. It uses the server name to get the server information using the Get-MySqlServer2 function. Then it constructs a URL with the server information and returns it.

.PARAMETER ServerName
The name of the server for which to generate the URL.

.PARAMETER IcMId
The ID for the IcM item. If provided, it will be included in the URL.

.EXAMPLE
PS C:\Users\yoj\SqlAzureConsole> $server = "ne-trftrain-mysql-cloud-shell-test2-infra-838"
PS C:\Users\yoj\SqlAzureConsole> $url = YOJ-FlexVMJITUrl -ServerName $server -IcMId "12345"
PS C:\Users\yoj\SqlAzureConsole> Write-Output $url

This example generates a URL for the specified server and then prints it to the console.

.NOTES
This function relies on the Get-MySqlServer2 function to get server information.
#>
function YOJ-FlexVMJITUrl {
   param (
       [Parameter(Mandatory=$true)]
       [string]$ServerName,

       [Parameter(Mandatory=$false)]
       [string]$IcMId
   )

   # Call your function to get server info
   $info = Get-MySqlServer2 -ServerName $ServerName -State *

   # Prepare the parameters for the URL
   $ResourceType = "Remote%20Access%20-%20IAAS"
   $Region = $info.Location
   $SubscriptionId = $info.MsftSubscriptionId
   $ResourceGroup = $info.MsftResourceGroupName
   $ResourceName = $info.VirtualMachineName

   # Construct the URL
   $url = "https://jitaccess.security.core.windows.net/WorkFlowTempAccess.aspx?View=Submit&ResourceType=$ResourceType&Region=$Region&SubscriptionId=$SubscriptionId&ResourceGroup=$ResourceGroup&ResourceName=$ResourceName"

   # If IcMId is provided, add it to the URL
   if ($IcMId) {
       $url += "&MainContent_WorkItemID_TextBox=$IcMId"
   }

   return $url
}

<#
.SYNOPSIS
Opens port 22 (SSH) for a server based on server information.

.DESCRIPTION
The YOJ-FlexServerOpen22ForSSH function opens port 22 (SSH) for a server. It uses the server name to get the server information using the Get-MySqlServer2 function. Then it constructs a model for the firewall rule and sends a request to add or update the security rule.

.PARAMETER ServerName
The name of the server for which to open port 22.

.EXAMPLE
PS C:\Users\yoj\SqlAzureConsole> YOJ-FlexServerOpen22ForSSH -ServerName "ne-trftrain-mysql-cloud-shell-test2-infra-838"

This example opens port 22 for the specified server.

.NOTES
This function relies on the Get-MySqlServer2 and Invoke-MySqlControlArbitraryApi functions to get server information and send the request.
#>
function YOJ-FlexServerOpen22ForSSH {
   param (
       [Parameter(Mandatory=$true)]
       [string]$ServerName
   )

   # Get server info
   $info = Get-MySqlServer2 -ServerName $ServerName

   # Prepare the model for the firewall rule
   $model = @{
      Owner                      = "Microsoft"
      FirewallRuleName           = "Port_22"
      Description                = "EnablePort22"
      Priority                   = 710
      Access                     = "Allow"
      Direction                  = "Inbound"
      SqlTag                     = "CorpNetSaw"
      Protocol                   = "*"
      SourcePortRange            = "*"
      DestinationPortRange       = "22"
      DestinationAddressPrefix   = "*"
   }

   # Convert the model to JSON
   $body = ConvertTo-Json $model

   # Prepare the URL for the request
   $orcas_instance_id = $info.OrcasInstanceId

   # Send the request to add or update the security rule
   $response = Invoke-MySqlControlArbitraryApi -Method Put -Url "FirewallRule/AddOrUpdateSecurityRule?orcasInstanceId=$orcas_instance_id&nsgType=Microsoft" -CabId 123123  -Body $body

   # Print the response
   echo $response
}

<#
.SYNOPSIS
Generates a URL for Just-In-Time (JIT) access to a server.

.DESCRIPTION
The YOJ-SingleServerJITUrl function generates a URL for Just-In-Time (JIT) access to a server. It uses the server name to get the server information using the Get-ElasticServerInstance2 function. Then it constructs the URL based on the server information and the provided subscription ID.

.PARAMETER ServerName
The name of the server for which to generate the JIT access URL.

.PARAMETER SubscriptionId
The subscription ID to use in the JIT access URL.
This subscription is not single-server's subscription. It's get from PaaSV2 from service-fabric app. Please check with OneNote content.


.EXAMPLE
PS C:\Users\yoj\SqlAzureConsole> YOJ-SingleServerJITUrl -ServerName "ne-prd-spark-mysql-01-cloud-shell-deleteme-dryrun3" -SubscriptionId "9697d26c-2d7f-4f62-8743-71c824a941d4"

This example generates a JIT access URL for the specified server and subscription ID.

.NOTES
This function relies on the Get-ElasticServerInstance2 function to get server information.
#>
function YOJ-SingleServerJITUrl {
   param (
       [Parameter(Mandatory=$true)]
       [string]$ServerName,

       [Parameter(Mandatory=$true)]
       [string]$SubscriptionId,

       [Parameter(Mandatory=$false)]
       [string]$IcMId
   )

   $regions = @(
    "australiacentral",
    "australiacentral2",
    "australiaeast",
    "australiasoutheast",
    "austriaeast",
    "belgiumcentral",
    "brazilsouth",
    "brazilsoutheast",
    "canadacentral",
    "canadaeast",
    "centralindia",
    "centralus",
    "centraluseuap",
    "chilecentral",
    "denmarkeast",
    "eastasia",
    "eastus",
    "eastus2",
    "eastus2euap",
    "eastusslv",
    "eastusstg",
    "francecentral",
    "francesouth",
    "germanynorth",
    "germanywestcentral",
    "indiasouthcentral",
    "indonesiacentral",
    "israelcentral",
    "israelnorthwest",
    "italynorth",
    "japaneast",
    "japanwest",
    "jioindiacentral",
    "jioindiawest",
    "koreacentral",
    "koreasouth",
    "malaysiasouth",
    "malaysiawest",
    "mexicocentral",
    "newzealandnorth",
    "northcentralus",
    "northeurope",
    "norwayeast",
    "norwaywest",
    "polandcentral",
    "qatarcentral",
    "southafricanorth",
    "southafricawest",
    "southcentralus",
    "southcentralusstg",
    "southeastasia",
    "southeastus",
    "southindia",
    "spaincentral",
    "swedencentral",
    "swedensouth",
    "switzerlandnorth",
    "switzerlandwest",
    "taiwannorth",
    "taiwannorthwest",
    "uaecentral",
    "uaenorth",
    "uknorth",
    "uksouth",
    "uksouth2",
    "ukwest",
    "westcentralus",
    "westeurope",
    "westindia",
    "westus",
    "westus.validation",
    "westus2",
    "westus3"
   )

    # Get $info
    $info = Get-ElasticServerInstance2 -ServerName $ServerName -IncludeFabricProperties

    # Split $info.TenantRingName by '.'
    $trnParts = $info.TenantRingName.Split(".")

    # Generate ResourceGroup
    $ResourceGroup = "wasd-prod-$($trnParts[1])-$($trnParts[0])"

    # Generate Location
    $Location = $regions | Where-Object { $info.TenantRingName.Contains($_) } | Sort-Object Length -Descending | Select-Object -First 1

    # Extract InstanceIds
    $InstanceIds = $info.FabricNodeName.Split("_")[-1]

    # Generate URL
    $url = "https://jitaccess.security.core.windows.net/WorkFlowTempAccess.aspx?View=Submit&ResourceType=Virtual%20machine%20scale%20set&Region=$Location&SubscriptionId=$SubscriptionId&ResourceGroup=$ResourceGroup&ResourceName=DB&InstanceIds=$InstanceIds&AccessLevel=Administrator"

    # If IcMId is provided, add it to the URL
    if ($IcMId) {
        $url += "&MainContent_WorkItemID_TextBox=$IcMId"
    }

    return $url
}

<#
.SYNOPSIS
    This function generates a URL for the Just-In-Time (JIT) access portal.

.DESCRIPTION
    The YOJ-FlexServerJITPortal function generates a URL for the JIT access portal based on a server name. 
    It first uses the Get-MySqlServer2 function to get information about the server. 
    It then extracts the MsftSubscriptionId from this information and uses it to generate a URL.

.PARAMETER ServerName
    The name of the server for which to generate a JIT access portal URL.

.EXAMPLE
    YOJ-FlexServerJITPortal -ServerName "MyServerName"

    This command generates a JIT access portal URL for the server named "MyServerName".

.OUTPUTS
    String. The function outputs a URL.

.NOTES
    The generated URL includes the resource type (Subscription), the subscription ID (MsftSubscriptionId), 
    and the access level (Owner).
#>
function YOJ-FlexServerJITPortal {
   [CmdletBinding()]
   param(
       [Parameter(Mandatory=$true, HelpMessage="The name of the server for which to generate a JIT access portal URL.")]
       [string]$ServerName,

       [Parameter(Mandatory=$false)]
       [string]$IcMId
   )

   # Get $info
   $info = Get-MySqlServer2 -ServerName $ServerName

   # Extract MsftSubscriptionId
   $MSFTSubId = $info.MsftSubscriptionId

   # Generate URL
   $url = "https://jitaccess.security.core.windows.net/WorkFlowTempAccess.aspx?View=Submit&ResourceType=Subscription&SubscriptionId=$MSFTSubId&AccessLevel=Owner"

    # If IcMId is provided, add it to the URL
    if ($IcMId) {
        $url += "&MainContent_WorkItemID_TextBox=$IcMId"
    }

   return $url
}

<#
.SYNOPSIS
    This function retrieves information about a SQL Server and generates a SAS token.

.DESCRIPTION
    The YOJ-FlexServerSASToken function uses the Get-MySqlServer and Get-MySqlServerSasToken functions 
    to retrieve information about a SQL Server and generate a SAS token with specific permissions. 

.PARAMETER ServerName
    The name of the SQL Server for which to retrieve information and generate a SAS token.

.EXAMPLE
    YOJ-FlexServerSASToken -ServerName "your_server_name"
    This command retrieves information about the SQL Server named "your_server_name" and generates a SAS token.

.NOTES
    This function depends on the Get-MySqlServer and Get-MySqlServerSasToken functions. 
    Make sure these functions or cmdlets are available in your environment.
#>

function YOJ-FlexServerSASToken {
   param(
       [Parameter(Mandatory=$true)]
       [string]$ServerName
   )

   $info = Get-MySqlServer -ServerName $ServerName
   $info | Get-MySqlServerSasToken -StorageKind PremiumFileShare -Minutes 600 -Permissions rwdl
}

function YOJ-FlexServerPITRDryRun {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ServerName,

        [Parameter(Mandatory=$false)]
        [string]$RestoreToTime
    )

    $restore_to_time = $RestoreToTime

    # Step 1
    $queryResult = Query-MySqlControlStore "Select
        tserver.state,
        tserver.create_time,
        (case when trs.standby_count > 0 then 1 else 0 end) AS ha_enabled,
        (case when JSON_VALUE(tserver.entity_extension_data, '$.IsAutoMigratedFromSingleServer') = 'true' then 1 else 0 end) AS auto_migrated,
        tserver.replication_role,
        tserver.server_name,
        tserver.server_type,
        tserver.server_version,
        tserver.server_sku,
        tserver.is_vnet_injected,
        (case when trs.is_private_endpoint_enabled = 'true' then 'true' else 'false' end) AS is_private_endpoint_enabled,
        tserver.storage_limit_in_mb,
        tserver.storage_iops,
        auto_scale_iops=trs.paid_iops_enabled,
        tserver.autogrow,
        data_storage_account=tsa.account_name,
        tserver.customer_subscription_id,
        tserver.customer_resource_group_name,
        tserver.orcas_instance_id,
        tserver.replication_set_id,
        tserver.byok_enabled,
        tserver.geo_redundant_backup_enabled,
        trs.log_on_disk_enabled,
        tos.azure_os_name,
        msft_subscription_id = trg.subscription_id,
        msft_resource_group_name = trg.resource_group_name
    FROM dbo.entity_orcas_servers as tserver
    LEFT JOIN dbo.entity_azure_virtual_machines AS tvm ON tserver.orcas_instance_id = tvm.orcas_instance_id
    LEFT JOIN dbo.entity_azure_os as tos on tos.id = tvm.azure_os_entity_id
    LEFT JOIN dbo.entity_azure_resource_groups AS trg ON tvm.resource_group_entity_id = trg.id
    LEFT JOIN dbo.entity_orcas_replication_sets AS trs ON trs.replication_set_id = tserver.replication_set_id
    LEFT OUTER JOIN dbo.entity_azure_storage_account AS tsa ON tserver.orcas_instance_id = tsa.orcas_instance_id
    WHERE (tserver.server_name = '$ServerName')
        AND (tserver.state != 'Tombstoned')
        AND (tsa.account_name is NULL OR tsa.account_name LIKE '%fsdata')
    ORDER BY tserver.create_time ASC;"

    $is_vnet = $queryResult.is_vnet_injected
    $is_private_link = $queryResult.is_private_endpoint_enabled

    # 对 is_vnet 进行判断
    if ($is_vnet -eq $true) {
        Write-Output "VNET"
    } else {
        Write-Output "NOT_VNET"
    }

    # 对 is_private_link 进行判断
    if ($is_private_link -eq $true) {
        Write-Output "PRIVATE_LINK"
        Write-Output "This is a private link server, PITR is not supported."
        return
    } else {
        Write-Output "NOT_PRIVATE_LINK"
    }

    # Step 3
    if ($is_vnet -eq $true) {
        $subnetQueryResult = Query-MySqlControlStore "select 
        concat ('/subscriptions/', vnet.delegated_virtual_network_subscription_id, '/resourceGroups/',vnet.delegated_virtual_network_resource_group, 
        '/providers/Microsoft.Network/virtualNetworks/', vnet.network_name, '/subnets/', sbn.subnet_name) as subnet_arm_resource_id
        from entity_orcas_servers as svr
        join entity_dnc_network_container dnc on svr.orcas_instance_id = dnc.orcas_instance_id
        join entity_delegated_subnet as sbn on sbn.id = dnc.delegated_subnet_entity_id
        join entity_delegated_virtual_network as vnet on vnet.id = sbn.delegated_virtual_network_entity_id
        where svr.server_name = '$ServerName'"
        $subnet_arm_resource_id = $subnetQueryResult.subnet_arm_resource_id
        Write-Output $subnet_arm_resource_id
    }

    # Step 4
    if ($is_vnet -eq $true) {
        $zoneQueryResult = Query-MySqlControlStore "select
        zone.is_customer_private_dns_zone as need_for_restore,
        CONCAT ('/subscriptions/' , convert(nvarchar(50), zone.private_dns_zone_subscription_id)  , '/resourceGroups/' , 
        zone.private_dns_zone_resource_group ,'/providers/Microsoft.Network/privateDnsZones/' , zone.private_dns_zone_name) as zone_arm_resource_id
        from entity_orcas_servers as svr
        join entity_orcas_replication_sets as rs on svr.replication_set_id = rs.replication_set_id
        join entity_azure_dns_record as dns on rs.replication_set_id = dns.orcas_instance_id
        join entity_azure_private_dns_zone as zone on dns.private_dns_zone_entity_id = zone.id
        where svr.server_name = '$ServerName'"
        $need_for_restore = $zoneQueryResult.need_for_restore
        $zone_arm_resource_id = $zoneQueryResult.zone_arm_resource_id
        Write-Output $need_for_restore $zone_arm_resource_id 
    }

    # Step 5
    $source_server = Get-MySqlServer2 -ServerName $ServerName
    Write-Output "Restore to time: $restore_to_time"

    $additionalParameters = @{}
    if ($source_server.ServerEdition -eq "Burstable") {
        $additionalParameters.ServerSku = "Standard_D2ds_v4"
    }

    if ($is_vnet -eq $false) {
        Restore-MySqlServer -CustomerSubscriptionId $source_server.SubscriptionId -CustomerResourceGroup $source_server.ResourceGroup -SourceServerName $source_server.ServerName -TargetServerName "$(${source_server}.ServerName)-dry-run" -RestoreToTime $restore_to_time @additionalParameters
    } elseif ($need_for_restore -eq $false) {
        Restore-MySqlServer -CustomerSubscriptionId $source_server.SubscriptionId -CustomerResourceGroup $source_server.ResourceGroup -SourceServerName $source_server.ServerName -TargetServerName "$(${source_server}.ServerName)-dry-run" -RestoreToTime $restore_to_time -SubnetArmResourceId $subnet_arm_resource_id @additionalParameters
    } else {
        Restore-MySqlServer -CustomerSubscriptionId $source_server.SubscriptionId -CustomerResourceGroup $source_server.ResourceGroup -SourceServerName $source_server.ServerName -TargetServerName "$(${source_server}.ServerName)-dry-run" -RestoreToTime $restore_to_time -SubnetArmResourceId $subnet_arm_resource_id -PrivateDnsZoneArmResourceId $zone_arm_resource_id @additionalParameters
    }
}

function YOJ-FlexServerPITRRealRun {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ServerName,

        [Parameter(Mandatory=$false)]
        [string]$RestoreToTime
    )

    $restore_to_time = $RestoreToTime

    # Step 1
    $queryResult = Query-MySqlControlStore "Select
        tserver.state,
        tserver.create_time,
        (case when trs.standby_count > 0 then 1 else 0 end) AS ha_enabled,
        (case when JSON_VALUE(tserver.entity_extension_data, '$.IsAutoMigratedFromSingleServer') = 'true' then 1 else 0 end) AS auto_migrated,
        tserver.replication_role,
        tserver.server_name,
        tserver.server_type,
        tserver.server_version,
        tserver.server_sku,
        tserver.is_vnet_injected,
        (case when trs.is_private_endpoint_enabled = 'true' then 'true' else 'false' end) AS is_private_endpoint_enabled,
        tserver.storage_limit_in_mb,
        tserver.storage_iops,
        auto_scale_iops=trs.paid_iops_enabled,
        tserver.autogrow,
        data_storage_account=tsa.account_name,
        tserver.customer_subscription_id,
        tserver.customer_resource_group_name,
        tserver.orcas_instance_id,
        tserver.replication_set_id,
        tserver.byok_enabled,
        tserver.geo_redundant_backup_enabled,
        trs.log_on_disk_enabled,
        tos.azure_os_name,
        msft_subscription_id = trg.subscription_id,
        msft_resource_group_name = trg.resource_group_name
    FROM dbo.entity_orcas_servers as tserver
    LEFT JOIN dbo.entity_azure_virtual_machines AS tvm ON tserver.orcas_instance_id = tvm.orcas_instance_id
    LEFT JOIN dbo.entity_azure_os as tos on tos.id = tvm.azure_os_entity_id
    LEFT JOIN dbo.entity_azure_resource_groups AS trg ON tvm.resource_group_entity_id = trg.id
    LEFT JOIN dbo.entity_orcas_replication_sets AS trs ON trs.replication_set_id = tserver.replication_set_id
    LEFT OUTER JOIN dbo.entity_azure_storage_account AS tsa ON tserver.orcas_instance_id = tsa.orcas_instance_id
    WHERE (tserver.server_name = '$ServerName')
        AND (tserver.state != 'Tombstoned')
        AND (tsa.account_name is NULL OR tsa.account_name LIKE '%fsdata')
    ORDER BY tserver.create_time ASC;"

    $is_vnet = $queryResult.is_vnet_injected
    $is_private_link = $queryResult.is_private_endpoint_enabled

    # 对 is_vnet 进行判断
    if ($is_vnet -eq $true) {
        Write-Output "VNET"
    } else {
        Write-Output "NOT_VNET"
    }

    # 对 is_private_link 进行判断
    if ($is_private_link -eq $true) {
        Write-Output "PRIVATE_LINK"
        Write-Output "This is a private link server, PITR is not supported."
        return
    } else {
        Write-Output "NOT_PRIVATE_LINK"
    }

    # Step 3
    if ($is_vnet -eq $true) {
        $subnetQueryResult = Query-MySqlControlStore "select 
        concat ('/subscriptions/', vnet.delegated_virtual_network_subscription_id, '/resourceGroups/',vnet.delegated_virtual_network_resource_group, 
        '/providers/Microsoft.Network/virtualNetworks/', vnet.network_name, '/subnets/', sbn.subnet_name) as subnet_arm_resource_id
        from entity_orcas_servers as svr
        join entity_dnc_network_container dnc on svr.orcas_instance_id = dnc.orcas_instance_id
        join entity_delegated_subnet as sbn on sbn.id = dnc.delegated_subnet_entity_id
        join entity_delegated_virtual_network as vnet on vnet.id = sbn.delegated_virtual_network_entity_id
        where svr.server_name = '$ServerName'"
        $subnet_arm_resource_id = $subnetQueryResult.subnet_arm_resource_id
        Write-Output $subnet_arm_resource_id
    }

    # Step 4
    if ($is_vnet -eq $true) {
        $zoneQueryResult = Query-MySqlControlStore "select
        zone.is_customer_private_dns_zone as need_for_restore,
        CONCAT ('/subscriptions/' , convert(nvarchar(50), zone.private_dns_zone_subscription_id)  , '/resourceGroups/' , 
        zone.private_dns_zone_resource_group ,'/providers/Microsoft.Network/privateDnsZones/' , zone.private_dns_zone_name) as zone_arm_resource_id
        from entity_orcas_servers as svr
        join entity_orcas_replication_sets as rs on svr.replication_set_id = rs.replication_set_id
        join entity_azure_dns_record as dns on rs.replication_set_id = dns.orcas_instance_id
        join entity_azure_private_dns_zone as zone on dns.private_dns_zone_entity_id = zone.id
        where svr.server_name = '$ServerName'"
        $need_for_restore = $zoneQueryResult.need_for_restore
        $zone_arm_resource_id = $zoneQueryResult.zone_arm_resource_id
        Write-Output $need_for_restore $zone_arm_resource_id 
    }

    # Step 5
    $source_server = Get-MySqlServer2 -ServerName $ServerName
    Write-Output "Restore to time: $restore_to_time"

    $additionalParameters = @{}
    if ($source_server.ServerEdition -eq "Burstable") {
        $additionalParameters.ServerSku = "Standard_D2ds_v4"
    }

    # Step 6
    $source_server | Remove-MySqlServer

    # Step 7
    do {
        $userInput = Read-Host "Please check XTS this server has been Tombstoned status, if Tombstoned, input yes, then we can continue. (y/n)"
    } while ($userInput -ne "y")



    # Step 8
    if ($is_vnet -eq $false) {
        Restore-MySqlServer -CustomerSubscriptionId $source_server.SubscriptionId -CustomerResourceGroup $source_server.ResourceGroup -SourceServerName $source_server.ServerName -TargetServerName $source_server.ServerName -RestoreToTime $restore_to_time @additionalParameters
    } elseif ($need_for_restore -eq $false) {
        Restore-MySqlServer -CustomerSubscriptionId $source_server.SubscriptionId -CustomerResourceGroup $source_server.ResourceGroup -SourceServerName $source_server.ServerName -TargetServerName $source_server.ServerName -RestoreToTime $restore_to_time -SubnetArmResourceId $subnet_arm_resource_id @additionalParameters
    } else {
        Restore-MySqlServer -CustomerSubscriptionId $source_server.SubscriptionId -CustomerResourceGroup $source_server.ResourceGroup -SourceServerName $source_server.ServerName -TargetServerName $source_server.ServerName -RestoreToTime $restore_to_time -SubnetArmResourceId $subnet_arm_resource_id -PrivateDnsZoneArmResourceId $zone_arm_resource_id @additionalParameters
    }

    # Step 7
    do {
        $userInput = Read-Host "Please check XTS this source server PITR has been ready (y/n)"
    } while ($userInput -ne "y")

    # Step 9
    if ($source_server.ServerEdition -eq "Burstable") {
        Set-MySqlServer -CustomerSubscriptionId $source_server.SubscriptionId -CustomerResourceGroup $source_server.ResourceGroup -ServerName $source_server.ServerName -Sku $source_server.ServerSku -ServerVersion $source_server.ServerVersion -VCores $source_server.VCore -ServerEdition $source_server.ServerEdition -Location $source_server.Location
    }

    # Step 10
    Remove-MySqlServer -SubscriptionId $source_server.SubscriptionId -ResourceGroup $source_server.ResourceGroup -ServerName "$(${source_server}.ServerName)-dry-run"
}

<#
.SYNOPSIS
This function migrates a MySQL server to a flexible server on Azure using REST API.

.DESCRIPTION
The function signs in to an Azure account, acquires an access token, and uses it to call the Azure REST API to migrate a MySQL server to a flexible server.

.PARAMETER IsMoonCakeEnv
Specify the Azure environment. Default is set to Azure Mooncake environment (0). If set to 1, the function will use Azure China Cloud environment.

.PARAMETER SubscriptionId
The ID of your Azure subscription.

.PARAMETER ResourceGroup
The name of the target resource group where the flexible server will be created.

.PARAMETER TargetFlexServerName
The name of the target flexible server that will be created.

.PARAMETER Location
The location where the flexible server will be created.

.PARAMETER SourceSingleServerName
The name of the source single server that will be migrated.

.EXAMPLE
MySQLImportRestAPI -SubscriptionId 2941a09d-7bcf-42fe-91ca-1765f521c829 -ResourceGroup migration-group -SourceSingleServerName yoj-test -TargetFlexServerName yoj-flex-0322 -Location eastus -UserName "adminuser" -Version "8.0.21" -StorageSizeGB 256 -SKUName "Standard_D4ds_v4"

This example migrates the MySQL server 'yoj-test' to a flexible server 'yoj-flex-0322' in the 'eastus' location under the 'migration-group' resource group. The flexible server will be configured with the following parameters:
- Administrator login: 'adminuser'
- MySQL version: '8.0.21'
- Storage size: 256 GB
- SKU: 'Standard_D4ds_v4'
#>
function YOJ-MySQLImportRestAPI {
    param (
        #Specify the Azure environment (Default is set to Azure Mooncake environment)
        $IsMoonCakeEnv = 0,

        #Specify the subscription Id
        [Parameter(Mandatory=$true)]
        $SubscriptionId ="",

        #Specify the target resource group name
        [Parameter(Mandatory=$true)]
        $ResourceGroup = "",

        #Specify the target flexible server name
        [Parameter(Mandatory=$true)]
        $TargetFlexServerName = "",

        #Specify the location
        [Parameter(Mandatory=$true)]
        $Location = "",

        #Specify the source single server name
        [Parameter(Mandatory=$true)]
        $SourceSingleServerName = "",

        #Specify the administrator login
        [Parameter(Mandatory=$false)]
        [string]$UserName = "yoj",

        #Specify the administrator password
        [Parameter(Mandatory=$false)]
        [string]$Password = "Pwd",

        #Specify the MySQL version
        [ValidateSet("5.7", "8.0.21")]
        [string]$Version = "8.0.21",

        #Specify the storage size in GB
        [Parameter(Mandatory=$false)]
        [int]$StorageSizeGB = 128,

        #Specify the SKU name
        [Parameter(Mandatory=$false)]
        [string]$SKUName = "Standard_D2ds_v4",

        #Specify the online/offline  OnlineMigrate
        [ValidateSet("Migrate", "OnlineMigrate")]
        [string]$Mode = "Migrate"
    )

    # Import the module
    Import-Module Az.Accounts

    # Depending on the environment, set the API URL and environment name
    if ($IsMoonCakeEnv -eq 1) 
    {
        $apiUrl = "https://management.chinacloudapi.cn:443/subscriptions/"+$SubscriptionId+"/resourceGroups/"+$ResourceGroup+"/providers/Microsoft.DBforMySQL/flexibleServers/"+$TargetFlexServerName+"?api-version=2022-06-01-privatepreview"
        $env="AzureChinaCloud"
    }
    else
    {
        $apiUrl = "https://management.azure.com/subscriptions/"+$SubscriptionId+"/resourceGroups/"+$ResourceGroup+"/providers/Microsoft.DBforMySQL/flexibleServers/"+$TargetFlexServerName+"?api-version=2022-06-01-privatepreview"
        $env="AzureCloud"
    }

    # Ask the user to sign in and get the token
    $azureAccount = Connect-AzAccount -Environment $env -DeviceCode
    Set-AzContext -Subscription $SubscriptionId
    $context = Get-AzContext 
    $profile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($profile)
    $token = $profileClient.AcquireAccessToken($context.Subscription.TenantId)

    # Define the headers for the API request
    $headers = @{
        'Authorization' = "Bearer $($token.AccessToken)"
        'Content-Type'  = 'application/json'
    }

    # Define the payload for the API request
    $postbody = @{
        "sku" = @{
            "name" = $SKUName
            "tier" = "GeneralPurpose"
        }
        "properties" = @{
            "administratorLogin" = $UserName
            "administratorLoginPassword" = $Password
            "storage" = @{
                "storageSizeGB" = $StorageSizeGB
                "autoGrow" = "Enabled"
            }
            "version" = $Version
            "createMode" = $Mode
            "sourceServerResourceId" = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.DBforMySQL/servers/$SourceSingleServerName"
            "backup" = @{
                "backupRetentionDays" = 7
                "geoRedundantBackup" = "Enabled"
            }
        }
        "location" = $Location
        "type" = "Microsoft.DBforMySQL/flexibleServers"
    }

    # Convert the payload to JSON
    [string]$payload= $postbody | ConvertTo-Json -Depth 10

    # Print the payload
    Write-Host $payload

    # Invoke the API
    $response = Invoke-RestMethod -Uri $apiUrl -Method Put  -Body $payload -Headers $headers

    # Output the response
    $response
}

<#
.SYNOPSIS
This function migrates a MySQL server from one location to another using REST API.

.DESCRIPTION
The function YOJ-OneBox-MySQLImportRestAPI takes in source and destination server names as mandatory parameters.
It also accepts optional parameters such as UserName for AdministratorLogin, MySQL Version, StorageSizeGB, and SKUName.
If the optional parameters are not provided, the function will use default values.

.PARAMETER SrcServer
The name of the source server. This parameter is mandatory.

.PARAMETER DstServer
The name of the destination server. This parameter is mandatory.

.PARAMETER UserName
The username for AdministratorLogin. If not provided, the default value 'yoj' will be used.

.PARAMETER Version
The version of MySQL. It only supports '5.7' or '8.0.21'. If not provided, '8.0.21' will be used as the default.

.PARAMETER StorageSizeGB
The storage size in GB. If not provided, the default value '128' will be used.

.PARAMETER SKUName
The SKU name. If not provided, the default value 'Standard_D2ds_v4' will be used.

.EXAMPLE
YOJ-OneBox-MySQLImportRestAPI -SrcServer "sourceServerName" -DstServer "destinationServerName"

This example shows how to call the function with the mandatory parameters.

.EXAMPLE
YOJ-OneBox-MySQLImportRestAPI -SrcServer "sourceServerName" -DstServer "destinationServerName" -UserName "admin" -Version "5.7" -StorageSizeGB 128 -SKUName "Standard_D2ds_v4"
YOJ-OneBox-MySQLImportRestAPI -SrcServer "sourceServerName" -DstServer "destinationServerName" -UserName "admin" -Version "8.0.21" -StorageSizeGB 128 -SKUName "Standard_D2ds_v4"

This example shows how to call the function with both mandatory and optional parameters.
#>
function YOJ-OneBox-MySQLImportRestAPI {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SrcServer,

        [Parameter(Mandatory=$true)]
        [string]$DstServer,

        [Parameter(Mandatory=$false)]
        [string]$UserName = "yoj",

        [ValidateSet("5.7", "8.0.21")]
        [string]$Version = "8.0.21",

        [Parameter(Mandatory=$false)]
        [int]$StorageSizeGB = 128,

        [Parameter(Mandatory=$false)]
        [string]$SKUName = "Standard_D2ds_v4"
    )

    # Check if DstServer parameter value is provided
    if(-not $DstServer) {
        throw "Please provide a valid DstServer parameter value."
    }

    # Check if SrcServer parameter value is provided
    if(-not $SrcServer) {
        throw "Please provide a valid SrcServer parameter value."
    }

    # Default certificate thumbprint
    $script:DefaultRpCertThumbprint = "877495169fa05b9d8639a0ebc42022338f7d2324"

    # Construct the URI for the REST API request
    $uri = "https://localhost:8363/modules/ArmMySQL/subscriptions/ffffffff-ffff-ffff-ffff-ffffffffffff/resourceGroups/yoj-group/providers/Microsoft.DBforMySQL/flexibleServers/" + $DstServer + "?api-version=2021-05-01"

    # Print the source and destination server names
    write-host "Source server: $SrcServer"
    write-host "Destination server: $DstServer"

    # Construct the model for the REST API request body
    $model = @{
        Sku = @{
            Name = $SKUName;
            Tier = "GeneralPurpose"
        };
        Properties = @{
            AdministratorLogin = $UserName;
            Storage = @{
                StorageSizeGB = $StorageSizeGB;
                Iops = 150;
                AutoGrow = "Disabled"
            };
            Version = $Version;
            CreateMode =  "Migrate";
            SourceServerResourceId = "/subscriptions/ffffffff-ffff-ffff-ffff-ffffffffffff/resourceGroups/yoj-group/providers/Microsoft.DBforMySQL/servers/$SrcServer";
            Network = @{
                PublicNetworkAccess = "Enabled"
            };
            Backup = @{
                BackupRetentionDays = 7;
                GeoRedundantBackup = "Disabled"
            }
        };
        Location = "southcentralus";
        Tags = @{
            ElasticServer = "1";
            MigrationSourceSingleServerResourceId = "/subscriptions/ffffffff-ffff-ffff-ffff-ffffffffffff/resourceGroups/yoj-group/providers/Microsoft.DBforMySQL/servers/$SrcServer"
        }
    }

    # Convert the model to JSON format
    $body = ConvertTo-Json $model

    # Invoke the REST API request
    Invoke-WebRequestInsecure -Method Put -Uri $uri -Body $body -ContentType "application/json" -CertificateThumbprint $DefaultRpCertThumbprint
}

function YOJ-OneBox-Init {
    Select-SqlAzureEnvironment Local
    Select-SqlAzureCluster OrcasBreadthOnebox
    Set-MySqlFeatureSwitch -FeatureSwitchName IsSterling2MeruMigrationEnabled -FeatureSwitchValue ON -ServerType MySQL -SubscriptionId ffffffff-ffff-ffff-ffff-ffffffffffff -ResourceGroup * -ServerName * -FeatureSwitchDescription "Enabling for migration apis testing"


    Set-MySqlResourceProviderConfiguration -ConfigName SkuMapping -ServerType MySQL -ConfigDescription "The sku mapping for Single to Flexible migration maintenance window" -ConfigValue '{"Basic":{1:"Standard_B1ms",2:"Standard_B2ms"},"GeneralPurpose":{2:"Standard_D2s_v3",4:"Standard_D4s_v3",8:"Standard_D8s_v3",16:"Standard_D16s_v3",32:"Standard_D32s_v3",64:"Standard_D64s_v4"},"MemoryOptimized":{2:"Standard_E2s_v3",4:"Standard_E4s_v3",8:"Standard_E8s_v3",16:"Standard_E16s_v3",32:"Standard_E32s_v3"}}'
    Set-MySqlResourceProviderConfiguration -ConfigName MigrationStartHour -ServerType MySQL -ConfigDescription "Migration Start Hour" -ConfigValue 1
    Set-MySqlResourceProviderConfiguration -ConfigName MigrationEndHour -ServerType MySQL -ConfigDescription "Migration End Hour" -ConfigValue 7
    Set-MySqlResourceProviderConfiguration -ConfigName MigrationNotificationEventIdFS -ServerType MySQL -ConfigDescription "Migration Notification Event Id" -ConfigValue 8L6S-388
    Set-MySqlFeatureSwitch -FeatureSwitchName IsSingle2FlexMigrationRePlatformEnabled -FeatureSwitchValue ON -ServerType MySQL
    Set-MySqlFeatureSwitch -FeatureSwitchName IsSterling2MeruMigrationEnabled -FeatureSwitchValue ON -ServerType MySQL
    Set-MySqlFeatureSwitch -FeatureSwitchName IsSingle2FlexMigrationRePlatformEnabled -FeatureSwitchValue ON -ServerType MySQL
    Set-MySqlResourceProviderConfiguration -ConfigName SterlingCaCert -ServerType MySQL -ConfigDescription "The Sterling Combined CA Cert" -ConfigValue 'LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURkekNDQWwrZ0F3SUJBZ0lFQWdBQXVUQU5CZ2txaGtpRzl3MEJBUVVGQURCYU1Rc3dDUVlEVlFRR0V3SkoKUlRFU01CQUdBMVVFQ2hNSlFtRnNkR2x0YjNKbE1STXdFUVlEVlFRTEV3cERlV0psY2xSeWRYTjBNU0l3SUFZRApWUVFERXhsQ1lXeDBhVzF2Y21VZ1EzbGlaWEpVY25WemRDQlNiMjkwTUI0WERUQXdNRFV4TWpFNE5EWXdNRm9YCkRUSTFNRFV4TWpJek5Ua3dNRm93V2pFTE1Ba0dBMVVFQmhNQ1NVVXhFakFRQmdOVkJBb1RDVUpoYkhScGJXOXkKWlRFVE1CRUdBMVVFQ3hNS1EzbGlaWEpVY25WemRERWlNQ0FHQTFVRUF4TVpRbUZzZEdsdGIzSmxJRU41WW1WeQpWSEoxYzNRZ1VtOXZkRENDQVNJd0RRWUpLb1pJaHZjTkFRRUJCUUFEZ2dFUEFEQ0NBUW9DZ2dFQkFLTUV1eUtyCm1EMVg2Q1p5bXJWNTFDbmk0ZWlWZ0xHdzQxdU9LeW1hWk4raFhlMndDUVZ0MnlndXptS2lZdjYwaU5vUzZ6anIKSVozQVFTc0JVbnVJZDlNY2o4ZTZ1WWkxYWdubmMrZ1JRS2ZSek1waWpTM2xqd3VtVU5Lb1VNTW82dldySlllSwptcFljcVdlNFB3elY5L2xTRXkvQ0c5VndjUENQd0JMS0JzdWE0ZG5LTTNwMzF2anN1ZkZvUkVKSUU5TEF3cVN1ClhtRCt0cVlGL0xUZEIxa0MxRmtZbUdQMXBXUGdrQXg5WGJJR2V2T0Y2dXZVQTY1ZWhENWYveFh0YWJ6NU9UWnkKZGM5M1VrM3p5WkFzdVQzbHlTTlRQeDhrbUNGY0I1a3B2Y1k2N09kdWhqcHJsM1JqTTcxb0dESHdlSTEydi95ZQpqbDBxaHFkTmtOd25HamtDQXdFQUFhTkZNRU13SFFZRFZSME9CQllFRk9XZFdUQ0NSMWpNclBvSVZEYUdlenExCkJFM3dNQklHQTFVZEV3RUIvd1FJTUFZQkFmOENBUU13RGdZRFZSMFBBUUgvQkFRREFnRUdNQTBHQ1NxR1NJYjMKRFFFQkJRVUFBNElCQVFDRkRGMk81RzlSYUVJRm9OMjdUeWNsaEFPOTkyVDlMZGN3NDZRUUYrdmFLU20yZVQ5Mgo5aGtUSTdnUUN2bFlwTlJoY0wwRVlXb1NpaGZWQ3IzRnZEQjgxdWtNSlkyR1FFL3N6S04rT01ZM0VVL3QzV2d4CmprelNzd0YwN3I1MVhnZElHbjl3L3haY2hNQjVoYmdGL1grK1pSR2pEOEFDdFBoU056a0UxYWt4ZWhpL29DcjAKRXBuM28wV0M0enhlOVoyZXRjaWVmQzdJcEo1T0NCUkxiZjF3YldzYVk3MWs1aCszenZEeW55NjdHN2Z5VUloegprc0xpNHhhTm1qSUNxNDRZM2VrUUVlNStOYXVRcno0d2xIclFNejJuWlEvMS9JNmVZczlIUkN3Qlhic2R0VExTClI5STRMdEQrZ2R3eWFoNjE3anpWL09lQkhSbkRKRUxxWXptcAotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCi0tLS0tQkVHSU4gQ0VSVElGSUNBVEUtLS0tLQpNSUlEampDQ0FuYWdBd0lCQWdJUUF6cng1cWNScWFDN0tHU3hIUW42NVRBTkJna3Foa2lHOXcwQkFRc0ZBREJoCk1Rc3dDUVlEVlFRR0V3SlZVekVWTUJNR0ExVUVDaE1NUkdsbmFVTmxjblFnU1c1ak1Sa3dGd1lEVlFRTEV4QjMKZDNjdVpHbG5hV05sY25RdVkyOXRNU0F3SGdZRFZRUURFeGRFYVdkcFEyVnlkQ0JIYkc5aVlXd2dVbTl2ZENCSApNakFlRncweE16QTRNREV4TWpBd01EQmFGdzB6T0RBeE1UVXhNakF3TURCYU1HRXhDekFKQmdOVkJBWVRBbFZUCk1SVXdFd1lEVlFRS0V3eEVhV2RwUTJWeWRDQkpibU14R1RBWEJnTlZCQXNURUhkM2R5NWthV2RwWTJWeWRDNWoKYjIweElEQWVCZ05WQkFNVEYwUnBaMmxEWlhKMElFZHNiMkpoYkNCU2IyOTBJRWN5TUlJQklqQU5CZ2txaGtpRwo5dzBCQVFFRkFBT0NBUThBTUlJQkNnS0NBUUVBdXpmTk5OeDdhOG15YUpDdFNuWC9Scm9oQ2dpTjlSbFV5ZnVJCjIvT3U4anFKa1R4NjVxc0dHbXZQckMzb1hna2tSTHBpbW43V282aCs0RlIxSUFXc1VMZWNZeHBzTU56YUh4bXgKMXg3ZS9kZmd5NVNETjY3c0gwTk8zWHNzMHIwdXBTL2txYml0T3RTWnBMWWw2WnRyQUdDU1lQOVBJVWtZOTJlUQpxMkVHbkkveXV1bTA2Wkl5YTdYelYraGRHODJNSGF1VkJKVko4elV0bHVOSmJkMTM0L3RKUzdTc1ZRZXBqNVd6CnRDTzdURzFGOFBhcHNwVXd0UDFNVll3blNsY1VmSUtkelhPUzB4WktCZ3lNVU5HUEhnbStGNkhtSWNyOWcrVVEKdklPbENzUm5LUFp6RkJROVJuYkRoeFNKSVRSTnJ3OUZES1pKb2JxN25NV3hNNE1waFFJREFRQUJvMEl3UURBUApCZ05WSFJNQkFmOEVCVEFEQVFIL01BNEdBMVVkRHdFQi93UUVBd0lCaGpBZEJnTlZIUTRFRmdRVVRpSlVJQmlWCjV1TnU1Zy82K3JrUzdRWVhqemt3RFFZSktvWklodmNOQVFFTEJRQURnZ0VCQUdCbktKUnZEa2hqNnpIZDZtY1kKMVlsOVBNV0xTbi9wdnRzckY5K3dYM04zS2pJVE9ZRm5Rb1FqOGtWbk5leUl2L2lQc0dFTU5LU3VJRXlFeHR2NApOZUYyMmQrbVFydkhSQWlHZnpaMEpGcmFiQTBVV1RXOThrbmR0aC9Kc3cxSEtqMlpMN3RjdTdYVUlPR1pYMU5HCkZkdG9tL0R6TU5VK01lS05oSjdqaXRyYWxqNDFFNlZmOFBsd1VIQkhRUkZYR1U3QWo2NEd4SlVURnk4YkpaOTEKOHJHT21hRnZFN0ZCY2Y2SUtzaFBFQ0JWMS9NVVJlWGdSUFRxaDVVeWt3NytVMGI2TEozL2l5SzVTOWtKUmFUZQpwTGlhV04wYmZWS2ZqbGxEaUlHa25pYlZiNjNkRGNZM2ZlMERraHZsZDE5MjdqeU54RjFXVzZMWlptNnpOVGZsCk1yWT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQ=='
}

<#
.SYNOPSIS
This function creates a new PFS server.

.DESCRIPTION
The function YOJ-OneBox-PFS-SingleServerTest creates a new PFS server with given parameters. 
If parameters are not provided, the function will use default values.

.PARAMETER AdminPassword
The password for the admin user. If not provided, the default value 'fedora12@' will be used.

.PARAMETER AdminUser
The admin username. If not provided, the default value 'yoj' will be used.

.PARAMETER ResourceGroup
The resource group. If not provided, the default value 'yoj-group' will be used.

.PARAMETER ServerName
The server name. If not provided, the default value 'yoj-test-migration' will be used.

.PARAMETER ServerType
The server type. If not provided, the default value 'MySQL.Server.PAL' will be used.

.PARAMETER ServiceLevelObjective
The service level objective. If not provided, the default value 'MYSQL_GP_Gen5_2' will be used.

.PARAMETER Storage
The storage size in GB. If not provided, the default value '128' will be used.

.PARAMETER SubscriptionId
The subscription Id. If not provided, the default value 'ffffffff-ffff-ffff-ffff-ffffffffffff' will be used.

.PARAMETER Version
The version of MySQL. If not provided, the default value '5.7' will be used.

.PARAMETER PrivateFeature
The private feature. If not provided, the default value 'PFS' will be used.

.EXAMPLE
YOJ-OneBox-PFS-SingleServerTest -AdminPassword "password" -AdminUser "user" -ResourceGroup "group" -ServerName "server" -ServerType "type" -ServiceLevelObjective "objective" -Storage 128 -SubscriptionId "id" -Version "version" -PrivateFeature "feature"

This example shows how to call the function with both mandatory and optional parameters.
#>
function YOJ-OneBox-SingleServerCreate {
    param(
        [Parameter(Mandatory=$false)]
        [string]$AdminPassword = "fedora12@",
        
        [Parameter(Mandatory=$false)]
        [string]$AdminUser = "yoj",
        
        [Parameter(Mandatory=$false)]
        [string]$ResourceGroup = "yoj-group",
        
        [Parameter(Mandatory=$false)]
        [string]$ServerName,
        
        [Parameter(Mandatory=$false)]
        [string]$ServerType = "MySQL.Server.PAL",
        
        [Parameter(Mandatory=$false)]
        [string]$ServiceLevelObjective = "MYSQL_GP_Gen5_2",
        
        [Parameter(Mandatory=$false)]
        [int]$Storage = 128,
        
        [Parameter(Mandatory=$false)]
        [string]$SubscriptionId = "ffffffff-ffff-ffff-ffff-ffffffffffff",
        
        [Parameter(Mandatory=$false)]
        [string]$Version = "5.7",
        
        [Parameter(Mandatory=$false)]
        [string]$PrivateFeature = "PFS"
    )
    
    Select-SqlAzureEnvironment Test
    Select-SqlAzureCluster Wasd-test-osshf-southcentralus1-a
    New-ElasticServer2 -AdminPassword $AdminPassword -AdminUser $AdminUser -ResourceGroup $ResourceGroup -ServerName $ServerName -ServerType $ServerType -ServiceLevelObjective $ServiceLevelObjective -Storage $Storage -SubscriptionId $SubscriptionId -Version $Version -PrivateFeature $PrivateFeature
}

function YOJ-ExtractAndExecute {
    param (
        [string]$inputString
    )
 
    $regions = @(
        "australiacentral",
        "australiacentral2",
        "australiaeast",
        "australiasoutheast",
        "austriaeast",
        "belgiumcentral",
        "brazilsouth",
        "brazilsoutheast",
        "canadacentral",
        "canadaeast",
        "centralindia",
        "centralus",
        "centraluseuap",
        "chilecentral",
        "denmarkeast",
        "eastasia",
        "eastus",
        "eastus2",
        "eastus2euap",
        "eastusslv",
        "eastusstg",
        "francecentral",
        "francesouth",
        "germanynorth",
        "germanywestcentral",
        "indiasouthcentral",
        "indonesiacentral",
        "israelcentral",
        "israelnorthwest",
        "italynorth",
        "japaneast",
        "japanwest",
        "jioindiacentral",
        "jioindiawest",
        "koreacentral",
        "koreasouth",
        "malaysiasouth",
        "malaysiawest",
        "mexicocentral",
        "newzealandnorth",
        "northcentralus",
        "northeurope",
        "norwayeast",
        "norwaywest",
        "polandcentral",
        "qatarcentral",
        "southafricanorth",
        "southafricawest",
        "southcentralus",
        "southcentralusstg",
        "southeastasia",
        "southeastus",
        "southindia",
        "spaincentral",
        "swedencentral",
        "swedensouth",
        "switzerlandnorth",
        "switzerlandwest",
        "taiwannorth",
        "taiwannorthwest",
        "uaecentral",
        "uaenorth",
        "uknorth",
        "uksouth",
        "uksouth2",
        "ukwest",
        "westcentralus",
        "westeurope",
        "westindia",
        "westus",
        "westus2",
        "westus3"
    )
 
    if ($inputString -match "elastic_server_id: ([a-z0-9-]+)") {
        $elastic_server_id = $Matches[1]
    }
 
    if ($inputString -match "in ([A-Za-z0-9-]+) for") {
        $region = $Matches[1].ToLower()
    }
 
    if ($inputString -match "server: ([a-z0-9-]+)") {
        $server_name = $Matches[1]
    }
 
    Write-Host ${elastic_server_id}
    Write-Host ${server_name}
    Write-Host ${region}
 
    # Select-SqlAzureEnvironment Prod
    if ($region -match '\d$') {
        Select-SqlAzureCluster "Wasd-prod-${region}-a"
    } else {
        Select-SqlAzureCluster "Wasd-prod-${region}1-a"
    }
    Query-MySqlControlStore "Select * from entity_migration_schedules where elastic_server_id='${elastic_server_id}'"
}

function YOJ-SingleServerCommands {
    param (
        [string]$ServerName
    )

    # 获取服务器信息
    # $info = Get-ElasticServerInstance2 -ServerName $ServerName -IncludeFabricProperties -State *

    $info = Get-ElasticServerInstance2 -ServerName $ServerName -State *


    # 输出服务器信息
    $info

    # 定义命令列表及其功能
    $commands = @(
        @{ Command = "Select-SqlAzureEnvironment Prod"; Description = "Select Environment" },
        @{ Command = "Select-SqlAzureCluster Wasd-prod-uaenorth1-a-CR1"; Description = "Select Cluster" },
        @{ Command = "Get-JitAccess -WorkitemSource IcM -Justification `"Reason for request`" -WorkitemId IcMID"; Description = "Get Jit Access" },
        @{ Command = "Get-FabricNode -NodeName $($info.FabricNodeName) -NodeClusterName $($info.TenantRingName) | \\arsing\shared\New-JITRequest.ps1"; Description = "New JIT Request" },
        @{ Command = "Start-Process `"https://azurewatson.cloudapp.net/?ClusterName~$($info.TenantRingName)&AppName~$($info.PhysicalInstanceName)`""; Description = "AW dumps" },
        @{ Command = "Get-FabricNode -NodeName $($info.FabricNodeName) -NodeClusterName $($info.TenantRingName) | Dump-Process -ProcessName Dkmon.exe -ApplicationNameUri $($info.FabricApplicationUri)"; Description = "Dump process" },
        @{ Command = "Get-FabricNode -NodeName $($info.FabricNodeName) -NodeClusterName $($info.TenantRingName) | Kill-Process -ProcessName DkMon.exe -ApplicationNameUri $($info.FabricApplicationUri)"; Description = "Kill process" },
        @{ Command = "Get-FabricNode -NodeName $($info.FabricNodeName) -NodeClusterName $($info.TenantRingName) | Kill-Process -ProcessName MySqlInstanceAgentRunnerHost.exe -ApplicationNameUri $($info.FabricApplicationUri)"; Description = "Kill instance agent" },
        @{ Command = "Get-FabricNode -NodeName $($info.FabricNodeName) -NodeClusterName $($info.TenantRingName) | Kill-Process -ProcessName MDSAgentLauncherHost.exe -ApplicationNameUri $($info.FabricApplicationUri)"; Description = "Kill MDS agent" },
        @{ Command = "Get-FabricNode -NodeName $($info.FabricNodeName) -NodeClusterName $($info.TenantRingName) | Kill-Process -ProcessName SqlSatelliteRunnerHost.exe -ApplicationNameUri $($info.FabricApplicationUri)"; Description = "Kill SAT runner" },
        @{ Command = "Restart-ElasticServer -SubscriptionId $($info.SubscriptionId) -ResourceGroup $($info.ResourceGroup) -ServerName $($info.ServerName) -ServerType $($info.ServerType)"; Description = "Restart server" },
        @{ Command = "New-ElasticServerFirewallRule -StartIpAddress `"0.0.0.0`" -EndIpAddress `"0.0.0.0`" -SubscriptionId $($info.SubscriptionId) -ResourceGroup $($info.ResourceGroup) -ServerName $($info.ServerName) -ServerType $($info.ServerType)"; Description = "Add Firewall Rule" },
        @{ Command = "Remove-ElasticServerFirewallRule -SubscriptionId $($info.SubscriptionId) -ResourceGroup $($info.ResourceGroup) -ServerName $($info.ServerName) -ServerType $($info.ServerType)"; Description = "Remove Firewall Rule" },
        @{ Command = "Get-ElasticServerConfig -SubscriptionId $($info.SubscriptionId) -ResourceGroup $($info.ResourceGroup) -ServerName $($info.ServerName) -ServerType $($info.ServerType) -ConfigName input_config_name"; Description = "Get Configuration" },
        @{ Command = "Set-ElasticServerConfig -SubscriptionId $($info.SubscriptionId) -ResourceGroup $($info.ResourceGroup) -ServerName $($info.ServerName) -ServerType $($info.ServerType) -ConfigName input_config_name -ConfigValue input_config_value -ConfigType UserConfiguration"; Description = "Set Configuration" },
        @{ Command = "Get-ElasticServerSasToken -SubscriptionId $($info.SubscriptionId) -ResourceGroup $($info.ResourceGroup) -ServerName $($info.ServerName) -ServerType $($info.ServerType) -Minutes 30 -Backup `$false -Permissions rl -StorageType FileShare"; Description = "Get SAS key" },
        @{ Command = "Get-CreateElasticServerBackup -ServerName $($info.ServerName) -SubscriptionId $($info.SubscriptionId) -ServerType $($info.ServerType) -ResourceGroup $($info.ResourceGroup)"; Description = "PG Basic Backup" },
        @{ Command = "Get-FabricNode -NodeName $($info.FabricNodeName) -NodeClusterName $($info.TenantRingName) | Invoke-ElasticServerBackupServiceAction -ActionType ForceBackup -InstanceName $($info.PhysicalInstanceName) -BackupType Full -ElasticServerId $($info.ElasticServerId)"; Description = "Take backup" },
        @{ Command = "Restore-ElasticServer2 -SubscriptionId $($info.SubscriptionId) -SourceResourceGroup $($info.ResourceGroup) -SourceServerName $($info.ServerName) -ServerType $($info.ServerType) -TargetResourceGroup $($info.ResourceGroup) -TargetServerName `"input_new_restored_name`""; Description = "Restore server" },
        @{ Command = "New-ElasticServerReplica2 -SubscriptionId $($info.SubscriptionId) -PrimayResourceGroup $($info.ResourceGroup) -PrimaryServerName $($info.ServerName) -ServerName `"input_new_replica_name`" -ServerType $($info.ServerType)"; Description = "Create read replica" },
        @{ Command = "Write-Warning `"The following commands are for MySQL only.`""; Description = "Start of MySQL Only" },
        @{ Command = "Invoke-ElasticServerDbCommand -SubscriptionId $($info.SubscriptionId) -ResourceGroup $($info.ResourceGroup) -ServerName $($info.ServerName) -ServerType $($info.ServerType) -command `"input_MySQL_command`""; Description = "Invoke Command" },
        @{ Command = "Invoke-ElasticServerDbCommand -SubscriptionId $($info.SubscriptionId) -ResourceGroup $($info.ResourceGroup) -ServerName $($info.ServerName) -ServerType $($info.ServerType) -command `"show_binary_logs`""; Description = "Show binary logs" },
        @{ Command = "Invoke-ElasticServerDbCommand -SubscriptionId $($info.SubscriptionId) -ResourceGroup $($info.ResourceGroup) -ServerName $($info.ServerName) -ServerType $($info.ServerType) -command `"show_master_status`""; Description = "Show master status" },
        @{ Command = "Invoke-ElasticServerDbCommand -SubscriptionId $($info.SubscriptionId) -ResourceGroup $($info.ResourceGroup) -ServerName $($info.ServerName) -ServerType $($info.ServerType) -command `"show_slave_status`""; Description = "Show slave status" },
        @{ Command = "Invoke-ElasticServerDbCommand -SubscriptionId $($info.SubscriptionId) -ResourceGroup $($info.ResourceGroup) -ServerName $($info.ServerName) -ServerType $($info.ServerType) -command `"show_plugins`""; Description = "Show plugins" },
        @{ Command = "Invoke-ElasticServerDbCommand -SubscriptionId $($info.SubscriptionId) -ResourceGroup $($info.ResourceGroup) -ServerName $($info.ServerName) -ServerType $($info.ServerType) -command `"start_slave`""; Description = "Start Slave" },
        @{ Command = "Invoke-ElasticServerDbCommand -SubscriptionId $($info.SubscriptionId) -ResourceGroup $($info.ResourceGroup) -ServerName $($info.ServerName) -ServerType $($info.ServerType) -command `"stop_slave`""; Description = "Stop Slave" },
        @{ Command = "Invoke-ElasticServerDbCommand -SubscriptionId $($info.SubscriptionId) -ResourceGroup $($info.ResourceGroup) -ServerName $($info.ServerName) -ServerType $($info.ServerType) -command `"show_processlist`""; Description = "Show processlist" },
        @{ Command = "Set-ElasticServerConfig -SubscriptionId $($info.SubscriptionId) -ResourceGroup $($info.ResourceGroup) -ServerName $($info.ServerName) -ServerType $($info.ServerType) -ConfigName log_bin -ConfigValue ON -ConfigType UserConfiguration"; Description = "Turn on bin log" },
        @{ Command = "Set-ElasticServerConfig -SubscriptionId $($info.SubscriptionId) -ResourceGroup $($info.ResourceGroup) -ServerName $($info.ServerName) -ServerType $($info.ServerType) -ConfigName audit_log_enabled -ConfigValue ON -ConfigType UserConfiguration"; Description = "Turn on audit log" },
        @{ Command = "Set-ElasticServerConfig -SubscriptionId $($info.SubscriptionId) -ResourceGroup $($info.ResourceGroup) -ServerName $($info.ServerName) -ServerType $($info.ServerType) -ConfigName audit_log_events -ConfigValue `"GENERAL,CONNECTION`" -ConfigType UserConfiguration"; Description = "Set audit events" },
        @{ Command = "Set-ElasticServerConfig -SubscriptionId $($info.SubscriptionId) -ResourceGroup $($info.ResourceGroup) -ServerName $($info.ServerName) -ServerType $($info.ServerType) -ConfigName audit_log_exclude_users -ConfigValue azure_superuser -ConfigType UserConfiguration"; Description = "Set audit excl user" },
        @{ Command = "Set-ElasticServerConfig -SubscriptionId $($info.SubscriptionId) -ResourceGroup $($info.ResourceGroup) -ServerName $($info.ServerName) -ServerType $($info.ServerType) -ConfigName slave_parallel_workers -ConfigValue 0 -ConfigType UserConfiguration"; Description = "Turn off parallel replication" },
        @{ Command = "Write-Output `"The commands above are for MySQL only.`""; Description = "End of MySQL Only" },
        @{ Command = "Write-Warning `"Please consult team orcasql@service.microsoft.com before using the commands below`""; Description = "WARNING!" },
        @{ Command = "Get-FabricNode -NodeName $($info.FabricNodeName) -NodeClusterName $($info.TenantRingName) | Remove-Replica -AppName $($info.PhysicalInstanceName) -PartitionId $($info.FabricPartitionId)"; Description = "Remove replica" },
        @{ Command = "Get-FabricNode -NodeName $($info.FabricNodeName) -NodeClusterName $($info.TenantRingName) | Move-Replica -ApplicationUri $($info.FabricApplicationUri) -ServiceUri $($info.FabricApplicationUri)/$($info.ServerType)/$($info.PhysicalInstanceName)"; Description = "Move Replica" },
        @{ Command = "# Warning: This operation may cause data loss, please proceed with caution"; Description = "Delete database files" },
        @{ Command = "=============================================================================================================================================="; Description = "" },
        @{ Command = "Remove-ElasticServer -SubscriptionId $($info.SubscriptionId) -ResourceGroup $($info.ResourceGroup) -ServerName $($info.ServerName) -ServerType $($info.ServerType)"; Description = "Remove elastic server" },
        @{ Command = "Raise-SqlAzureFsmEvent -TableName `"tbl_elastic_servers`" -Keys @('$($info.ElasticServerId)') -EventName UpdatePremiumFileShareQuota -EventParameters @(`"<SizeInMB>`") -CabId <Cab ID>"; Description = "Increase PFS storage" },
        @{ Command = "Set-WinfabProperty -FabricClusterName $($info.TenantRingName) -FabricNameUri $($info.FabricApplicationUri) -PropertyName StartPause -PropertyValue ([System.Text.Encoding]::Unicode.GetBytes(`"BeforeLaunch`"))"; Description = "Pause" },
        @{ Command = "Remove-WinfabProperty -FabricClusterName $($info.TenantRingName) -FabricNameUri $($info.FabricApplicationUri) -PropertyName StartPause"; Description = "Unpause" },
        @{ Command = "Set-ApplicationDeploymentPinningFlag -FabricApplicationUri $($info.FabricApplicationUri) -Action Pin -Justification `"<JUSTIFICATION>`""; Description = "Pin" },
        @{ Command = "Set-ApplicationDeploymentPinningFlag -FabricApplicationUri $($info.FabricApplicationUri) -Action UnPin"; Description = "UnPin" }
    )

    # 输出命令及其功能
    foreach ($cmd in $commands) {
        Write-Output "$($cmd.Description)`t$($cmd.Command)"
    }
}


function Get-AllRegionJitAccess
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$IcM = "208144943",

        [Parameter(Mandatory=$true)]
        [string]$Reason = "jit to open featureswitch"
    )

    New-JITRequest -env product -src IcM -wid $IcM -Justification "${Reason}" -rtype DstsCtrls -stype SqlAzureCas -ins asiasoutheast.sterling,asiaeast.sterling,australiac.sterling,australiac2.sterling,australiaeast.sterling,australiasoutheast.sterling,brazilse.sterling,brazilsouth.sterling,canadacentral.sterling,canadaeast.sterling,dm3.sterling,egclusters,europenorth.sterling,europewest.sterling,francec.sterling,frances.sterling,germanyn.sterling,germanywc.sterling,indiacentral.sterling,indiasouth.sterling,indiawest.sterling,japaneast.sterling,japanwest.sterling,koreacentral.sterling,koreasouth.sterling,norwaye.sterling,norwayw.sterling,southafrican.sterling,southafricaw.sterling,stageclusters,switzerlandn.sterling,switzerlandw.sterling,uaec.sterling,uaen.sterling,uksouth.sterling,ukwest.sterling,uscentral.sterling,uscentraleuap.sterling,useast.sterling,useast2.sterling,useast2euap.sterling,usnorth.sterling,ussouth.sterling,uswest.sterling,uswest2.sterling,uswest3.sterling,uswestcentral.sterling -AccessLevel PlatformServiceAdministrator -ver 2015-09-07.1.0
}


<#
.SYNOPSIS
Outputs a list of regions for Meru JIT SQL Azure CAS submission.

.DESCRIPTION
The Output-Regions function prints a list of regions that are required when submitting a Meru JIT SQL Azure CAS request. Each region is listed with an index for easy reference.

.EXAMPLE
PS C:\> Output-Regions

This example calls the function to print the list of regions to the console.

.NOTES
This function is useful for quickly referencing the list of regions needed for Meru JIT SQL Azure CAS submissions.
#>
function YOJ-MERUJITSQLAzureCASRegions
{
    $regions = @(
        "asiaeast.sterling",
        "asiasoutheast.sterling",
        "australiac.sterling",
        "australiac2.sterling",
        "australiaeast.sterling",
        "australiaeast1-z.sterling",
        "australiasoutheast.sterling",
        "brazilse.sterling",
        "brazilsouth.sterling",
        "canadacentral.sterling",
        "canadaeast.sterling",
        "chilec.sterling",
        "dm3.sterling",
        "eastus1-z.sterling",
        "eastus2-z.sterling",
        "egclusters",
        "europenorth.sterling",
        "europewest.sterling",
        "eusslv.sterling",
        "francec.sterling",
        "frances.sterling",
        "germanyn.sterling",
        "germanywc.sterling",
        "indiacentral.sterling",
        "indiasouth.sterling",
        "indiawest.sterling",
        "indonesiac.sterling",
        "israelc.sterling",
        "italyn.sterling",
        "japaneast.sterling",
        "japanwest.sterling",
        "jioinc.sterling",
        "jioinw.sterling",
        "koreacentral.sterling",
        "koreasouth.sterling",
        "malaysias.sterling",
        "malaysiaw.sterling",
        "mexicoc.sterling",
        "newzealandn.sterling",
        "northeurope1-z.sterling",
        "norwaye.sterling",
        "norwayw.sterling",
        "polandc.sterling",
        "qatarc.sterling",
        "southafrican.sterling",
        "southafricaw.sterling",
        "southeastasia1-z.sterling",
        "spainc.sterling",
        "stageclusters",
        "swedenc.sterling",
        "swedens.sterling",
        "switzerlandn.sterling",
        "switzerlandw.sterling",
        "taiwann.sterling",
        "taiwannw.sterling",
        "uaec.sterling",
        "uaen.sterling",
        "uksouth.sterling",
        "uksouth1-z.sterling",
        "ukwest.sterling",
        "uscentral.sterling",
        "uscentraleuap.sterling",
        "useast.sterling",
        "useast2.sterling",
        "useast2euap.sterling",
        "useuapcentral1-z.sterling",
        "useuapeast2-z.sterling",
        "useuapeast2-z.sterling.sterling",
        "usnorth.sterling",
        "ussouth.sterling",
        "ussoutheast.sterling",
        "uswest.sterling",
        "uswest2.sterling",
        "uswest3.sterling",
        "uswestcentral.sterling"
    )

    for ($i = 0; $i -lt $regions.Length; $i++) {
        Write-Output "$($i + 1). $($regions[$i])"
    }
}

<#
.SYNOPSIS
   Changes the timeout for MySQL Import operation.

.DESCRIPTION
   The Set-MySqlImportTimeout function changes the timeout for MySQL Import operation to 24 hours. This is necessary as previous changes have set the timeout to 2 hours.

.PARAMETER csvFilePath
   Path to the CSV file containing the SubscriptionId, CustomerName, and Region.

.EXAMPLE
   Set-MySqlImportTimeout -csvFilePath "path\to\your\file.csv"
#>
function YOJ-MySqlImportTimeout {
    param(
        [Parameter(Mandatory=$true)]
        [string]$csvFilePath
    )

    # Import the CSV file
    $csv = Import-Csv -Path $csvFilePath -Header "SubscriptionId", "CustomerName", "Region"

    # Loop through each row in the CSV
    foreach ($row in $csv) {
        # Generate and execute the commands for each row
        Write-Host "Set 24 hour for SubscriptionId"
        Write-Host $row.SubscriptionId
        Select-SqlAzureCluster $row.Region
        Set-MySqlResourceProviderConfiguration -ConfigName UpsertServerManagementOperationTimeout -ConfigValue "24:00:00" -SubscriptionId $row.SubscriptionId -ConfigDescription "Set 24 hour for $($row.CustomerName)" -ServerType MySQL
    }
}

function YOJ-DBXServerInfo {
    param(
        [Parameter(Mandatory=$true)]
        [string]$serverName
    )

    # 获取服务器信息
    $info = Get-ElasticServerInstance2 -ServerName $serverName

    # 获取配置
    $logBinCfg = $info | Get-ElasticServerConfig -ConfigName "log_bin"
    $gtidModCfg = $info | Get-ElasticServerConfig -ConfigName "gtid_mode"
    $binlogGtidSimpleIgnoreCfg = $info | Get-ElasticServerConfig -ConfigName "binlog_gtid_simple_ignore"

    # 获取全局变量
    $globalVarsJson = $info | Invoke-ElasticServerDbCommand -command "show_global_variables"

    # 解析全局变量
    $globalVars = ConvertFrom-Json -InputObject $globalVarsJson

    # 查找 "log_bin" 变量
    $logBinVar = $globalVars.result | Where-Object { $_.Variable_name -eq "log_bin" }

    # 创建一个自定义对象并以表格的形式输出
    $output = New-Object -TypeName PSObject
    $output | Add-Member -MemberType NoteProperty -Name "ServerName" -Value $serverName
    $output | Add-Member -MemberType NoteProperty -Name "log_bin_cfg" -Value $logBinCfg
    $output | Add-Member -MemberType NoteProperty -Name "gtid_mod_cfg" -Value $gtidModCfg
    $output | Add-Member -MemberType NoteProperty -Name "binlog_gtid_simple_ignore_cfg" -Value $binlogGtidSimpleIgnoreCfg
    $output | Add-Member -MemberType NoteProperty -Name "log_bin" -Value $logBinVar.Value

    $output | Format-Table -AutoSize
}

# Step 0. Check variable of binlog_gtid_simple_ignores
function YOJ-CheckDBXServerConfig {
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$serverNames
    )

    foreach ($serverName in $serverNames) {
        # 获取服务器信息
        $info = Get-ElasticServerInstance2 -ServerName $serverName

        # 获取配置
        $configOutput = $info | Get-ElasticServerConfig -ConfigName "binlog_gtid_simple_ignore"

        # 解析配置值
        $configValue = ($configOutput -split '=')[1].Trim()

        # 检查配置是否为 "OFF"
        if ($configValue -eq "ON") {
            # 输出服务器名称和 "NEED_CHANGE"
            Write-Host $serverName "NeedChange"
        } else {
            Write-Host $serverName "SKIP"
        }
    }
}

# Step 1. change variable of binlog_gtid_simple_ignores & flush_binary_logs
function YOJ-ChangeDBXServerConfig {
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$serverNames
    )

    foreach ($serverName in $serverNames) {
        # 获取服务器信息
        $info = Get-ElasticServerInstance2 -ServerName $serverName

        # 获取配置
        $configOutput = $info | Get-ElasticServerConfig -ConfigName "binlog_gtid_simple_ignore"

        # 解析配置值
        $configValue = ($configOutput -split '=')[1].Trim()

        # 检查配置是否为 "OFF"
        if ($configValue -eq "ON") {
            # 输出服务器名称和 "NEED_CHANGE"
            Write-Host $serverName "Change"
            $info | Set-ElasticServerConfig -ConfigName binlog_gtid_simple_ignore -ConfigValue OFF -ConfigType UserConfiguration
            $info | Get-ElasticServerConfig -ConfigName "binlog_gtid_simple_ignore"
            $info | Invoke-ElasticServerDbCommand -command "flush_binary_logs"
        } else {
            Write-Host $serverName "SKIP"
        }
    }
}

# Step 2. Gernerate take backup command
function YOJ-BackupDBXServerCommand {
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$serverNames
    )

    foreach ($serverName in $serverNames) {
        # 获取服务器信息
        YOJ-SingleServerCommands -ServerName $serverName | findstr "Take backup"
    }
}

<#
.SYNOPSIS
Processes a CSV file to manage MySQL migration schedules.

It's generated by the SQL query

SELECT o.subscription_id,
       o.server_name,
       o.resource_group,
       o.region,
       o.storage_type
FROM orig_cms_sql_all_single_servers_08_12 AS o
JOIN sub_cx_name_map AS s
ON o.subscription_id = s.sub_id
WHERE s.cx_name = 'Walmart' and o.storage_type='SBS';

.DESCRIPTION
The Process-CsvFile function reads a CSV file containing server information and processes each row to manage MySQL migration schedules. It checks if an elastic_server_id exists and if a schedule exists for that server. If either does not exist, it creates a new migration server and schedule, then cancels the current schedule. It also logs the operations to a file and prints them to the console.

.PARAMETER CsvFilePath
The path to the CSV file containing server information.

.PARAMETER LogFilePath
The path to the log file where operations will be recorded.

.EXAMPLE
PS C:\> Process-CsvFile -CsvFilePath "C:\path\to\servers.csv" -LogFilePath "C:\path\to\log.txt"

This example processes the CSV file located at "C:\path\to\servers.csv" to manage MySQL migration schedules and logs the operations to "C:\path\to\log.txt".

.NOTES
This function relies on the Query-MySqlControlStore, New-MySqlMigrationServer, New-MySqlMigrationSchedule, and Cancel-MySqlMigrationCurrentSchedule functions to perform its operations.
#>
function YOJ-SetAndCancelScheduleForSBS {
    param (
        [string]$CsvFilePath,
        [string]$LogFilePath
    )

    # 初始化日志文件
    if (Test-Path $LogFilePath) {
        Clear-Content $LogFilePath
    }

    # 读取CSV文件
    $csvData = Import-Csv -Path $CsvFilePath -Header "subscription_id", "server_name", "resource_group", "region", "storage_type"

    foreach ($row in $csvData) {
        $subscription_id = $row.subscription_id
        $server_name = $row.server_name
        $resource_group = $row.resource_group
        $region = $row.region


        if ($subscription_id -eq "subscription_id") {
            continue
        }

        # 根据区域选择不同的环境
        switch ($region) {
            'wasd-prod-usgovsouthcentral1-a' { Select-SqlAzureEnvironment ffProd }
            'wasd-prod-usgovsouthwest1-a' { Select-SqlAzureEnvironment ffProd }
            'wasd-prod-usgoveast1-a' { Select-SqlAzureEnvironment ffProd }
            'wasd-prod-chinaeast2-a' { Select-SqlAzureEnvironment mcProd }
            'wasd-prod-chinanorth2-a' { Select-SqlAzureEnvironment mcProd }
            default { Select-SqlAzureEnvironment Prod }
        }

        Select-SqlAzureCluster $region

        $need_schedule = $false

        # 检查是否存在elastic_server_id
        $res = Query-MySqlControlStore "Select elastic_server_id from entity_migration_servers where elastic_server_name = '$server_name'"

        if ($res) {
            # 检查是否存在schedule
            $schedule = Query-MySqlControlStore "Select state from entity_migration_schedules where elastic_server_id = '$($res.elastic_server_id)'"

            if (-not $schedule) {
                $need_schedule = $true
                Add-Content -Path $LogFilePath -Value "$subscription_id  $server_name  $resource_group  $region [ADD]"
                Write-Output "$subscription_id  $server_name  $resource_group  $region [ADD]"
            } else {
                Add-Content -Path $LogFilePath -Value "$subscription_id  $server_name  $resource_group  $region [SKIP]"
                Write-Output "$subscription_id  $server_name  $resource_group  $region [SKIP]"
            }
        } else {
            $need_schedule = $true
            Add-Content -Path $LogFilePath -Value "$subscription_id  $server_name  $resource_group  $region [ADD]"
            Write-Output "$subscription_id  $server_name  $resource_group  $region [ADD]"
        }

        if ($need_schedule) {
            # 创建新的迁移服务器和计划
            New-MySqlMigrationServer -CustomerSubscriptionId $subscription_id -CustomerResourceGroup $resource_group -ElasticServerName $server_name
            Add-Content -Path $LogFilePath -Value "    $subscription_id  $server_name  $resource_group  $region [ADD_server_done]"
            Write-Output "    $subscription_id  $server_name  $resource_group  $region [ADD_server_done]"

            New-MySqlMigrationSchedule -CustomerSubscriptionId $subscription_id -CustomerResourceGroup $resource_group -ElasticServerName $server_name -ScheduledMigrationStartTime "2025-08-24T06:37:38.9326924" -ScheduledMigrationEndTime "2025-08-27T09:37:38.9326924" -MigrationMode Online -HaMode DISALBED
            Add-Content -Path $LogFilePath -Value "    $subscription_id  $server_name  $resource_group  $region [ADD_schedule_done]"
            Write-Output "    $subscription_id  $server_name  $resource_group  $region [ADD_schedule_done]"

            # 重新检查elastic_server_id
            $res = Query-MySqlControlStore "Select elastic_server_id from entity_migration_servers where elastic_server_name = '$server_name'"
            Add-Content -Path $LogFilePath -Value "    $subscription_id  $server_name  $resource_group  $region [RECHECK_elastic_server_id_done]"
            Write-Output "    $subscription_id  $server_name  $resource_group  $region [RECHECK_elastic_server_id_done]"

            # 取消当前的迁移计划
            Cancel-MySqlMigrationCurrentSchedule -ElasticServerId $res.elastic_server_id -CancelReason "cancel for mysql import by $server_name M32 test"
            Add-Content -Path $LogFilePath -Value "    $subscription_id  $server_name  $resource_group  $region [CANCEL_schedule_done]"
            Write-Output "    $subscription_id  $server_name  $resource_group  $region [CANCEL_schedule_done]"

            Query-MySqlControlStore "Select state from entity_migration_schedules where elastic_server_id = '$($res.elastic_server_id)'"
        }
    }
}

Export-ModuleMember -Function YOJ-ExtractAndExecute
Export-ModuleMember -Function YOJ-OneBox-SingleServerCreate
Export-ModuleMember -Function YOJ-OneBox-Init
Export-ModuleMember -Function YOJ-OneBox-MySQLImportRestAPI
Export-ModuleMember -Function YOJ-MySQLImportRestAPI
Export-ModuleMember -Function YOJ-FlexServerPITRRealRun
Export-ModuleMember -Function YOJ-FlexServerPITRDryRun
Export-ModuleMember -Function YOJ-FlexServerSASToken
Export-ModuleMember -Function YOJ-FlexServerJITPortal
Export-ModuleMember -Function YOJ-SingleServerJITUrl  # CMD1
Export-ModuleMember -Function YOJ-FlexServerOpen22ForSSH
Export-ModuleMember -Function YOJ-FlexVMJITUrl
Export-ModuleMember -Function YOJ-GenerateDirectoryPathsAndCommand   # CMD2
Export-ModuleMember -Function YOJ-GetJitMySqlConnectionStringSingleServer
Export-ModuleMember -Function YOJ-SingleServerPITRDryRun
Export-ModuleMember -Function YOJ-SetSingleParameter
Export-ModuleMember -Function YOJ-RestartSingleServer
Export-ModuleMember -Function YOJ-MERUSASToken
Export-ModuleMember -Function YOJ-SingleServerSASToken
Export-ModuleMember -Function YOJ-ComputeTableRows
Export-ModuleMember -Function YOJ-MERUStorageResize
Export-ModuleMember -Function YOJ-SingleServerCommands
Export-ModuleMember -Function YOJ-MERUJITSQLAzureCASRegions
Export-ModuleMember -Function YOJ-MySqlImportTimeout
Export-ModuleMember -Function YOJ-DBXServerInfo
Export-ModuleMember -Function YOJ-CheckDBXServerConfig
Export-ModuleMember -Function YOJ-ChangeDBXServerConfig
Export-ModuleMember -Function YOJ-BackupDBXServerCommand
Export-ModuleMember -Function YOJ-SetAndCancelScheduleForSBS

# Import-Module "C:\Users\yoj\Work Folders\Downloads\yoj.psm1" -Force
# Import-Module "C:\DevOps\DevOps.Module.psm1"
# Import-Module "C:\Users\yoj\Work Folders\Downloads\top100\MySqlFS.DevOps.AutoMigration.psm1" -Force
