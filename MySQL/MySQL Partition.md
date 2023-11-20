
# Windows与Linux的差异

```C++
/* To be backwards compatible we also fold partition separator on windows. */
#ifdef _WIN32
const char* part_sep = "#p#";
const char* sub_sep = "#sp#";
#else
const char* part_sep = "#P#";
const char* sub_sep = "#SP#";
#endif /* _WIN32 */
[9/28 14:53] Jiaye Wu
/** Always normalize table name to lower case on Windows */
#ifdef _WIN32
#define normalize_table_name(norm_name, name)           \
    create_table_info_t::normalize_table_name_low(norm_name, name, TRUE)
#else
#define normalize_table_name(norm_name, name)           \
    create_table_info_t::normalize_table_name_low(norm_name, name, FALSE)
#endif /* _WIN32 */
```

# PFS account

```bash
mkdir -p /mnt/yojfs  
if [ ! -d "/etc/smbcredentials" ]; then  
    mkdir -p /etc/smbcredentials  
fi  
if [ ! -f "/etc/smbcredentials/yojsa.cred" ]; then  
    bash -c 'echo "username=yojsa" >> /etc/smbcredentials/yojsa.cred'  
    bash -c 'echo "password=cgJgMhWGvzXgr9SyPEJwsYUa4fDfoBJuECWWUyk6ko7sMQFFst8i3e+O2fSvczA0MaqSgKn6+H3U+AStcDTpEw==" >> /etc/smbcredentials/yojsa.cred'  
fi  
chmod 600 /etc/smbcredentials/yojsa.cred

bash -c 'echo "//yojsa.file.core.windows.net/yojfs /mnt/yojfs cifs nofail,credentials=/etc/smbcredentials/yojsa.cred,dir_mode=0777,file_mode=0777,serverino,nosharesock,actimeo=30" >> /etc/fstab'  
mount -t cifs //yojsa.file.core.windows.net/yojfs /mnt/yojfs -o credentials=/etc/smbcredentials/yojsa.cred,dir_mode=0777,file_mode=0777,serverino,nosharesock,actimeo=30
```

# Error Code

```
HA_ERR_INTERNAL_ERROR
```

# Add log pos

```
./sql/auth/sql_user_table.cc:52:                    assert(error == HA_ERR_INTERNAL_ERROR);    \
./sql/auth/sql_user_table.cc:64:                    assert(error == HA_ERR_INTERNAL_ERROR);     \
./sql/auth/sql_user_table.cc:76:                    assert(error == HA_ERR_INTERNAL_ERROR);     \
./sql/ha_ndbcluster.cc:829:      error= HA_ERR_INTERNAL_ERROR;
./sql/handler.cc:8245:                  DBUG_RETURN(HA_ERR_INTERNAL_ERROR); );
./sql/handler.cc:8287:                  DBUG_RETURN(HA_ERR_INTERNAL_ERROR); );
./sql/handler.cc:8320:                  return HA_ERR_INTERNAL_ERROR; );
./sql/ha_ndbinfo.cc:243:  DBUG_RETURN(HA_ERR_INTERNAL_ERROR);
./sql/ha_ndbinfo.cc:633:    DBUG_RETURN(HA_ERR_INTERNAL_ERROR);
./sql/partitioning/partition_handler.cc:2772:    error= HA_ERR_INTERNAL_ERROR;
./sql/partitioning/partition_handler.cc:3157:      DBUG_RETURN(HA_ERR_INTERNAL_ERROR);
grep: ./out/sql/mysqld: binary file matches
grep: ./out/sql/CMakeFiles/sql.dir/auth/sql_user_table.cc.o: binary file matches
grep: ./out/archive_output_directory/libsql.a: binary file matches
grep: ./out/storage/perfschema/unittest/pfs_connect_attr-t: binary file matches
./include/my_base.h:416:#define HA_ERR_INTERNAL_ERROR   122     /* Internal error */
./storage/partition/ha_partition.h:437:      return(HA_ERR_INTERNAL_ERROR);
./storage/partition/ha_partition.cc:1546:  int error= HA_ERR_INTERNAL_ERROR;
./storage/innobase/handler/ha_innodb.cc:2258:           return(HA_ERR_INTERNAL_ERROR);
./storage/innobase/handler/ha_innopart.cc:1035:                 DBUG_RETURN(HA_ERR_INTERNAL_ERROR);
./storage/innobase/handler/ha_innopart.cc:2770:         DBUG_RETURN(HA_ERR_INTERNAL_ERROR);
./storage/innobase/handler/ha_innopart.cc:2860:                 error = HA_ERR_INTERNAL_ERROR;
./storage/innobase/handler/ha_innopart.cc:2870:                 error = HA_ERR_INTERNAL_ERROR;
./storage/innobase/handler/ha_innopart.cc:2923:                                 error = HA_ERR_INTERNAL_ERROR;
./storage/innobase/handler/ha_innopart.cc:2934:                                 error = HA_ERR_INTERNAL_ERROR;;
./storage/innobase/handler/ha_innopart.cc:4496:                 DBUG_RETURN(HA_ERR_INTERNAL_ERROR);
./storage/innobase/handler/ha_innopart.cc:4626:         DBUG_RETURN(HA_ERR_INTERNAL_ERROR);
./storage/archive/ha_archive.cc:745:    rc= my_errno() ? my_errno() : HA_ERR_INTERNAL_ERROR;
```

# Code

```C++
    if (NULL == ib_table && is_partition) {

        /* MySQL partition engine hard codes the file name

        separator as "#P#". The text case is fixed even if

        lower_case_table_names is set to 1 or 2. This is true

        for sub-partition names as well. InnoDB always

        normalises file names to lower case on Windows, this

        can potentially cause problems when copying/moving

        tables between platforms.

        1) If boot against an installation from Windows

        platform, then its partition table name could

        be in lower case in system tables. So we will

        need to check lower case name when load table.

        2) If we boot an installation from other case

        sensitive platform in Windows, we might need to

        check the existence of table name without lower

        case in the system table. */

        if (innobase_get_lower_case_table_names() == 1 ) {

            char    par_case_name[FN_REFLEN];
```

# 为什么会出这样的问题

```
select * from INNODB_SYS_DATAFILES;
```

这里可以可以看到每个文件的存储位置。对于MySQL面言，在打开db文件之前，总是会先到这里进行string compare。而不是真正地去文件系统中寻找路径。

# cfg lower_case_table_names

`lower_case_table_names` 是 MySQL 的一个系统变量，用于控制数据库对象（如表名和数据库名）的大小写敏感性。该变量可以设置为不同的整数值，每个值代表不同的行为。以下是 `lower_case_table_names` 的几个可能的取值和它们的含义：

1. **0**：这是默认值，表示表名和数据库名是区分大小写的。这意味着 `MyTable` 和 `mytable` 被视为两个不同的表名。

2. **1**：表示表名和数据库名不区分大小写。这意味着 `MyTable` 和 `mytable` 被视为相同的表名，不区分大小写。

3. **2**：表示表名和数据库名在创建时存储为小写，但在比较时不区分大小写。这意味着 `MyTable` 在存储时会被保存为 `mytable`，但在比较时仍然可以区分大小写。

注意：在使用 `lower_case_table_names` 设置为非默认值时，需要特别小心，因为它可能导致不同大小写的表名被视为相同，这可能会导致数据访问问题。

在实际使用中，建议在 MySQL 安装之前选择 `lower_case_table_names` 的值，并且在创建表之前确保表名的大小写符合所选的设置。这将有助于避免混淆和不一致性。

# 重现

#### 创建表1

这里有两种hash，一种是根据值来Hash

```SQL
CREATE TABLE `students` (
  `StudentID` int(11) NOT NULL,
  `Name` varchar(50) DEFAULT NULL,
  `Age` int(11) DEFAULT NULL,
  `CourseID` int(11) NOT NULL,
  PRIMARY KEY (`StudentID`,`CourseID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1
/*!50100 PARTITION BY HASH (StudentID)
PARTITIONS 40 */;
```

#### 加数据1

```
DELIMITER //

CREATE PROCEDURE `InsertStudentsData`()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE random_age INT;
    DECLARE random_course_id INT;
    WHILE i <= 10000 DO
        SET random_age = FLOOR(RAND() * 100) + 18;
        SET random_course_id = FLOOR(RAND() * 10) + 1;
        INSERT INTO students (StudentID, Name, Age, CourseID)
        VALUES (i, CONCAT('Student_', i), random_age, random_course_id);
        SET i = i + 1;
    END WHILE;
END//

DELIMITER ;
```

调用之
```
call InsertStudentsData();
```

#### 创建表2

```Sql
CREATE TABLE `cipcode` (
  `ID_FORM` int(10) unsigned NOT NULL,
  `ID_CIP` int(10) unsigned NOT NULL,
  `YEAR` smallint(5) unsigned NOT NULL,
  PRIMARY KEY (`ID_FORM`,`ID_CIP`,`YEAR`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8
/*!50100 PARTITION BY RANGE (YEAR)
(PARTITION part1998 VALUES LESS THAN (1998) ENGINE = InnoDB,
 PARTITION part1999 VALUES LESS THAN (1999) ENGINE = InnoDB,
 PARTITION part2000 VALUES LESS THAN (2000) ENGINE = InnoDB,
 PARTITION part2001 VALUES LESS THAN (2001) ENGINE = InnoDB,
 PARTITION part2002 VALUES LESS THAN (2002) ENGINE = InnoDB,
 PARTITION part2003 VALUES LESS THAN (2003) ENGINE = InnoDB,
 PARTITION part2004 VALUES LESS THAN (2004) ENGINE = InnoDB,
 PARTITION part2005 VALUES LESS THAN (2005) ENGINE = InnoDB,
 PARTITION part2006 VALUES LESS THAN (2006) ENGINE = InnoDB,
 PARTITION part2007 VALUES LESS THAN (2007) ENGINE = InnoDB,
 PARTITION part2008 VALUES LESS THAN (2008) ENGINE = InnoDB,
 PARTITION part2009 VALUES LESS THAN (2009) ENGINE = InnoDB,
 PARTITION part2010 VALUES LESS THAN (2010) ENGINE = InnoDB,
 PARTITION part2011 VALUES LESS THAN (2011) ENGINE = InnoDB,
 PARTITION part2012 VALUES LESS THAN (2012) ENGINE = InnoDB,
 PARTITION part2013 VALUES LESS THAN (2013) ENGINE = InnoDB,
 PARTITION part2014 VALUES LESS THAN (2014) ENGINE = InnoDB,
 PARTITION part2015 VALUES LESS THAN (2015) ENGINE = InnoDB,
 PARTITION partMax VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */;
```


#### 加数据2

```Sql
DELIMITER //

CREATE PROCEDURE InsertDataIntoCipcode()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE random_year SMALLINT(5) unsigned;
    WHILE i <= 10000 DO
        SET random_year = FLOOR(1998 + RAND() * (2016 - 1998 + 1));
        INSERT INTO cipcode (ID_FORM, ID_CIP, YEAR)
        VALUES (i, i, random_year);
        SET i = i + 1;
    END WHILE;
END//

DELIMITER ;

```

调用之
```
CALL InsertDataIntoCipcode();
```

# Trigger Import

```Bash

rg="sunl-group"
region="centralus"
server="sunlmigrationtest-57"
target="sunlmigrationtest-57-flex"
user="cloudsa"

az account set --subscription 2941a09d-7bcf-42fe-91ca-1765f521c829

az mysql flexible-server import create \
--data-source-type "mysql_single"      \
--data-source $server                  \
--resource-group $rg                   \
--location $region                     \
--name $target                         \
--admin-user $user                     \
--sku-name "Standard_D4ds_v4"          \
--tier "GeneralPurpose"                \
--public-access 0.0.0.0                \
--storage-size 256                     \
--version 5.7                          \
--storage-auto-grow Enabled

```



```
rg="sunl-group"
region="centralus"
server="sunlmigrationtest-80"
target="sunlmigrationtest-80-flex"
user="cloudsa"

az account set --subscription 2941a09d-7bcf-42fe-91ca-1765f521c829

az mysql flexible-server import create \
--data-source-type "mysql_single"      \
--data-source $server                  \
--resource-group $rg                   \
--location $region                     \
--name $target                         \
--admin-user $user                     \
--sku-name "Standard_D4ds_v4"          \
--tier "GeneralPurpose"                \
--public-access 0.0.0.0                \
--storage-size 256                     \
--version 8.0.21                       \
--storage-auto-grow Enabled


```

# Try upgrade imported 5.7 to 8.0

```

|2023-10-13T06:59:44.750798Z 2 [ERROR] [MY-013524] [InnoDB] Table Partition: oltp01/students#P#p0 is not found in InnoDB dictionary|
|2023-10-13T06:59:44.750902Z 2 [ERROR] [MY-010767] [Server] Error in fixing SE data for 6f678.dac49|
|2023-10-13T06:59:44.779198Z 2 [ERROR] [MY-013524] [InnoDB] Table Partition: oltp01/cipcode#P#part1998 is not found in InnoDB dictionary|
|2023-10-13T06:59:44.779265Z 2 [ERROR] [MY-010767] [Server] Error in fixing SE data for 6f678.9e237|
|2023-10-13T06:59:49.379806Z 0 [ERROR] [MY-010022] [Server] Failed to Populate DD tables.|
|2023-10-13T06:59:49.379869Z 0 [ERROR] [MY-010119] [Server] Aborting|
```

# Tickets

- [Incident-420974619 Details - IcM (microsofticm.com)](https://portal.microsofticm.com/imp/v3/incidents/details/420974619/home)
- [Incident-427111434 Details - IcM (microsofticm.com)](https://portal.microsofticm.com/imp/v3/incidents/details/427111434/home)
- [Incident-423231616 Details - IcM (microsofticm.com)](https://portal.microsofticm.com/imp/v3/incidents/details/423231616/home)


# 代码路径

MySQL 在启动之后，会经历一系列的初始化过程。这个过程涉及到了大量的函数，因此这里我会提供一个简化的视图，来描述从 `main` 函数到 `ha_innobase::open_dict_table` 函数的主要步骤。

1. 首先，`main` 函数在 `sql/mysqld.cc` 文件中定义。这个函数首先初始化了一些基本的系统变量，并调用 `init_common_variables` 函数进行一些系统级别的初始化。

2. `init_common_variables` 函数会进行如下操作：初始化 MySQL 的线程处理库，设置默认的存储引擎，初始化查询缓存，初始化连接处理器等。

3. 在完成初始化之后，`main` 函数会调用 `mysqld_main` 函数来启动服务器。这个函数首先会调用 `init_server_components` 函数完成一些服务器组件的初始化。

4. `init_server_components` 函数会调用 `ha_initialize_handlerton` 函数来初始化所有的存储引擎，包括 InnoDB。

5. 对于 InnoDB，它的初始化是在 `innobase_init` 函数中完成的。这个函数会调用 `innobase_start_or_create_for_mysql` 函数。

6. `innobase_start_or_create_for_mysql` 函数中，会调用 `dict_boot` 函数初始化数据字典。

7. 最后，`dict_boot` 函数会调用 `ha_innobase::open_dict_table` 函数打开 InnoDB 的内部系统字典表。

注意，以上步骤只是简化的视图，实际的调用链可能会更复杂，并且可能涉及到更多的函数。每一步都涉及到了大量的代码，并且可能涉及到错误处理、日志记录等多种复杂的操作。

# 所有Partition相关路径

```C++
yoj@cn-yoj-201229:/opt/mysql/storage/innobase$ grep -riHn "#P#" .
./include/dict0dict.ic:2023:    return(strstr(table->name.m_name, "#p#")
./include/dict0dict.ic:2024:           || strstr(table->name.m_name, "#P#"));
./row/row0mysql.cc:5350:        is_old_part = strstr((char*)old_name, "#p#") ||
./row/row0mysql.cc:5353:        is_new_part = strstr((char*)new_name, "#p#") ||
./handler/ha_innodb.cc:6581:    /* We look for pattern #P# to see if the table is partitioned */
./handler/ha_innodb.cc:6584:    is_part = strstr(norm_name, "#p#");
./handler/ha_innodb.cc:6586:    is_part = strstr(norm_name, "#P#");
./handler/ha_innodb.cc:6981:            separator as "#P#". The text case is fixed even if
./handler/ha_innodb.cc:13362:           char*   is_part = strstr(norm_name, "#p#");
./handler/ha_innodb.cc:13364:           char*   is_part = strstr(norm_name, "#P#");
./handler/ha_innodb.cc:13961:           named table_name#P#partition_name[#SP#subpartition_name].
./handler/ha_innodb.cc:13985:                   is_part = strstr(norm_from, "#p#");
./handler/ha_innodb.cc:13987:                   is_part = strstr(norm_from, "#P#");
./handler/ha_innodb.cc:22247:        char*      is_part = strstr(tbname, "#p#");
./handler/ha_innodb.cc:22249:        char*      is_part = strstr(tbname, "#P#");
./handler/ha_innodb.cc:22299:   char*   is_part = strstr(tbname, "#p#");
./handler/ha_innodb.cc:22301:   char*   is_part = strstr(tbname, "#P#");
./handler/ha_innopart.cc:69:const char* part_sep = "#p#";
./handler/ha_innopart.cc:72:const char* part_sep = "#P#";
./handler/ha_innopart.cc:77:const char* part_sep_nix = "#P#";
./handler/ha_innopart.cc:1060:  /* TODO: Handle mismatching #P# vs #p# in upgrading to new DD instead!
./handler/ha_innopart.cc:1063:  on windows, partitioning never folds partition (and #P# separator).
./handler/ha_innopart.cc:2911:                          <name>#P#<part_name>#SP#<subpart_name>.
yoj@cn-yoj-201229:/opt/mysql/storage/innobase$ 
```

# 测试场景

`rename`: 需要测试    [TESTED]
`open_dict_table`: 这里jiaye已经改了
`delete_table`: delete table [TESTED]
`innobase_rename_table`: rename table   [TESTED]
`innobase_init_vc_templ`: 虚拟列    
`innobase_rename_vc_templ`: rename 虚拟列

# Sub partition


# 一个TODO

```c++
    /* TODO: Handle mismatching #P# vs #p# in upgrading to new DD instead!

    See bug#58406, The problem exists when moving partitioned tables

    between Windows and Unix-like platforms. InnoDB always folds the name

    on windows, partitioning never folds partition (and #P# separator).

    I.e. non of it follows lower_case_table_names correctly :( */
```

# 在single-server的文件名 lower_case=2

```SQL
yoj@cn-yoj-201229:~$ mysql -uyoj@yoj-test-migration -hyoj-test-migration.ossms-scus1-a.mscds.com -pfedora12@
mysql: [Warning] Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 65532
Server version: 5.6.47.0 MySQL Community Server (GPL)

Copyright (c) 2000, 2022, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> use information_schema;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql>  select * from INNODB_SYS_DATAFILES;
+-------+--------------------------------------------------------+
| SPACE | PATH                                                   |
+-------+--------------------------------------------------------+
|     2 | .\mysql\plugin.ibd                                     |
|     3 | .\mysql\servers.ibd                                    |
|     4 | .\mysql\help_topic.ibd                                 |
|     5 | .\mysql\help_category.ibd                              |
|     6 | .\mysql\help_relation.ibd                              |
|     7 | .\mysql\help_keyword.ibd                               |
|     8 | .\mysql\time_zone_name.ibd                             |
|     9 | .\mysql\time_zone.ibd                                  |
|    10 | .\mysql\time_zone_transition.ibd                       |
|    11 | .\mysql\time_zone_transition_type.ibd                  |
|    12 | .\mysql\time_zone_leap_second.ibd                      |
|    13 | .\mysql\innodb_table_stats.ibd                         |
|    14 | .\mysql\innodb_index_stats.ibd                         |
|    15 | .\mysql\slave_relay_log_info.ibd                       |
|    16 | .\mysql\slave_master_info.ibd                          |
|    17 | .\mysql\slave_worker_info.ibd                          |
|    18 | .\mysql\gtid_executed.ibd                              |
|    19 | .\mysql\server_cost.ibd                                |
|    20 | .\mysql\engine_cost.ibd                                |
|    21 | .\sys\sys_config.ibd                                   |
|    22 | .\mysql\__firewall_rules__.ibd                         |
|    23 | .\mysql\__az_replication_current_state__.ibd           |
|    24 | .\mysql\__az_action_history__.ibd                      |
|    25 | .\mysql\__az_replica_information__.ibd                 |
|    27 | .\mysql\__querystore_query_metrics__.ibd               |
|    31 | .\mysql\__querystore_query_text__.ibd                  |
|    32 | .\mysql\__querystore_event_wait__.ibd                  |
|    33 | .\mysql\__querystore_wait_stats_procedure_errors__.ibd |
|    34 | .\mysql\__recommendation_session__.ibd                 |
|    35 | .\mysql\__recommendation__.ibd                         |
|    37 | .\mysql\__script_version__.ibd                         |
|    98 | .\oltp01\students#p#p0.ibd                             |
|    99 | .\oltp01\students#p#p1.ibd                             |
|   100 | .\oltp01\students#p#p2.ibd                             |
|   101 | .\oltp01\students#p#p3.ibd                             |
|   102 | .\oltp01\students#p#p4.ibd                             |
|   103 | .\oltp01\students#p#p5.ibd                             |
|   104 | .\oltp01\students#p#p6.ibd                             |
|   105 | .\oltp01\students#p#p7.ibd                             |
|   106 | .\oltp01\students#p#p8.ibd                             |
|   107 | .\oltp01\students#p#p9.ibd                             |
|   108 | .\oltp01\students#p#p10.ibd                            |
|   109 | .\oltp01\students#p#p11.ibd                            |
|   110 | .\oltp01\students#p#p12.ibd                            |
|   111 | .\oltp01\students#p#p13.ibd                            |
|   112 | .\oltp01\students#p#p14.ibd                            |
|   113 | .\oltp01\students#p#p15.ibd                            |
|   114 | .\oltp01\students#p#p16.ibd                            |
|   115 | .\oltp01\students#p#p17.ibd                            |
|   116 | .\oltp01\students#p#p18.ibd                            |
|   117 | .\oltp01\students#p#p19.ibd                            |
|   118 | .\oltp01\students#p#p20.ibd                            |
|   119 | .\oltp01\students#p#p21.ibd                            |
|   120 | .\oltp01\students#p#p22.ibd                            |
|   121 | .\oltp01\students#p#p23.ibd                            |
|   122 | .\oltp01\students#p#p24.ibd                            |
|   123 | .\oltp01\students#p#p25.ibd                            |
|   124 | .\oltp01\students#p#p26.ibd                            |
|   125 | .\oltp01\students#p#p27.ibd                            |
|   126 | .\oltp01\students#p#p28.ibd                            |
|   127 | .\oltp01\students#p#p29.ibd                            |
|   128 | .\oltp01\students#p#p30.ibd                            |
|   129 | .\oltp01\students#p#p31.ibd                            |
|   130 | .\oltp01\students#p#p32.ibd                            |
|   131 | .\oltp01\students#p#p33.ibd                            |
|   132 | .\oltp01\students#p#p34.ibd                            |
|   133 | .\oltp01\students#p#p35.ibd                            |
|   134 | .\oltp01\students#p#p36.ibd                            |
|   135 | .\oltp01\students#p#p37.ibd                            |
|   136 | .\oltp01\students#p#p38.ibd                            |
|   137 | .\oltp01\students#p#p39.ibd                            |
|   138 | .\oltp01\cipcode#p#part1998.ibd                        |
|   139 | .\oltp01\cipcode#p#part1999.ibd                        |
|   140 | .\oltp01\cipcode#p#part2000.ibd                        |
|   141 | .\oltp01\cipcode#p#part2001.ibd                        |
|   142 | .\oltp01\cipcode#p#part2002.ibd                        |
|   143 | .\oltp01\cipcode#p#part2003.ibd                        |
|   144 | .\oltp01\cipcode#p#part2004.ibd                        |
|   145 | .\oltp01\cipcode#p#part2005.ibd                        |
|   146 | .\oltp01\cipcode#p#part2006.ibd                        |
|   147 | .\oltp01\cipcode#p#part2007.ibd                        |
|   148 | .\oltp01\cipcode#p#part2008.ibd                        |
|   149 | .\oltp01\cipcode#p#part2009.ibd                        |
|   150 | .\oltp01\cipcode#p#part2010.ibd                        |
|   151 | .\oltp01\cipcode#p#part2011.ibd                        |
|   152 | .\oltp01\cipcode#p#part2012.ibd                        |
|   153 | .\oltp01\cipcode#p#part2013.ibd                        |
|   154 | .\oltp01\cipcode#p#part2014.ibd                        |
|   155 | .\oltp01\cipcode#p#part2015.ibd                        |
|   156 | .\oltp01\cipcode#p#partmax.ibd                         |
+-------+--------------------------------------------------------+
90 rows in set (0.26 sec)

mysql>
```


但是migration过去之后，文件路径都是小写。

```SQL
mysql> select * from INNODB_SYS_DATAFILES;
+-------+--------------------------------------------------------+
| SPACE | PATH                                                   |
+-------+--------------------------------------------------------+
|     2 | .\mysql\plugin.ibd                                     |
|     3 | .\mysql\servers.ibd                                    |
|     4 | .\mysql\help_topic.ibd                                 |
|     5 | .\mysql\help_category.ibd                              |
|     6 | .\mysql\help_relation.ibd                              |
|     7 | .\mysql\help_keyword.ibd                               |
|     8 | .\mysql\time_zone_name.ibd                             |
|     9 | .\mysql\time_zone.ibd                                  |
|    10 | .\mysql\time_zone_transition.ibd                       |
|    11 | .\mysql\time_zone_transition_type.ibd                  |
|    12 | .\mysql\time_zone_leap_second.ibd                      |
|    13 | .\mysql\innodb_table_stats.ibd                         |
|    14 | .\mysql\innodb_index_stats.ibd                         |
|    15 | .\mysql\slave_relay_log_info.ibd                       |
|    16 | .\mysql\slave_master_info.ibd                          |
|    17 | .\mysql\slave_worker_info.ibd                          |
|    18 | .\mysql\gtid_executed.ibd                              |
|    19 | .\mysql\server_cost.ibd                                |
|    20 | .\mysql\engine_cost.ibd                                |
|    21 | .\sys\sys_config.ibd                                   |
|    22 | .\mysql\__firewall_rules__.ibd                         |
|    24 | .\mysql\__az_action_history__.ibd                      |
|    25 | .\mysql\__az_replica_information__.ibd                 |
|    27 | .\mysql\__querystore_query_metrics__.ibd               |
|    31 | .\mysql\__querystore_query_text__.ibd                  |
|    32 | .\mysql\__querystore_event_wait__.ibd                  |
|    33 | .\mysql\__querystore_wait_stats_procedure_errors__.ibd |
|    34 | .\mysql\__recommendation_session__.ibd                 |
|    35 | .\mysql\__recommendation__.ibd                         |
|    37 | .\mysql\__script_version__.ibd                         |
|    98 | .\oltp01\students#p#p0.ibd                             |
|    99 | .\oltp01\students#p#p1.ibd                             |
|   100 | .\oltp01\students#p#p2.ibd                             |
|   101 | .\oltp01\students#p#p3.ibd                             |
|   102 | .\oltp01\students#p#p4.ibd                             |
|   103 | .\oltp01\students#p#p5.ibd                             |
|   104 | .\oltp01\students#p#p6.ibd                             |
|   105 | .\oltp01\students#p#p7.ibd                             |
|   106 | .\oltp01\students#p#p8.ibd                             |
|   107 | .\oltp01\students#p#p9.ibd                             |
|   108 | .\oltp01\students#p#p10.ibd                            |
|   109 | .\oltp01\students#p#p11.ibd                            |
|   110 | .\oltp01\students#p#p12.ibd                            |
|   111 | .\oltp01\students#p#p13.ibd                            |
|   112 | .\oltp01\students#p#p14.ibd                            |
|   113 | .\oltp01\students#p#p15.ibd                            |
|   114 | .\oltp01\students#p#p16.ibd                            |
|   115 | .\oltp01\students#p#p17.ibd                            |
|   116 | .\oltp01\students#p#p18.ibd                            |
|   117 | .\oltp01\students#p#p19.ibd                            |
|   118 | .\oltp01\students#p#p20.ibd                            |
|   119 | .\oltp01\students#p#p21.ibd                            |
|   120 | .\oltp01\students#p#p22.ibd                            |
|   121 | .\oltp01\students#p#p23.ibd                            |
|   122 | .\oltp01\students#p#p24.ibd                            |
|   123 | .\oltp01\students#p#p25.ibd                            |
|   124 | .\oltp01\students#p#p26.ibd                            |
|   125 | .\oltp01\students#p#p27.ibd                            |
|   126 | .\oltp01\students#p#p28.ibd                            |
|   127 | .\oltp01\students#p#p29.ibd                            |
|   128 | .\oltp01\students#p#p30.ibd                            |
|   129 | .\oltp01\students#p#p31.ibd                            |
|   130 | .\oltp01\students#p#p32.ibd                            |
|   131 | .\oltp01\students#p#p33.ibd                            |
|   132 | .\oltp01\students#p#p34.ibd                            |
|   133 | .\oltp01\students#p#p35.ibd                            |
|   134 | .\oltp01\students#p#p36.ibd                            |
|   135 | .\oltp01\students#p#p37.ibd                            |
|   136 | .\oltp01\students#p#p38.ibd                            |
|   137 | .\oltp01\students#p#p39.ibd                            |
|   138 | .\oltp01\cipcode#p#part1998.ibd                        |
|   139 | .\oltp01\cipcode#p#part1999.ibd                        |
|   140 | .\oltp01\cipcode#p#part2000.ibd                        |
|   141 | .\oltp01\cipcode#p#part2001.ibd                        |
|   142 | .\oltp01\cipcode#p#part2002.ibd                        |
|   143 | .\oltp01\cipcode#p#part2003.ibd                        |
|   144 | .\oltp01\cipcode#p#part2004.ibd                        |
|   145 | .\oltp01\cipcode#p#part2005.ibd                        |
|   146 | .\oltp01\cipcode#p#part2006.ibd                        |
|   147 | .\oltp01\cipcode#p#part2007.ibd                        |
|   148 | .\oltp01\cipcode#p#part2008.ibd                        |
|   149 | .\oltp01\cipcode#p#part2009.ibd                        |
|   150 | .\oltp01\cipcode#p#part2010.ibd                        |
|   151 | .\oltp01\cipcode#p#part2011.ibd                        |
|   152 | .\oltp01\cipcode#p#part2012.ibd                        |
|   153 | .\oltp01\cipcode#p#part2013.ibd                        |
|   154 | .\oltp01\cipcode#p#part2014.ibd                        |
|   155 | .\oltp01\cipcode#p#part2015.ibd                        |
|   156 | .\oltp01\cipcode#p#partmax.ibd                         |
|   158 | ./mysql/__az_replication_current_state__.ibd           |
+-------+--------------------------------------------------------+
90 rows in set (0.00 sec)

mysql>
```

# 真实的Linux路径

```Bash
root [ /datashare/data/oltp01 ]# ls
cipcode#p#part1998.ibd  cipcode#p#part2005.ibd  cipcode#p#part2012.ibd  students#p#p0.ibd   students#p#p15.ibd  students#p#p21.ibd  students#p#p28.ibd  students#p#p34.ibd  students#p#p5.ibd
cipcode#p#part1999.ibd  cipcode#p#part2006.ibd  cipcode#p#part2013.ibd  students#p#p1.ibd   students#p#p16.ibd  students#p#p22.ibd  students#p#p29.ibd  students#p#p35.ibd  students#p#p6.ibd
cipcode#p#part2000.ibd  cipcode#p#part2007.ibd  cipcode#p#part2014.ibd  students#p#p10.ibd  students#p#p17.ibd  students#p#p23.ibd  students#p#p3.ibd   students#p#p36.ibd  students#p#p7.ibd
cipcode#p#part2001.ibd  cipcode#p#part2008.ibd  cipcode#p#part2015.ibd  students#p#p11.ibd  students#p#p18.ibd  students#p#p24.ibd  students#p#p30.ibd  students#p#p37.ibd  students#p#p8.ibd
cipcode#p#part2002.ibd  cipcode#p#part2009.ibd  cipcode#p#partmax.ibd   students#p#p12.ibd  students#p#p19.ibd  students#p#p25.ibd  students#p#p31.ibd  students#p#p38.ibd  students#p#p9.ibd
cipcode#p#part2003.ibd  cipcode#p#part2010.ibd  cipcode.frm             students#p#p13.ibd  students#p#p2.ibd   students#p#p26.ibd  students#p#p32.ibd  students#p#p39.ibd  students.frm
cipcode#p#part2004.ibd  cipcode#p#part2011.ibd  db.opt                  students#p#p14.ibd  students#p#p20.ibd  students#p#p27.ibd  students#p#p33.ibd  students#p#p4.ibd
root [ /datashare/data/oltp01 ]#
```
# 当添加了virtual column之后，立马变成了大写

```
root [ /datashare/data/oltp01 ]# ls
cipcode#P#part1998.ibd  cipcode#P#part2005.ibd  cipcode#P#part2012.ibd  students#p#p0.ibd   students#p#p15.ibd  students#p#p21.ibd  students#p#p28.ibd  students#p#p34.ibd  students#p#p5.ibd
cipcode#P#part1999.ibd  cipcode#P#part2006.ibd  cipcode#P#part2013.ibd  students#p#p1.ibd   students#p#p16.ibd  students#p#p22.ibd  students#p#p29.ibd  students#p#p35.ibd  students#p#p6.ibd
cipcode#P#part2000.ibd  cipcode#P#part2007.ibd  cipcode#P#part2014.ibd  students#p#p10.ibd  students#p#p17.ibd  students#p#p23.ibd  students#p#p3.ibd   students#p#p36.ibd  students#p#p7.ibd
cipcode#P#part2001.ibd  cipcode#P#part2008.ibd  cipcode#P#part2015.ibd  students#p#p11.ibd  students#p#p18.ibd  students#p#p24.ibd  students#p#p30.ibd  students#p#p37.ibd  students#p#p8.ibd
cipcode#P#part2002.ibd  cipcode#P#part2009.ibd  cipcode#P#partMax.ibd   students#p#p12.ibd  students#p#p19.ibd  students#p#p25.ibd  students#p#p31.ibd  students#p#p38.ibd  students#p#p9.ibd
cipcode#P#part2003.ibd  cipcode#P#part2010.ibd  cipcode.frm             students#p#p13.ibd  students#p#p2.ibd   students#p#p26.ibd  students#p#p32.ibd  students#p#p39.ibd  students.frm
cipcode#P#part2004.ibd  cipcode#P#part2011.ibd  db.opt                  students#p#p14.ibd  students#p#p20.ibd  students#p#p27.ibd  students#p#p33.ibd  students#p#p4.ibd
root [ /datashare/data/oltp01 ]#
```

