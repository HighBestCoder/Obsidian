
# 问题重现的sop

  
According to their table schema and telemetries, we can reproduce the issue now with the following simplified steps.

1. Create the partition table on Windows (Single)
    
    CREATE TABLE `test` (
      `id` int(11)
    )
    PARTITION BY RANGE (id)
    (PARTITION u0001 VALUES LESS THAN (10),
     PARTITION future VALUES LESS THAN MAXVALUE)
    
      
    
2. Migrate the data to Linux (Flex)

3. Reorganize the partition (split an existing partition into two, and one of the new partitions keeps using the original name)
    
    ALTER TABLE `test` REORGANIZE PARTITION future INTO (PARTITION u0002 VALUES LESS THAN (20), PARTITION future VALUES LESS THAN MAXVALUE);
    
      
    
4. The table is corrupted
    

This is caused by the platform discrepancy of MySQL. On Windows, it uses "#p#" as the separator of partitions. While on Linux, it used "#P#". So, the table is missing after the migration.

There are lots of places in the MySQL code that hard-coded the separator based on the platform, it knows to handle the compatibility, but the handling logic for this is so weak and confusing, which leads to the unexpected issues.

# 真实的复现

测试数据的准备。首先，我这里有一个`Windows`上准备好的数据。

```
root@yoj-small-vm:/src/ms-mysql# ls /src/migration/partition_table/data.tar
```

解压到了Linux系统之后，所有的partition文件都是小写。

```
 test#p#future.ibd  test#p#u0001.ibd  test#p#u0002.ibd  test#p#u0003.ibd  test.frm
```

然后我们会使用`mysql -uroot -proot -Dtest`连接上mysql。接着使用
```sql
DELIMITER //
CREATE PROCEDURE InsertData()
BEGIN
  DECLARE i INT DEFAULT 1;
  WHILE i <= 1000 DO
    INSERT INTO `test` (`id`) VALUES (i);
    SET i = i + 1;
  END WHILE;
END;
//
DELIMITER ;

CALL InsertData();
```

往`test`表里面添加1000行数据。

然后再执行命令：

```SQL
 ALTER TABLE `test` REORGANIZE PARTITION future INTO (PARTITION u0004 VALUES LESS THAN (40), PARTITION future VALUES LESS THAN MAXVALUE);
```

这个命令会执行成功。但是接下来打开table `test`就会出错了。

```sql

mysql> select * from rest;
ERROR 1146 (42S02): Unknown error 1146
mysql> select * from test;
ERROR 1030 (HY000): Unknown error 1030
mysql> quit
Bye
```

# source code

在MySQL 5.7的源码中，`ALTER TABLE ... REORGANIZE PARTITION` 语句的执行流程涉及多个步骤和组件。以下是对该流程的详细解析：

1. **语法解析和准备阶段**：
   - 客户端发送 `ALTER TABLE ... REORGANIZE PARTITION` 语句到MySQL服务器。
   - MySQL的SQL解析器（`sql_parse.cc`）解析该语句，并将其转换为内部表示形式。
   - 解析后的语句被传递给 `mysql_execute_command()` 函数（位于 `sql_parse.cc`），该函数负责处理各种SQL命令。

2. **权限检查**：
   - 在执行任何操作之前，MySQL会检查当前用户是否有足够的权限来执行 `ALTER TABLE` 操作。
   - 权限检查通过 `check_access()` 和 `check_table_access()` 函数完成。

3. **表锁定和元数据更新**：
   - MySQL会锁定要修改的表，以防止在操作期间其他会话对其进行修改。
   - 表锁定通过 `lock_table_names()` 函数实现。
   - 元数据更新涉及修改表的定义，包括分区信息。

4. **分区重组**：
   - `ALTER_REORGANIZE_PARTITION` 操作的核心是分区重组。
   - 该操作由 `mysql_alter_table()` 函数（位于 `sql_table.cc`）调用 `reorganize_partitions()` 函数（位于 `partition_info.h` 和 `partition_info.cc`）来完成。
   - `reorganize_partitions()` 函数负责创建新的分区，并将数据从旧分区移动到新分区。
   - 数据移动涉及扫描旧分区，将数据插入到新分区中，并删除旧分区中的数据。

5. **提交和清理**：
   - 一旦数据移动完成，MySQL会提交事务，并释放表锁定。
   - 提交事务通过 `ha_commit_trans()` 函数完成。
   - 清理工作包括释放临时资源和更新表的元数据。

6. **错误处理**：
   - 如果在执行过程中发生错误，MySQL会回滚事务，并释放所有锁定资源。
   - 错误处理通过 `ha_rollback_trans()` 函数完成。

以下是一些关键的源码文件和函数，它们在 `ALTER_REORGANIZE_PARTITION` 操作中起着重要作用：

- `sql_parse.cc`：包含 `mysql_execute_command()` 函数，负责处理SQL命令。
- `sql_table.cc`：包含 `mysql_alter_table()` 函数，负责执行 `ALTER TABLE` 操作。
- `partition_info.h` 和 `partition_info.cc`：包含 `reorganize_partitions()` 函数，负责分区重组。
- `handler.h` 和 `handler.cc`：包含表和分区的底层处理逻辑。

通过这些步骤和组件，MySQL 5.7能够有效地执行 `ALTER TABLE ... REORGANIZE PARTITION` 操作，确保数据的一致性和完整性。

# call stack

```cpp
这是一个MySQL的错误日志，其中包含了一些函数调用栈的信息。从日志中可以看出，MySQL在尝试重命名一个表时遇到了问题。以下是调用栈的整理：

1. `row_rename_table_for_mysql` (在`/src/mysql/storage/innobase/row/row0mysql.cc:5357`)
2. `mysql_alter_table` (在`Z17mysql_alter_tableP3THDPKcS2_P24st_ha_create_informationP10TABLE_LISTP10Alter_info+0x158d:0`)
3. `fast_alter_partition_table` (在`Z26fast_alter_partition_tableP3THDP5TABLEP10Alter_infoP24st_ha_create_informationP10TABLE_LISTPcPKcP14partition_info+0x51e:0`)
4. `handle_alter_part_end` (在`Z21handle_alter_part_endP18st_lock_param_typeb+0x9d:0`)
5. `execute_ddl_log_entry` (在`Z21execute_ddl_log_entryP3THDj+0x64:0`)
6. Unknown function (在`0xca5e34:0`)
7. Unknown function (在`0xca5a32:0`)
8. `ha_innobase::delete_table` (在`ZN11ha_innobase12delete_tableEPKc+0x9d:0`)
9. Unknown function (在`fs_spawn_thread+0x164:0`)
10. Unknown function (在`andle_connection+0x2f0:0`)
11. `do_command` (在`Z10do_commandP3THD+0x197:0`)
12. `dispatch_command` (在`Z16dispatch_commandP3THDPK8COM_DATA19enum_server_command+0xb85:0`)
13. `mysql_parse` (在`Z11mysql_parseP3THDP12Parser_state+0x48d:0`)
14. `mysql_execute_command` (在`Z21mysql_execute_commandP3THDb+0x940:0`)
15. `Sql_cmd_alter_table::execute` (在`ZN19Sql_cmd_alter_table7executeEP3THD+0x449:0`)

请注意，这个调用栈可能并不完全准确，因为一些函数的名字在日志中并没有给出。此外，这个调用栈是从最近的调用开始的，所以你可能需要从下到上阅读，以了解问题的起源。

这个错误可能是由于MySQL试图重命名一个不存在的表导致的。你可能需要检查你的数据库和查询，确保你在操作存在的表。
```


# 复现

on single server

```bash
root@yoj-small-vm:/src# mysql -hyoj-test-pfs-57i.mysql.database.azure.com -uyoj@yoj-test-pfs-57i -pfedora12@
mysql: [Warning] Using a password on the command line interface can be insecure.
ERROR 9000 (HY000): Client with IP address '104.211.16.102' is not allowed to connect to this MySQL server.
root@yoj-small-vm:/src# mysql -hyoj-test-pfs-57i.mysql.database.azure.com -uyoj@yoj-test-pfs-57i -pfedora12@
mysql: [Warning] Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 65524
Server version: 5.6.47.0 MySQL Community Server (GPL)

Copyright (c) 2000, 2024, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> creat database test;
ERROR 1064 (42000): You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'creat database test' at line 1
mysql> create database test;
Query OK, 1 row affected (0.08 sec)
mysql> use test;
Database changed
mysql>
mysql>
mysql> CREATE TABLE `test` (
(PARTITION u0001 VALUES LESS THA    ->  `id` int(11)
ON future VALUES    -> )
    -> PARTITION BY RANGE (`id`)
    -> (PARTITION u0001 VALUES LESS THAN (10),
    ->  PARTITION future VALUES LESS THAN MAXVALUE);
Query OK, 0 rows affected (0.19 sec)

mysql>
mysql>
mysql>
mysql>
mysql> DELIMITER //
END WHILE;
END;
//
DELIMITER ;

mysql> CREATE PROCEDURE InsertData()
    -> BEGIN
    ->   DECLARE i INT DEFAULT 1;
    ->   WHILE i <= 1000 DO
    ->     INSERT INTO `test` (`id`) VALUES (i);
    ->     SET i = i + 1;
    ->   END WHILE;
    -> END;
    -> //
Query OK, 0 rows affected (0.04 sec)

mysql> DELIMITER ;
mysql>
mysql> CALL InsertData();
Query OK, 1 row affected (7.01 sec)

mysql>
```


on flex server
```bash

root@1a6c1c646d7e:/# mysql -hyoj-flex-pfs-57i.mysql.database.azure.com -uyoj -pfedora12@
mysql: [Warning] Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 7
Server version: 5.7.44-azure-log MySQL Community Server (GPL)

Copyright (c) 2000, 2023, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.


mysql> use test;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> show tables;
+----------------+
| Tables_in_test |
+----------------+
| test           |
+----------------+
1 row in set (0.04 sec)

mysql> select count(*) from test;
+----------+
| count(*) |
+----------+
|     1000 |
+----------+
1 row in set (0.08 sec)

mysql>  ALTER TABLE `test` REORGANIZE PARTITION future INTO (PARTITION u0004 VALUES LESS THAN (40), PARTITION future VALUES LESS THAN MAXVALUE);
Query OK, 0 rows affected (0.35 sec)

mysql> select count(*) from test;
ERROR 1030 (HY000): Got error 122 from storage engine
mysql> exit
Bye
```

# 简化之后的SQL

在single server上执行

创建数据库：

```sql
CREATE DATABASE test;
USE test;
```

创建分区表：

```sql
CREATE TABLE `test` (
  `id` int(11)
)
PARTITION BY RANGE (`id`) (
  PARTITION u0001 VALUES LESS THAN (10),
  PARTITION future VALUES LESS THAN MAXVALUE
);
```

创建存储过程并插入数据：

```sql
DELIMITER //
CREATE PROCEDURE InsertData()
BEGIN
  DECLARE i INT DEFAULT 1;
  WHILE i <= 1000 DO
    INSERT INTO `test` (`id`) VALUES (i);
    SET i = i + 1;
  END WHILE;
END;
//
DELIMITER ;
```

调用存储过程：

```sql
CALL InsertData();
```

# 使用mysql import进行迁移

```Bash
root@1a6c1c646d7e:/#  az mysql flexible-server import create --data-source-type "mysql_single" --data-source "yoj-test-pfs-57" --resource-group "yoj-test-perf" --location centraluseuap --name "yoj-flex-pfs-57" --admin-user "yoj" --admin-password "fedora12@" --sku-name "
Standard_D2s_v3" --tier "GeneralPurpose" --public-access 0.0.0.0 --storage-size 256 --version 5.7 --storage-auto-grow Enabled --public-access Disabled
Changing administrator login name and password is currently not supported for single to flex migrations. Please use source single server administrator login name and password to connect after migration.
Checking the existence of the resource group 'yoj-test-perf'...
Resource group 'yoj-test-perf' exists ? : True
IOPS is 1068 which is either your input or free(maximum) IOPS supported for your storage size and SKU.
Creating MySQL Server 'yoj-flex-pfs-57' in group 'yoj-test-perf'...
Your server 'yoj-flex-pfs-57' is using sku 'Standard_D2s_v3' (Paid Tier). Please refer to https://aka.ms/mysql-pricing for pricing details




 - Running ..


 \ Running ..

Firewall rules cannot be migrated for private access enabled server.
Make a note of your password. If you forget, you would have to reset your password with'az mysql flexible-server update -n yoj-flex-pfs-57 -g yoj-test-perf -p <new-password>'.
Try using az 'mysql flexible-server connect' command to test out connection.
{
  "connectionString": "mysql --host yoj-flex-pfs-57.mysql.database.azure.com --user yoj --password=fedora12@",
  "host": "yoj-flex-pfs-57.mysql.database.azure.com",
  "id": "/subscriptions/2941a09d-7bcf-42fe-91ca-1765f521c829/resourceGroups/yoj-test-perf/providers/Microsoft.DBforMySQL/flexibleServers/yoj-flex-pfs-57",
  "location": "Central US EUAP",
  "password": "fedora12@",
  "resourceGroup": "yoj-test-perf",
  "skuname": "Standard_D2s_v3",
  "username": "yoj",
  "version": "5.7"
}
```


# flex server上的测试


这是你执行过的SQL语句：

1. 切换数据库：
```sql
USE test;
```

2. 查看数据库中的表：
```sql
SHOW TABLES;
```

3. 查询表中的记录数量：
```sql
SELECT COUNT(*) FROM test;
```

4. 重新组织表的分区：
```sql
ALTER TABLE `test` REORGANIZE PARTITION future INTO (
  PARTITION u0004 VALUES LESS THAN (40), 
  PARTITION future VALUES LESS THAN MAXVALUE
);
```

5. 再次查询表中的记录数量：
```sql
SELECT COUNT(*) FROM test;
```

6. 退出数据库：
```sql
quit
```

