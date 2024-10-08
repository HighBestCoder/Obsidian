首先运行Kusto SQL

```
MonMySQLLogs
| where LogicalServerName == 'ne-prd-spark-mysql-01-cloud-shell-deleteme-dryrun3'
| where PreciseTimeStamp > ago(20m)
```

找到package version
![[Pasted image 20240304103844.png]]

那么，接下来就需要去看 RP的build pipeline里面，找到对应的版本

[Pipelines - Run 27.1.20240219.119204647 (visualstudio.com)](https://msdata.visualstudio.com/Database%20Systems/_build/results?buildId=119204647&view=results "https://msdata.visualstudio.com/database%20systems/_build/results?buildid=119204647&view=results")

然后点开页面最下面的

![[Pasted image 20240304103953.png]]

再点击右上角的

![[Pasted image 20240304104013.png]]

再依次打开

![[Pasted image 20240304104048.png]]

再查看文件
![[Pasted image 20240304104108.png]]

然后再打开 mysql engine的official build

[https://msdata.visualstudio.com/Database%20Systems/_build?definitionId=20188](https://msdata.visualstudio.com/Database%20Systems/_build?definitionId=20188 "https://msdata.visualstudio.com/database%20systems/_build?definitionid=20188")

找到那一天相应的 build
![[Pasted image 20240304104211.png]]

![[Pasted image 20240304104244.png]]
