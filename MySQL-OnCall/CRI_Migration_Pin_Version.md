


# ROOT CAUSE

```SQL
MonMySQLLogs
| where message contains "ERROR: [MYFILE] binlogov failed to load libbinlogov.so"
| project LogicalServerName
| summarize count() by LogicalServerName
```

这里可以发现`libbinlogov.so`不能加载成功。
# MySQL Version Pinning Guide

## Step 1

打开CAS 然后运行以下查询：

```sql
Query-MySqlControlStore "SELECT * FROM dbo.entity_application_package_mapping WHERE application_name = 'MySQL:8.0';"
```

你将会得到以下输出：

```
ce077ae5-a81c-486e-b78b-95d4d338c283	MySQL	MySQL:8.0	mysql80_28_0_20240304_120361473	subscriptions/*/resourceGroups/*/providers/Microsoft.DBforMySQL/flexibleServers/*		Regional Default	2024-03-19T02:47:41.2380972Z	Created
```

## Step 2

运行CAS以固定版本：

```powershell
PS C:\Users\yoj\SqlAzureConsole> Select-SqlAzureEnvironment mcProd
- OptimizedSync has been enabled.
  * To turn off OptimizedSync pass -DisableOptimizedSync to Select-SqlAzureEnvironment
PS C:\Users\yoj\SqlAzureConsole> Select-SqlAzureCluster Wasd-prod-chinaeast2-a
No Ringname Specified, so selecting First Live Control Ring i.e, 'wasd-prod-chinaeast2-a-cr1'
CAS version number: 16.0.5529.103
PS C:\Users\yoj\SqlAzureConsole> Set-MySqlApplicationDefaultVersion -ServerType "MySQL" -SubscriptionId "74c15957-7570-416c-96c0-d410228045f9" -ApplicationName "MySQL:8.0" -ApplicationVersion "mysql80_27_1_20240219_119204647" -IncidentId "484836269" -Description "Need pin M27 for migration, due to M28 mysql 8.0.28 can not load libbinlogov.so"
>>
Invoke API to set application/os default version.
```

## Step 3

然后再次运行CMS查询以检查：

```sql
Query-MySqlControlStore "SELECT * FROM dbo.entity_application_package_mapping WHERE application_name = 'MySQL:8.0';"
```

你会得到以下输出：

```
ce077ae5-a81c-486e-b78b-95d4d338c283	MySQL	MySQL:8.0	mysql80_28_0_20240304_120361473	subscriptions/*/resourceGroups/*/providers/Microsoft.DBforMySQL/flexibleServers/*		Regional Default	2024-03-19T02:47:41.2380972Z	Created					2023/5/9 2:30:10	14	false	
b8afdd99-dd43-404c-8c93-cd547fb44bf3	MySQL	MySQL:8.0	mysql80_27_1_20240219_119204647	subscriptions/74c15957-7570-416c-96c0-d410228045f9/resourceGroups/*/providers/Microsoft.DBforMySQL/flexibleServers/*		Incident: 484836269 - Need pin M27 for migration, due to M28 mysql 8.0.28 can not load libbinlogov.so	2024-03-26T07:07:16.1170808Z	Created					2024/3/26 7:07:16	0	false	
```

# 用户migration结束之后

需要用`Remove-MySqlApplicationDefaultVersionRow`把那一行加的限制给删除

要通过query cms找出来。然后把那一行删除掉。千万不要删错。
