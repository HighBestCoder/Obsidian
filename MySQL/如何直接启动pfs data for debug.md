# Copy Data
首先JIT 自己的test VM之后，然后将数据整个目录打包。这样可以把所有的数据都带走。

放到自己的Linux VM之后，解压。

比如我这里解压到了

```
/src/binlogs/chinese/data/datashare 

root@yoj-small-vm:~# cd /src/binlogs/chinese/data/datashare
root@yoj-small-vm:/src/binlogs/chinese/data/datashare# ls
auto.cnf                    azure_mysqlclient_key.pem  binlogs           ca.pem    config            entrypoint.sh   ib_logfile1  key.pem      mysql                         mysql.sock          public_key.pem  replication_set_role.cnf  sys
azure_mysqlclient_cert.pem  azure_mysqlservice.pem     bootstrap.sql     cert.pem  control           ib_buffer_pool  ibdata1      mtr_dev_ahe  mysql-bin.index               performance_schema  redologs        reset_purged_gtids        temp
azure_mysqlclient_cert.pfx  binlog                     c11218e62966.pid  cert.pfx  dbc55454647f.pid  ib_logfile0     ibtmp1       mtr_prod     mysql-bin.index_double_write  private_key.pem     relaylogs       serverlogs                userconfig
root@yoj-small-vm:/src/binlogs/chinese/data/datashare#

```

# Start Container

在启动container之前，需要将data目录下的所有文件移到`/src/binlogs/chinese/data/datashare `下，否则启动的时候，会说启动失败。

```
cd /src/binlogs/chinese/data/datashare
mv data/* ./
```

然后再用命令启动container

```
docker run -idt   -v /src/binlogs/chinese/data/datashare:/var/lib/mysql   -e MYSQL_ROOT_PASSWORD=root  -e MYSQL_INITDB_SKIP_TZINFO=1  --name eform-test   mysql:5.7
```

# 连进数据库

```
root@yoj-small-vm:/src/binlogs/chinese/data/datashare# dc eform-test
bash-4.2#
bash-4.2#
bash-4.2# mysql -uazure_superuser
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 9
Server version: 5.7.39 MySQL Community Server (GPL)

Copyright (c) 2000, 2022, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql>
```

# 添加用户

