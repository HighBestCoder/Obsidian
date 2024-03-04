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

    $info = Get-ElasticServerInstance2 -ServerName $ServerName -IncludeFabricProperties
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
   $info = Get-MySqlServer2 -ServerName $ServerName

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

Export-ModuleMember -Function YOJ-FlexServerSASToken
Export-ModuleMember -Function YOJ-FlexServerJITPortal
Export-ModuleMember -Function YOJ-SingleServerJITUrl
Export-ModuleMember -Function YOJ-FlexServerOpen22ForSSH
Export-ModuleMember -Function YOJ-FlexVMJITUrl
Export-ModuleMember -Function YOJ-GenerateDirectoryPathsAndCommand
Export-ModuleMember -Function YOJ-GetJitMySqlConnectionStringSingleServer
Export-ModuleMember -Function YOJ-SingleServerPITRDryRun
Export-ModuleMember -Function YOJ-SetSingleParameter
Export-ModuleMember -Function YOJ-RestartSingleServer
Export-ModuleMember -Function YOJ-MERUSASToken
Export-ModuleMember -Function YOJ-SingleServerSASToken
Export-ModuleMember -Function YOJ-ComputeTableRows
Export-ModuleMember -Function YOJ-MERUStorageResize

# Import-Module "C:\Users\yoj\code\Obsidian\MySQL-OnCall\yoj.psm1" -Force

