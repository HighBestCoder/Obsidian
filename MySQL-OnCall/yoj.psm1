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
       $path1 = "S:\WFRoot\_App\Worker.PAL.MySQL_$AppInfo\work\Sandbox\work"
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

