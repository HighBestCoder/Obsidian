# AFEC
1. 使用SAW
2. edge-> new private window: [打开链接]([https://portal.microsoftgeneva.com/?page=actions&acisEndpoint=Public&managementOpen=false&selectedNodeType=3&extension=Azure%20Resource%20Manager&group=Feature%20Management&operationId=GetFeatures&operationName=Get%20Features&inputMode=single&params={"resourceprovidernamespace":"Microsoft.Storage"}&actionEndpoint=Feature&genevatraceguid=27dd9564-613d-4fdd-bdb8-d2dbfcb26177](https://portal.microsoftgeneva.com/?page=actions&acisEndpoint=Public&managementOpen=false&selectedNodeType=3&extension=Azure%20Resource%20Manager&group=Feature%20Management&operationId=GetFeatures&operationName=Get%20Features&inputMode=single&params=%7B%22resourceprovidernamespace%22:%22Microsoft.Storage%22%7D&actionEndpoint=Feature&genevatraceguid=27dd9564-613d-4fdd-bdb8-d2dbfcb26177 "https://portal.microsoftgeneva.com/?page=actions&acisendpoint=public&managementopen=false&selectednodetype=3&extension=azure%20resource%20manager&group=feature%20management&operationid=getfeatures&operationname=get%20features&inputmode=single&params=%7b%22resourceprovidernamespace%22:%22microsoft.storage%22%7d&actionendpoint=feature&genevatraceguid=27dd9564-613d-4fdd-bdb8-d2dbfcb26177"))
3. 一直使用microsoft帐号。在选择PIN的时候，记得选择yoj@microsoft.com的smart-card.
4. 在看用户的feature的时候，要使用Microsoft.Resources(用户的sub)/Microsoft.Storage这两个。

# PITR

### 1 
首先进行PITR
Get-JitAccess -WorkitemSource IcM -Justification "Request SAS token or access backend node for investigations" -WorkitemId IcM_ID -SubscriptionId SUB_ID
### 2
$targetDate = [DateTime]::UtcNow

下面这个命令可以从xts上copy
Restore-ElasticServer2 -SubscriptionId <subscription id> -ServerType MySQL.Server.PAL -SourceResourceGroup <resource group> -SourceServerName <server name> -TargetServerName <server name>-restore -PointInTimeUtc $targetDate -TargetResourceGroup <resource group>
