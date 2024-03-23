j#meru修改状态

-   #jitmerurp
    -   Get-MeruRpJitAccess -WorkitemSource IcM -WorkItemId <ICM_ID> -Justification < Justification >
-   需要重启asc console 注意，这里需要等一段时间再重启，让本地建好cache。如果重启得过快，有可能会在跑命令的时候出现错误。
- 
-   修改meru node状态
    
    -   Set-MySqlServerEntityState -TableName entity_orcas_servers -Keys "a1d5f574-7861-48c6-8b8b-b6fa7c8abba8" -ExpectedCurrentState AddingStandby -NewState Succeeded -CabId 12123 -Force
- 这里的keys实际上就是`entity_orcas_servers`的id这个值。

#注意

在删除的时候，如果是HA节点。那么就先删除primay，再删除standby。如果primary删除成功之后。standby还是卡在dropped状态。那么

1. 重新把standby修改成succeded
2. 手动输入sub/servername/rg参数，利用`Remove-MySqlServer`这个命令把server删除掉。
