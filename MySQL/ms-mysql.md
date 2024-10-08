# 系统开始的设置


```Bash
#!/bin/bash

# Check if script is run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Install necessary packages
tdnf install -y mariner-repos-extended diffutils openssh-server openssh-clients keyutils cifs-utils vim git jemalloc capstone

# Enable and start sshd service
systemctl enable sshd.service
systemctl start sshd.service

# Allow inbound 3306 TCP connections
iptables -A INPUT -p tcp --dport 3306 -j ACCEPT

# Keep tmux alive after ssh disconnect
sed -i 's/#KillUserProcesses=no/KillUserProcesses=no/' /etc/systemd/logind.conf
systemctl restart systemd-logind.service

# Ease myfile/myfile-common/verlaine-client build
echo 'export DISTRO=linux.mariner' >> ~/.bashrc
source ~/.bashrc

# Uncomment and change the value of PubkeyAuthentication
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config # Uncomment and change the value of PasswordAuthentication
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config

# Restart the ssh service
systemctl restart sshd
```

# 挂载永久盘
帮我写一个linux shell脚本，这个脚本的参数是

[1] 磁盘路径，比如/dev/sdc
[2] 挂载路径

然后，我希望你帮我完成功能

[a] 将磁盘格式化为ext4，并挂载到/src
[b] 得到磁盘的blkid，然后将挂载信息到写入/etc/fstab


```Bash
#!/bin/bash

# Check if script is run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Check if both arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: \\$0 [DISK_PATH] [MOUNT_PATH]"
    exit 1
fi

DISK_PATH=$1
MOUNT_PATH=$2

umount $DISK_PATH

# Force format the disk to ext4
mkfs.ext4 -F $DISK_PATH

# Mount the disk
mkdir -p $MOUNT_PATH
mount $DISK_PATH $MOUNT_PATH

# Get the UUID of the disk
UUID=$(blkid -s UUID -o value $DISK_PATH)

# Check if the UUID is already in /etc/fstab
if ! grep -q "$UUID" /etc/fstab; then
    # If not, add the mount information to /etc/fstab
    echo "UUID=$UUID $MOUNT_PATH ext4 defaults 0 2" >> /etc/fstab
fi

echo "Disk $DISK_PATH formatted and mounted to $MOUNT_PATH."
```

# 设置ssh pub key


# 下载mysql

```
tdnf install -y git vim capstone
cd /src

git clone msdata@vs-ssh.visualstudio.com:v3/msdata/Database%20Systems/orcasql-mysql

cd /src/orcasql-mysql
git checkout 50091de2082e1adf002c9019239d7249a7362dbc
./setupnuget.sh yoj qnpb3zmflkeaqepfxr6rbrda36pmixib7t6msztgvyi6ivpvx5va
./init.sh
./build.sh -d
```

# 挂载pfs

```bash
#!/bin/bash

# Check if script is run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

mkdir -p /app/work
if [ ! -d "/etc/smbcredentials" ]; then
    mkdir -p /etc/smbcredentials
fi
if [ ! -f "/etc/smbcredentials/e9d8c9006526fsdata.cred" ]; then
    bash -c 'echo "username=e9d8c9006526fsdata" >> /etc/smbcredentials/e9d8c9006526fsdata.cred'
    bash -c 'echo "password=+rBfhhx8D4NbA2u9mTZXOhFMMvKLVniVIBvvcztRuy8L9xsxCcp37eW+3QwwSBdLX+GlqpuQjIhv+AStFtMeFg==" >> /etc/smbcredentials/e9d8c9006526fsdata.cred'
fi
chmod 600 /etc/smbcredentials/e9d8c9006526fsdata.cred

bash -c 'echo "//e9d8c9006526fsdata.file.core.windows.net/share /app/work cifs nofail,credentials=/etc/smbcredentials/e9d8c9006526fsdata.cred,dir_mode=0777,file_mode=0777,serverino,nosharesock,actimeo=30" >> /etc/fstab'
mount -t cifs //e9d8c9006526fsdata.file.core.windows.net/share /app/work -o credentials=/etc/smbcredentials/e9d8c9006526fsdata.cred,dir_mode=0777,file_mode=0777,serverino,nosharesock,actimeo=30
```

# 准备文件

将onebox flex server上的/mysql/lib目录复制到vm上相同的路径下。这里由于/mysql目录我们想直接复用/src这个永久盘。所以这里直接创建一个软链接。

```bash
mkdir -p /src/mysql
cp -rf lib /src/mysql
ln -s /src/mysql /mysql
```

并且保证有如下文件

```Bash
root [ /src/start ]# cat start.sh
#!/bin/bash

BASE="/src/start"
source ${BASE}/verlaine.env
export VML_FILE_SETTINGS_JSON_PATH="${BASE}/vml_file_settings.json"

LD_PRELOAD="/mysql/lib/private/libsyscall.so /mysql/lib/private/libmyaio.so /usr/lib/libjemalloc.so.2" \
 /src/orcasql-mysql/out/runtime_output_directory/mysqld                                                \
 --defaults-file=${BASE}/my.ini                                                                        \
 --basedir=/mysql                                                                                      \
 --datadir=/app/work/data                                                                              \
 --console                                                                                             \
 --core-file                                                                                           \
 --user=root
root [ /src/start ]# ls
my.ini  out.txt  setup.sh  start.sh  verlaine.env  vml_file_settings.json
root [ /src/start ]#
```

这里my.ini setup.sh verlaine.env vml_file_settings.json 都是从onebox中的flex server上copy得来

# 连接

```
 mysql -uazure_superuser
```

# 日志

注意：日志都是打到了/var/log/messages文件

# 打开文件流程

```Cpp

bool open_tables(THD *thd, Table_ref **start, uint *counter, uint flags,
                 Prelocking_strategy *prelocking_strategy) {
  /*
    We use pointers to "next_global" member in the last processed
    Table_ref element and to the "next" member in the last processed
    Sroutine_hash_entry element as iterators over, correspondingly, the table
    list and stored routines list which stay valid and allow to continue
    iteration when new elements are added to the tail of the lists.
  */
  Table_ref **table_to_open;
  TABLE *old_table;
  Sroutine_hash_entry **sroutine_to_open;
  Table_ref *tables;
  Open_table_context ot_ctx(thd, flags);
  bool error = false;
  bool some_routine_modifies_data = false;
  bool has_prelocking_list;
  DBUG_TRACE;
  bool audit_notified = false;

  sql_print_information("JIYOU bgin to work on open_tables, flag:%d", flags);

restart:
  /*
    Close HANDLER tables which are marked for flush or against which there
    are pending exclusive metadata locks. This is needed both in order to
    avoid deadlocks and to have a point during statement execution at
    which such HANDLERs are closed even if they don't create problems for
    the current session (i.e. to avoid having a DDL blocked by HANDLERs
    opened for a long time).
  */
  if (!thd->handler_tables_hash.empty()) mysql_ha_flush(thd);

  has_prelocking_list = thd->lex->requires_prelocking();
  table_to_open = start;
  old_table = *table_to_open ? (*table_to_open)->table : nullptr;
  sroutine_to_open = &thd->lex->sroutines_list.first;
  *counter = 0;

  sql_print_information("JIYOU has_prelocking_list:%d old_table:%p", has_prelocking_list, old_table);

  if (!(thd->state_flags & Open_tables_state::SYSTEM_TABLES))
    THD_STAGE_INFO(thd, stage_opening_tables);

  /*
    If we are executing LOCK TABLES statement or a DDL statement
    (in non-LOCK TABLES mode) we might have to acquire upgradable
    semi-exclusive metadata locks (SNW or SNRW) on some of the
    tables to be opened.
    When executing CREATE TABLE .. If NOT EXISTS .. SELECT, the
    table may not yet exist, in which case we acquire an exclusive
    lock.
    We acquire all such locks at once here as doing this in one
    by one fashion may lead to deadlocks or starvation. Later when
    we will be opening corresponding table pre-acquired metadata
    lock will be reused (thanks to the fact that in recursive case
    metadata locks are acquired without waiting).
  */
  if (!(flags & (MYSQL_OPEN_HAS_MDL_LOCK | MYSQL_OPEN_FORCE_SHARED_MDL |
                 MYSQL_OPEN_FORCE_SHARED_HIGH_PRIO_MDL))) {
    sql_print_information("JIYOU open_tables, get_and_lock_tablespace_names AA");
    if (thd->locked_tables_mode) {
      sql_print_information("JIYOU open_tables, get_and_lock_tablespace_names BB");
      /*
        Under LOCK TABLES, we can't acquire new locks, so we instead
        need to check if appropriate locks were pre-acquired.
      */
      Table_ref *end_table = thd->lex->first_not_own_table();
      if (open_tables_check_upgradable_mdl(thd, *start, end_table) ||
          acquire_backup_lock_in_lock_tables_mode(thd, *start, end_table)) {
        error = true;
        sql_print_information("JIYOU open_tables, get_and_lock_tablespace_names CC");
        goto err;
      }
    } else {
      sql_print_information("JIYOU open_tables, get_and_lock_tablespace_names DD");
      Table_ref *table;
      if (lock_table_names(thd, *start, thd->lex->first_not_own_table(),
                           ot_ctx.get_timeout(), flags)) {
        sql_print_information("JIYOU open_tables, get_and_lock_tablespace_names EE");
        error = true;
        goto err;
      }
      for (table = *start; table && table != thd->lex->first_not_own_table();
           table = table->next_global) {
        sql_print_information("JIYOU open_tables, get_and_lock_tablespace_names FF");
        if (table->mdl_request.is_ddl_or_lock_tables_lock_request() ||
            table->open_strategy == Table_ref::OPEN_FOR_CREATE) {
          //
          sql_print_information("JIYOU open_tables, get_and_lock_tablespace_names GG");
          table->mdl_request.ticket = nullptr;
        }
      }
    }
  }

  /*
    Perform steps of prelocking algorithm until there are unprocessed
    elements in prelocking list/set.
  */
  while (*table_to_open ||
         (thd->locked_tables_mode <= LTM_LOCK_TABLES && *sroutine_to_open)) {
    /*
      For every table in the list of tables to open, try to find or open
      a table.
    */
    sql_print_information("JIYOU open_tables, get_and_lock_tablespace_names HH");
    for (tables = *table_to_open; tables;
         table_to_open = &tables->next_global, tables = tables->next_global) {
      sql_print_information("JIYOU open_tables, get_and_lock_tablespace_names II");
      old_table = (*table_to_open)->table;
      error = open_and_process_table(thd, thd->lex, tables, counter,
                                     prelocking_strategy, has_prelocking_list,
                                     &ot_ctx);
      sql_print_information("JIYOU open_tables, get_and_lock_tablespace_names JJ");
      if (error) {
        sql_print_information("JIYOU open_tables, get_and_lock_tablespace_names KK");
        if (ot_ctx.can_recover_from_failed_open()) {
          sql_print_information("JIYOU open_tables, get_and_lock_tablespace_names LL");
          /*
            We have met exclusive metadata lock or old version of table.
            Now we have to close all tables and release metadata locks.
            We also have to throw away set of prelocked tables (and thus
            close tables from this set that were open by now) since it
            is possible that one of tables which determined its content
            was changed.

            Instead of implementing complex/non-robust logic mentioned
            above we simply close and then reopen all tables.

            We have to save pointer to table list element for table which we
            have failed to open since closing tables can trigger removal of
            elements from the table list (if MERGE tables are involved),
          */
          close_tables_for_reopen(thd, start, ot_ctx.start_of_statement_svp());

          /*
            Here we rely on the fact that 'tables' still points to the valid
            Table_ref element. Although currently this assumption is valid
            it may change in future.
          */
          if (ot_ctx.recover_from_failed_open()) {
            sql_print_information("JIYOU open_tables, get_and_lock_tablespace_names MM");
            goto err;
          }

          /* Re-open temporary tables after close_tables_for_reopen(). */
          if (open_temporary_tables(thd, *start)) {
            sql_print_information("JIYOU open_tables, get_and_lock_tablespace_names NN");
            goto err;
          }

          sql_print_information("JIYOU open_tables, get_and_lock_tablespace_names OO");
          error = false;
          goto restart;
        }
        sql_print_information("JIYOU open_tables, get_and_lock_tablespace_names PP");
        goto err;
      }

      DEBUG_SYNC(thd, "open_tables_after_open_and_process_table");
    }

    /*
      Iterate through set of tables and generate table access audit events.
    */
    if (!audit_notified && mysql_audit_table_access_notify(thd, *start)) {
      sql_print_information("JIYOU open_tables, get_and_lock_tablespace_names QQ");
      error = true;
      goto err;
    }

    /*
      Event is not generated in the next loop. It may contain duplicated
      table entries as well as new tables discovered for stored procedures.
      Events for these tables will be generated during the queries of these
      stored procedures.
    */
    audit_notified = true;
    // ... 
}
```


根据我添加的消息，输出如下 ：

```bash
 JIYOU bgin to work on open_tables, flag:18434
 JIYOU has_prelocking_list:0 old_table:(nil)
 JIYOU open_tables, get_and_lock_tablespace_names AA
 JIYOU open_tables, get_and_lock_tablespace_names DD
 JIYOU open_tables, get_and_lock_tablespace_names FF
 JIYOU open_tables, get_and_lock_tablespace_names HH
 JIYOU open_tables, get_and_lock_tablespace_names II
 JIYOU open_tables, get_and_lock_tablespace_names JJ
 JIYOU open_tables, get_and_lock_tablespace_names RR
 JIYOU open_tables, get_and_lock_tablespace_names JJ
 JIYOU open_tables, get_and_lock_tablespace_names KK
 JIYOU open_tables, get_and_lock_tablespace_names PP

```


```Cpp
  if (!(share = get_table_share_with_discover(
            thd, table_list, key, key_length,
            flags & MYSQL_OPEN_SECONDARY_ENGINE, &error))) {
    mysql_mutex_unlock(&LOCK_open);

      sql_print_information("JIYOU open_table 50: %s.%s error: %d at %s(%s:%d)", table_list->db,
                        table_list->table_name, error, __FUNCTION__, __FILE__, __LINE__);
    /*
      If thd->is_error() is not set, we either need discover
      (error == 7), or the error was silenced by the prelocking
      handler (error == 0), in which case we should skip this
      table.
    */
    if (error == 7 && !thd->is_error()) {
      sql_print_information("JIYOU open_table 51: %s.%s at %s(%s:%d)", table_list->db,
                        table_list->table_name, __FUNCTION__, __FILE__, __LINE__);
      (void)ot_ctx->request_backoff_action(Open_table_context::OT_DISCOVER,
                                           table_list);
    }
        sql_print_information("JIYOU open_table 52: %s.%s error:%d at %s(%s:%d)", table_list->db,
                        table_list->table_name, error, __FUNCTION__, __FILE__, __LINE__);
    return true;
  }
```

这里需要注意，虽然这个局部变量error没有出错，但是由于share没有找到。所以会从50 -> 52

那么接下来就需要看log时，注意下面这一段是要删除的。

```bash
(gdb) bt
#0  open_and_process_table (ot_ctx=0x7acde5dfb1d0, has_prelocking_list=false,
    prelocking_strategy=0x7acde5dfb278, counter=0x7ac714428058, tables=0x7acde5dfb530,
    lex=0x7ac714428000, thd=0x7ac714405000) at /src/orcasql-mysql-release/sql/sql_base.cc:5196
#1  open_tables (thd=thd@entry=0x7ac714405000, start=start@entry=0x7acde5dfb268,
    counter=0x7ac714428058, flags=flags@entry=1024,
    prelocking_strategy=prelocking_strategy@entry=0x7acde5dfb278)
    at /src/orcasql-mysql-release/sql/sql_base.cc:6233
#2  0x0000595e9e6572b0 in open_tables_for_query (thd=thd@entry=0x7ac714405000,
    tables=<optimized out>, tables@entry=0x7acde5dfb530, flags=flags@entry=1024)
    at /src/orcasql-mysql-release/sql/sql_base.cc:7143
#3  0x0000595e9e7661f5 in mysqld_list_fields (thd=thd@entry=0x7ac714405000,
    table_list=table_list@entry=0x7acde5dfb530, wild=wild@entry=0x7ac7145d1150 "")
    at /src/orcasql-mysql-release/sql/sql_show.cc:1379
#4  0x0000595e9e6f530a in dispatch_command (thd=0x7ac714405000, com_data=<optimized out>,
    command=COM_FIELD_LIST) at /src/orcasql-mysql-release/sql/sql_parse.cc:2620
#5  0x0000595e9e6f58b7 in do_command (thd=thd@entry=0x7ac714405000)
    at /src/orcasql-mysql-release/sql/sql_parse.cc:1825
#6  0x0000595e9e846db8 in handle_connection (arg=arg@entry=0x7acdcbdfe8f0)
    at /src/orcasql-mysql-release/sql/conn_handler/connection_handler_per_thread.cc:320
#7  0x0000595e9fdca205 in pfs_spawn_thread (arg=0x7acdf02f8ee0)
    at /src/orcasql-mysql-release/storage/perfschema/pfs.cc:3042
#8  0x00007acdf0e8a1d2 in start_thread () from /lib/libc.so.6
#9  0x00007acdf0f0be90 in clone3 () from /lib/libc.so.6
```

![[Pasted image 20240307104137.png]]


![[Pasted image 20240307104304.png]]

# 可能的地方
断点 sql_base.cc:830
这里read_histogram将open_table_err设置为true


![[Pasted image 20240307134019.png]]



![[Pasted image 20240307134057.png]]

![[Pasted image 20240307144738.png]]

![[Pasted image 20240307144750.png]]

# make some code change

sql_base.cc 626 -> change return true -> return false; check table success.

yoj@yoj-debug-mysql [ ~ ]$ cn
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 9
Server version: 8.0.35 Source distribution

Copyright (c) 2000, 2023, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> use prd-spark-trf-be-reporting;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> check table parties_summary;
+--------------------------------------------+-------+----------+----------+
| Table                                      | Op    | Msg_type | Msg_text |
+--------------------------------------------+-------+----------+----------+
| prd-spark-trf-be-reporting.parties_summary | check | status   | OK       |
+--------------------------------------------+-------+----------+----------+
1 row in set (17.10 sec)

mysql>


# Histogram Stats

```
SELECT 
    `schema_name`, 
    `table_name`, 
    `column_name`
FROM 
    `information_schema`.`column_statistics`

```

more infor found in: https://dev.mysql.com/blog-archive/histogram-statistics-in-mysql/

```
mysql> select SCHEMA_NAME,TABLE_NAME,COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMN_STATISTICS where SCHEMA_NAME='prd-spark-trf-be-reporting' and TABLE_NAME='movements'\g;
+----------------------------+------------+----------------+
| SCHEMA_NAME                | TABLE_NAME | COLUMN_NAME    |
+----------------------------+------------+----------------+
| prd-spark-trf-be-reporting | movements  | currency       |
| prd-spark-trf-be-reporting | movements  | date           |
| prd-spark-trf-be-reporting | movements  | programme_id   |
| prd-spark-trf-be-reporting | movements  | seller_id      |
| prd-spark-trf-be-reporting | movements  | step_number    |
| prd-spark-trf-be-reporting | movements  | transaction_id |
+----------------------------+------------+----------------+
6 rows in set (0.00 sec)

ERROR:
No query specified

mysql>
```

we can find the info:

```
mysql> select * FROM INFORMATION_SCHEMA.COLUMN_STATISTICS where SCHEMA_NAME='prd-spark-trf-be-reporting' and TABLE_NAME='movements' and COLUMN_NAME='date'\g;
```

```
| prd-spark-trf-be-reporting | movements  | date        | {"buckets": [["2021-02-01", 0.0005930172222084949], ["2021-02-02", 0.001208684407765231], ["2021-02-03", 0.0017934652796652746], ["2021-02-04", 0.003080395015360793], ["2021-02-05", 0.004208775007618624], ["2021-02-06", 0.00479561496709578], ["2021-02-07", 0.0053598049632246954], ["2021-02-08", 0.006346107912661741], ["2021-02-09", 0.007449778853994217], ["2021-02-10", 0.00865228599902811], ["2021-02-11", 0.00962829351057959], ["2021-02-12", 0.01081432795499658], ["2021-02-13", 0.011415581527513527], ["2021-02-14", 0.011996244224259345], ["2021-02-15", 0.013081383377397806], ["2021-02-16", 0.01415416800507359], ["2021-02-17", 0.015255779858828955], ["2021-02-18", 0.01635327353743009], ["2021-02-19", 0.017423999077528764], ["2021-02-20", 0.01801083903700592], ["2021-02-21", 0.01859973808406019], ["2021-02-22", 0.01968281814962154], ["2021-02-23", 0.020774134565491337], ["2021-02-24", 0.02183662375528156], ["2021-02-25", 0.02297324009784784], ["2021-02-26", 0.02407279286402609], ["2021-02-27", 0.024651396473194795], ["2021-02-28", 0.025260886396020192], ["2021-03-01", 0.025880671756731154], ["2021-03-02", 0.0267866702906608], ["2021-03-03", 0.02793152298353553], ["2021-03-04", 0.028635730934908118], ["2021-03-05", 0.02980117450355398], ["2021-03-06", 0.030431255302150507], ["2021-03-07", 0.031016036174050552], ["2021-03-08", 0.03217118430481085], ["2021-03-09", 0.0333345687858796], ["2021-03-10", 0.03444441698994342], ["2021-03-11", 0.03552955614308188], ["2021-03-12", 0.03670117697445908], ["2021-03-13", 0.03735596682398096], ["2021-03-14", 0.037965456746806354], ["2021-03-15", 0.03854406035597506], ["2021-03-16", 0.039112368527258204], ["2021-03-17", 0.03967244034823289], ["2021-03-18", 0.040226334906476244], ["2021-03-19", 0.04077611128956537], ["2021-03-20", 0.04107673807582384], ["2021-03-21", 0.041381483037236544], ["2021-03-22", 0.04193331850790278], ["2021-03-23", 0.042485153978569015], ["2021-03-24", 0.04305346214985216], ["2021-03-25", 0.043609415795672624], ["2021-03-26", 0.04420037393030401], ["2021-03-27", 0.0444886461910998], ["2021-03-28", 0.04478515480220405], ["2021-03-29", 0.04534110844802451], ["2021-03-30", 0.0459011802689992], ["2021-03-31", 0.04647772479059079], ["2021-04-01", 0.047031619348834146], ["2021-04-02", 0.04734048248540107], ["2021-04-03", 0.04763905018408243], ["2021-04-04", 0.047947913320649356], ["2021-04-05", 0.04825265828206206], ["2021-04-06", 0.048864207292464566], ["2021-04-07", 0.04944281090163327], ["2021-04-08", 0.05006671443749846], ["2021-04-09", 0.050641199871512936], ["2021-04-10", 0.05093770848261718], ["2021-04-11", 0.05125068979433833], ["2021-04-12", 0.051769579863770766], ["2021-04-13", 0.05208256117549192], ["2021-04-14", 0.05270028744862577], ["2021-04-15", 0.05305239142431206], ["2021-04-16", 0.05365364499682901], ["2021-04-17", 0.053985158096744174], ["2021-04-18", 0.05430637575877378], ["2021-04-19", 0.05483556126609177], ["2021-04-20", 0.0554018103497978], ["2021-04-21", 0.05595158673288692], ["2021-04-22", 0.056484890415359146], ["2021-04-23", 0.05707996672514475], ["2021-04-24", 0.05739088894928879], ["2021-04-25", 0.05770181117343282], ["2021-04-26", 0.058243351206213496], ["2021-04-27", 0.0585645688682431], ["2021-04-28", 0.058889904705426925], ["2021-04-29", 0.05938614481151112], ["2021-04-30", 0.05996268933310271], ["2021-05-01", 0.060271552469669636], ["2021-05-02", 0.06057423834350522], ["2021-05-03", 0.060916046881305946], ["2021-05-04", 0.06146788235197218], ["2021-05-05", 0.06209178588783737], ["2021-05-06", 0.06267038949700607], ["2021-05-07", 0.06323046131798075], ["2021-05-08", 0.06358668346882128], ["2021-05-09", 0.06392437383146778], ["2021-05-10", 0.06454210010460162], ["2021-05-11", 0.06507746287465097], ["2021-05-12", 0.06568695279747637], ["2021-05-13", 0.06603493859800844], ["2021-05-14", 0.06664648760841095], ["2021-05-15", 0.06698211888348034], ["2021-05-16", 0.06729098202004727], ["2021-05-17", 0.06787576289194731], ["2021-05-18", 0.06847701646446426], ["2021-05-19", 0.06908032912455832], ["2021-05-20", 0.06963422368280167], ["2021-05-21", 0.0702169454671246], ["2021-05-22", 0.07055051765461688], ["2021-05-23", 0.07087997166695494], ["2021-05-24", 0.07120118932898453], ["2021-05-25", 0.07174684753691943], ["2021-05-26", 0.0723686919852075], ["2021-05-27", 0.07297200464530156], ["2021-05-28", 0.07356708095508717], ["2021-05-29", 0.07390271223015656], ["2021-05-30", 0.07424452076795729], ["2021-05-31", 0.07532760083351864], ["2021-06-01", 0.07706547074860187], ["2021-06-02", 0.07923574905487879], ["2021-06-03", 0.0811795277276733], ["2021-06-04", 0.08341775592399495], ["2021-06-05", 0.08460584945598905], ["2021-06-06", 0.08587218831591344], ["2021-06-07", 0.08821337089109073], ["2021-06-08", 0.09059367613023316], ["2021-06-09", 0.09403235238401159], ["2021-06-10", 0.09645589846227338], ["2021-06-11", 0.09884032187657005], ["2021-06-12", 0.10009842438618599], ["2021-06-13", 0.10141624043553821], ["2021-06-14", 0.10378419114921796], ["2021-06-15", 0.10617067365109173], ["2021-06-16", 0.10841713819772182], ["2021-06-17", 0.11092922504179947], ["2021-06-18", 0.11346602093680248], ["2021-06-19", 0.1148167823873885], ["2021-06-20", 0.11613871661189494], ["2021-06-21", 0.11872287152117154], ["2021-06-22", 0.12133379456895062], ["2021-06-23", 0.12388912225214764], ["2021-06-24", 0.12647121807384712], ["2021-06-25", 0.1290368411949297], ["2021-06-26", 0.13047614341133157], ["2021-06-27", 0.13190103201469364], ["2021-06-28", 0.13461490944132834], ["2021-06-29", 0.13711875993509753], ["2021-06-30", 0.1398594055002347], ["2021-07-01", 0.14270918270695887], ["2021-07-02", 0.14543335557147916], ["2021-07-03", 0.1469962030425078], ["2021-07-04", 0.14849727788622305], ["2021-07-05", 0.15004365265663477], ["2021-07-06", 0.15310551588380156], ["2021-07-07", 0.15597382487871972], ["2021-07-08", 0.15875153402024492], ["2021-07-09", 0.16161778392758597], ["2021-07-10", 0.16323622676319666], ["2021-07-11", 0.1648649650366929], ["2021-07-12", 0.16767767866702904], ["2021-07-13", 0.17084661444820567], ["2021-07-14", 0.17431617701564078], ["2021-07-15", 0.17871438808035378], ["2021-07-16", 0.18317025359722594], ["2021-07-17", 0.18551967252271168], ["2021-07-18", 0.187897918674277], ["2021-07-19", 0.1923105433520298], ["2021-07-20", 0.19666757266520055], ["2021-07-21", 0.20119550624727167], ["2021-07-22", 0.2055690082610593], ["2021-07-23", 0.21024519614868253], ["2021-07-24", 0.2127099239784866], ["2021-07-25", 0.2151828881585991], ["2021-07-26", 0.21995791224992375], ["2021-07-27", 0.22448172765684063], ["2021-07-28", 0.22917438824508077], ["2021-07-29", 0.23361172197375893], ["2021-07-30", 0.23834762340111842], ["2021-07-31", 0.24084117845700206], ["2021-08-01", 0.24340886066566175], ["2021-08-02", 0.24846392066747375], ["2021-08-03", 0.25109543459102396], ["2021-08-04", 0.2536425259239125], ["2021-08-05", 0.25621432630772645], ["2021-08-06", 0.25871199953876434], ["2021-08-07", 0.26003187467569366], ["2021-08-08", 0.26142793605297615], ["2021-08-09", 0.26407798176472036], ["2021-08-10", 0.2666456639733801], ["2021-08-11", 0.26918040078080596], ["2021-08-12", 0.2718860418571322], ["2021-08-13", 0.274674046436543], ["2021-08-14", 0.2761442349666015], ["2021-08-15", 0.27766384159851076], ["2021-08-16", 0.2804291962145733], ["2021-08-17", 0.2832377916697552], ["2021-08-18", 0.286171991467141], ["2021-08-19", 0.28922561834399935], ["2021-08-20", 0.2922154135059672], ["2021-08-21", 0.2939018062316226], ["2021-08-22", 0.295606730745472], ["2021-08-23", 0.2988250846284993], ["2021-08-24", 0.3019487204829795], ["2021-08-25", 0.30509088812565366], ["2021-08-26", 0.3084204327378451], ["2021-08-27", 0.31159348669417597], ["2021-08-28", 0.31338283379868703], ["2021-08-29", 0.3151927717789692], ["2021-08-30", 0.31701300519713693], ["2021-08-31", 0.32058346305585056], ["2021-09-01", 0.32410656190029064], ["2021-09-02", 0.327452579213099], ["2021-09-03", 0.3307162330228228], ["2021-09-04", 0.33247057563852295], ["2021-09-05", 0.33431551810761606], ["2021-09-06", 0.33637254659715177], ["2021-09-07", 0.33985240460247246], ["2021-09-08", 0.34328490359351954], ["2021-09-09", 0.3466679844827159], ["2021-09-10", 0.3500531244594894], ["2021-09-11", 0.35189188966585117], ["2021-09-12", 0.35374712757282983], ["2021-09-13", 0.3572372810160361], ["2021-09-14", 0.36064507095615783], ["2021-09-15", 0.3641166926111701], ["2021-09-16", 0.3675841960910281], ["2021-09-17", 0.37107434953423435], ["2021-09-18", 0.3730551917834169], ["2021-09-19", 0.37499073410590295], ["2021-09-20", 0.37847471028637786], ["2021-09-21", 0.3819607455544299], ["2021-09-22", 0.38550443527464107], ["2021-09-23", 0.389153138461285], ["2021-09-24", 0.39265564642995393], ["2021-09-25", 0.39469414313129564], ["2021-09-26", 0.3966935171686722], ["2021-09-27", 0.4003545748807788], ["2021-09-28", 0.4038364919736766], ["2021-09-29", 0.40745842702181806], ["2021-09-30", 0.411234793638243], ["2021-10-01", 0.4149370331018919], ["2021-10-02", 0.41696317527777094], ["2021-10-03", 0.4189460766145306], ["2021-10-04", 0.42259683888875166], ["2021-10-05", 0.42615906039715684], ["2021-10-06", 0.4298921861744624], ["2021-10-07", 0.4334605849455989], ["2021-10-08", 0.4371957698104816], ["2021-10-09", 0.43927338917578845], ["2021-10-10", 0.4413880721174833], ["2021-10-11", 0.4437745546193571], ["2021-10-12", 0.4478803752481201], ["2021-10-13", 0.4518255870458683], ["2021-10-14", 0.455597835487139], ["2021-10-15", 0.45934949305263856], ["2021-10-16", 0.46149712139556726], ["2021-10-17", 0.4637024041906551], ["2021-10-18", 0.4676393796380948], ["2021-10-19", 0.47161135957434547], ["2021-10-20", 0.47544538064292957], ["2021-10-21", 0.47940294696614044], ["2021-10-22", 0.4832925633993066], ["2021-10-23", 0.48551225980743423], ["2021-10-24", 0.48779166975529814], ["2021-10-25", 0.4902975793366445], ["2021-10-26", 0.4946525495622381], ["2021-10-27", 0.4986327658487972], ["2021-10-28", 0.502590332172008], ["2021-10-29", 0.506531425794602], ["2021-10-30", 0.508794363041849], ["2021-10-31", 0.5110655366394045], ["2021-11-01", 0.5148377850806751], ["2021-11-02", 0.518723283338687], ["2021-11-03", 0.5227940994786391], ["2021-11-04", 0.5268319702173574], ["2021-11-05", 0.530731882088409], ["2021-11-06", 0.5330545328753923], ["2021-11-07", 0.535401892713301], ["2021-11-08", 0.5392791546210044], ["2021-11-09", 0.5433499707609565], ["2021-11-10", 0.5475093276667244], ["2021-11-11", 0.5500317099486877], ["2021-11-12", 0.5543866801742813], ["2021-11-13", 0.5567587490631153], ["2021-11-14", 0.5591143452513324], ["2021-11-15", 0.5633848928862644], ["2021-11-16", 0.5674515908510622], ["2021-11-17", 0.571680956734452], ["2021-11-18", 0.575770304662598], ["2021-11-19", 0.5799173070429032], ["2021-11-20", 0.5822955531944686], ["2021-11-21", 0.5846799766087653], ["2021-11-22", 0.588872278915767], ["2021-11-23", 0.5930048676830324], ["2021-11-24", 0.5972054063403426], ["2021-11-25", 0.5998430975266241], ["2021-11-26", 0.6037594820982928], ["2021-11-27", 0.606154200950475], ["2021-11-28", 0.6086065742548163], ["2021-11-29", 0.6122944001054255], ["2021-11-30", 0.6164702297118103], ["2021-12-01", 0.6204936868374887], ["2021-12-02", 0.6248363025376197], ["2021-12-03", 0.6290862592967805], ["2021-12-04", 0.6315736370899329], ["2021-12-05", 0.6339992422557718], ["2021-12-06", 0.6381688945994253], ["2021-12-07", 0.6423653150815812], ["2021-12-08", 0.6465514401258516], ["2021-12-09", 0.6509414148402561], ["2021-12-10", 0.6554219894080536], ["2021-12-11", 0.6580699760322207], ["2021-12-12", 0.6607323762694276], ["2021-12-13", 0.6652891370775783], ["2021-12-14", 0.669736766244142], ["2021-12-15", 0.6739187731132582], ["2021-12-16", 0.6782263843245783], ["2021-12-17", 0.6824948728719331], ["2021-12-18", 0.6849163598626178], ["2021-12-19", 0.687348142291188], ["2021-12-20", 0.6916022172255031], ["2021-12-21", 0.6957595150436939], ["2021-12-22", 0.6999929991022379], ["2021-12-23", 0.7042614876495927], ["2021-12-24", 0.7081634586082215], ["2021-12-25", 0.7105643547231351], ["2021-12-26", 0.7129652508380486], ["2021-12-27", 0.7154443922808925], ["2021-12-28", 0.7180203108398606], ["2021-12-29", 0.7227335623038719], ["2021-12-30", 0.7269485145742218], ["2021-12-31", 0.7307784174676517], ["2022-01-01", 0.7345321341207284], ["2022-01-02", 0.7370050983008409], ["2022-01-03", 0.7395007124443017], ["2022-01-04", 0.7435015196066319], ["2022-01-05", 0.7479429715104643], ["2022-01-06", 0.7522691145099784], ["2022-01-07", 0.7567208618516963], ["2022-01-08", 0.7593338439870525], ["2022-01-09", 0.761899467108135], ["2022-01-10", 0.7665427095945245], ["2022-01-11", 0.7709594524474316], ["2022-01-12", 0.7753803134754929], ["2022-01-13", 0.779799115415977], ["2022-01-14", 0.7842240946191925], ["2022-01-15", 0.786806190440892], ["2022-01-16", 0.7894047589632084], ["2022-01-17", 0.7922051180680818], ["2022-01-18", 0.7970872147134164], ["2022-01-19", 0.8016007346824477], ["2022-01-20", 0.8060668956372055], ["2022-01-21", 0.8106421882335502], ["2022-01-22", 0.8132984112080257], ["2022-01-23", 0.8158372661906058], ["2022-01-24", 0.8204660950639554], ["2022-01-25", 0.8250434467478772], ["2022-01-26", 0.829474603213824], ["2022-01-27", 0.8339387050810046], ["2022-01-28", 0.8384295750866877], ["2022-01-29", 0.8410487344847752], ["2022-01-30", 0.8436473030070917], ["2022-01-31", 0.848179354764317], ["2022-02-01", 0.8525981567048012], ["2022-02-02", 0.8571425629874893], ["2022-02-03", 0.8615593058403963], ["2022-02-04", 0.8659616350802636], ["2022-02-05", 0.8685890308286596], ["2022-02-06", 0.8712123084019013], ["2022-02-07", 0.8757402419839725], ["2022-02-08", 0.880111684910183], ["2022-02-09", 0.884584023127672], ["2022-02-10", 0.8891201930600516], ["2022-02-11", 0.8935184041247647], ["2022-02-12", 0.8961663907489318], ["2022-02-13", 0.8988843863507208], ["2022-02-14", 0.9036758831426623], ["2022-02-15", 0.9084076663948676], ["2022-02-16", 0.9129706044657496], ["2022-02-17", 0.9175603106751341], ["2022-02-18", 0.9219770535280412], ["2022-02-19", 0.9245612084373177], ["2022-02-20", 0.927213313236639], ["2022-02-21", 0.9299395451887364], ["2022-02-22", 0.9349451870886978], ["2022-02-23", 0.9395987250129728], ["2022-02-24", 0.9441698994341633], ["2022-02-25", 0.9486298831261897], ["2022-02-26", 0.9513252287646303], ["2022-02-27", 0.9540082198776083], ["2022-02-28", 0.9586164578751868], ["2022-03-01", 0.9632720548870389], ["2022-03-02", 0.9679173564610055], ["2022-03-03", 0.9725564807722408], ["2022-03-04", 0.9771214779306999], ["2022-03-05", 0.9797447555039417], ["2022-03-06", 0.9822980240995616], ["2022-03-07", 0.9870133346511499], ["2022-03-08", 0.9914939092189474], ["2022-03-09", 0.9960156655382872], ["2022-03-10", 1.0000000000000007]], "data-type": "date", "null-values": 0.0, "collation-id": 8, "last-updated": "2022-03-10 14:03:07.912733", "sampling-rate": 0.7963905033936588, "histogram-type": "singleton", "number-of-buckets-specified": 500} |
```

# Get Data histogram failed

```
yoj@yoj-debug-mysql [ /src/orcasql-mysql-release ]$ cat filter-log | grep "X at" | grep movements | grep -v movements_ | grep -v _movemen | grep failed
 JIYOU db:prd-spark-trf-be-reporting table_name:movements column_name:date 1.failed.X at /src/orcasql-mysql-release/sql/histograms/histogram.cc(find_histogram:1792)
 JIYOU db:prd-spark-trf-be-reporting table_name:movements column_name:date 1.failed.X at /src/orcasql-mysql-release/sql/histograms/histogram.cc(find_histogram:1792)
 JIYOU db:prd-spark-trf-be-reporting table_name:movements column_name:date 1.failed.X at /src/orcasql-mysql-release/sql/histograms/histogram.cc(find_histogram:1793)
 JIYOU db:prd-spark-trf-be-reporting table_name:movements column_name:date 1.failed.X at /src/orcasql-mysql-release/sql/histograms/histogram.cc(find_histogram:1793)
 JIYOU db:prd-spark-trf-be-reporting table_name:movements column_name:date 1.failed.X at /src/orcasql-mysql-release/sql/histograms/histogram.cc(find_histogram:1800)
 JIYOU db:prd-spark-trf-be-reporting table_name:movements column_name:date 1.failed.X at /src/orcasql-mysql-release/sql/histograms/histogram.cc(find_histogram:1800)
 JIYOU db:prd-spark-trf-be-reporting table_name:movements column_name:date 1.failed.X at /src/orcasql-mysql-release/sql/histograms/histogram.cc(find_histogram:1800)
 JIYOU db:prd-spark-trf-be-reporting table_name:movements column_name:date 1.failed.X at /src/orcasql-mysql-release/sql/histograms/histogram.cc(find_histogram:1801)
 JIYOU db:prd-spark-trf-be-reporting table_name:movements column_name:date 1.failed.X at /src/orcasql-mysql-release/sql/histograms/histogram.cc(find_histogram:1801)
 JIYOU db:prd-spark-trf-be-reporting table_name:movements column_name:date 1.failed.X at /src/orcasql-mysql-release/sql/histograms/histogram.cc(find_histogram:1801)
 JIYOU db:prd-spark-trf-be-reporting table_name:movements column_name:date 1.failed.X at /src/orcasql-mysql-release/sql/histograms/histogram.cc(find_histogram:1801)
 JIYOU db:prd-spark-trf-be-reporting table_name:movements column_name:date 1.failed.X at /src/orcasql-mysql-release/sql/histograms/histogram.cc(find_histogram:1801)
 JIYOU db:prd-spark-trf-be-reporting table_name:movements column_name:date 1.failed.X at /src/orcasql-mysql-release/sql/histograms/histogram.cc(find_histogram:1801)
 JIYOU db:prd-spark-trf-be-reporting table_name:movements column_name:date 1.failed.X at /src/orcasql-mysql-release/sql/histograms/histogram.cc(find_histogram:1801)
 JIYOU db:prd-spark-trf-be-reporting table_name:movements column_name:date 1.failed.X at /src/orcasql-mysql-release/sql/histograms/histogram.cc(find_histogram:1801)
 JIYOU db:prd-spark-trf-be-reporting table_name:movements column_name:date 1.failed.X at /src/orcasql-mysql-release/sql/histograms/histogram.cc(find_histogram:1801)
 JIYOU db:prd-spark-trf-be-reporting table_name:movements column_name:date 1.failed.X at /src/orcasql-mysql-release/sql/histograms/histogram.cc(find_histogram:1801)
yoj@yoj-debug-mysql [ /src/orcasql-mysql-release ]$ 
```

# 查询有问题的histogram

```
SELECT cs.SCHEMA_NAME, cs.table_name, cs.column_name, jt.freq, cs.HISTOGRAM->'$.\"histogram-type\"' as histogram_type
FROM `information_schema`.`column_statistics` cs,
     JSON_TABLE(
         cs.HISTOGRAM->'$.buckets',
         '$[*]' COLUMNS (
             value INT PATH '$[0]',
             freq DOUBLE PATH '$[1]'
         )
     ) jt
WHERE (jt.freq < 0 OR jt.freq > 1) 
AND cs.HISTOGRAM->'$.\"histogram-type\"' = 'singleton';
```

```Sql
ANALYZE TABLE parties_summary DROP HISTOGRAM ON transaction_id;
ANALYZE TABLE parties_summary DROP HISTOGRAM ON transaction_id;

DROP STATISTICS parties_summary(transaction_id);

Check:
 SELECT SCHEMA_NAME, TABLE_NAME, COLUMN_NAME, HISTOGRAM FROM `information_schema`.`column_statistics` WHERE SCHEMA_NAME='prd-spark-trf-be-reporting'     AND TABLE_NAME = 'parties_summary' AND column_name='transaction_id';

Delete：
delete FROM `information_schema`.`column_statistics` WHERE SCHEMA_NAME='prd-spark-trf-be-reporting'     AND TABLE_NAME = 'parties_summary' AND column_name='transaction_id';

SELECT cs.SCHEMA_NAME, cs.table_name, cs.column_name, jt.freq, cs.HISTOGRAM->'$.\"histogram-type\"' as histogram_type
FROM `information_schema`.`column_statistics` cs,
     JSON_TABLE(
         cs.HISTOGRAM->'$.buckets',
         '$[*]' COLUMNS (
             freq DOUBLE PATH '$[1]'
         )
     ) jt
WHERE (jt.freq < 0 OR jt.freq > 1) 
AND cs.HISTOGRAM->'$.\"histogram-type\"' = 'singleton';

SELECT cs.SCHEMA_NAME, cs.table_name, cs.column_name, jt.freq, cs.HISTOGRAM->'$.\"histogram-type\"' as histogram_type
FROM `information_schema`.`column_statistics` cs,
     JSON_TABLE(
         cs.HISTOGRAM->'$.buckets',
         '$[*]' COLUMNS (
             freq DOUBLE PATH '$[2]'
         )
     ) jt
WHERE (jt.freq < 0 OR jt.freq > 1) 
AND cs.HISTOGRAM->'$.\"histogram-type\"' = 'equi-height';


SELECT cs.SCHEMA_NAME, cs.table_name, cs.column_name, jt.freq, cs.HISTOGRAM->'$.\"histogram-type\"' as histogram_type
FROM `information_schema`.`column_statistics` cs,
     JSON_TABLE(
         cs.HISTOGRAM->'$.buckets',
         '$[*]' COLUMNS (
             freq DOUBLE PATH '$[2]'
         )
     ) jt
WHERE cs.HISTOGRAM->'$.\"histogram-type\"' = 'equi-height';
```

# 测试Histogram的SQL


[1] 创建一个学生表，students，这个students里面有一列为school

```sql
CREATE TABLE students (
    id INT AUTO_INCREMENT,
    name VARCHAR(100),
    age INT,
    school VARCHAR(255),
    PRIMARY KEY (id)
);
```

[2] 创建一个存储过程，往这个students里面随机insert 4000条数据。

在这个例子中，我将使用MySQL的RAND()函数来随机生成学生的名字（只是为了示例，实际情况可能需要更复杂的逻辑来生成名字），年龄（在10到30之间），和学校名称（'School'后面跟一个1到100的随机数）。

```sql
DELIMITER //
CREATE PROCEDURE InsertRandomStudents()
BEGIN
    DECLARE i INT DEFAULT 0;
    WHILE i < 4000 DO
        INSERT INTO students (name, age, school) VALUES (CONCAT('Student', FLOOR(RAND() * 10000)), FLOOR(10 + RAND() * 20), CONCAT('School', FLOOR(1 + RAND() * 100)));
        SET i = i + 1;
    END WHILE;
END //
DELIMITER ;
```

你可以通过以下命令调用这个存储过程：

```sql
CALL InsertRandomStudents();
```

[3] 在school这一列上建histogram信息。

MySQL 8.0及以上版本开始支持直方图。但是，你需要注意的是，不是所有的存储引擎都支持直方图。在InnoDB和MyISAM中，你可以创建直方图。

以下是创建直方图的命令：

```sql
ANALYZE TABLE students UPDATE HISTOGRAM ON school WITH 100 BUCKETS;
```

在这个例子中，创建了一个包含100个buckets的直方图。可以根据需要调整buckets的数量。

请注意，这些代码可能需要根据你的数据库系统和版本进行适当的修改。

# 创建带functional index

```
CREATE TABLE `test_oauth2_access_token` (

  `TOKEN_ID` varchar(255) NOT NULL,

  `ACCESS_TOKEN` varchar(2048) DEFAULT NULL,

  `REFRESH_TOKEN` varchar(2048) DEFAULT NULL,

  `CONSUMER_KEY_ID` int DEFAULT NULL,

  `AUTHZ_USER` varchar(100) DEFAULT NULL,

  `TENANT_ID` int DEFAULT NULL,

  `USER_DOMAIN` varchar(50) DEFAULT NULL,

  `USER_TYPE` varchar(25) DEFAULT NULL,

  `GRANT_TYPE` varchar(50) DEFAULT NULL,

  `TIME_CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,

  `REFRESH_TOKEN_TIME_CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,

  `VALIDITY_PERIOD` bigint DEFAULT NULL,

  `REFRESH_TOKEN_VALIDITY_PERIOD` bigint DEFAULT NULL,

  `TOKEN_SCOPE_HASH` varchar(32) DEFAULT NULL,

  `TOKEN_STATE` varchar(25) DEFAULT 'ACTIVE',

  `TOKEN_STATE_ID` varchar(128) DEFAULT 'NONE',

  `SUBJECT_IDENTIFIER` varchar(255) DEFAULT NULL,

  `ACCESS_TOKEN_HASH` varchar(512) DEFAULT NULL,

  `REFRESH_TOKEN_HASH` varchar(512) DEFAULT NULL,

  `IDP_ID` int NOT NULL DEFAULT '-1',

  `TOKEN_BINDING_REF` varchar(32) DEFAULT 'NONE',

  `CONSENTED_TOKEN` varchar(6) DEFAULT NULL,

  PRIMARY KEY (`TOKEN_ID`),

  UNIQUE KEY `CON_APP_KEY` (`CONSUMER_KEY_ID`,`AUTHZ_USER`,`TENANT_ID`,`USER_DOMAIN`,`USER_TYPE`,`TOKEN_SCOPE_HASH`,`TOKEN_STATE`,`TOKEN_STATE_ID`,`IDP_ID`,`TOKEN_BINDING_REF`),

  KEY `IDX_TC` (`TIME_CREATED`),

  KEY `IDX_ATH` (`ACCESS_TOKEN_HASH`),

  KEY `IDX_AT_TI_UD` (`AUTHZ_USER`,`TENANT_ID`,`TOKEN_STATE`,`USER_DOMAIN`),

  KEY `IDX_AT_AT` (`ACCESS_TOKEN`),

  KEY `IDX_AT_RTH` (`REFRESH_TOKEN_HASH`),

  KEY `IDX_AT_RT` (`REFRESH_TOKEN`),

  KEY `IDX_AT_CKID_AU_TID_UD_TSH_TS` (`CONSUMER_KEY_ID`,`AUTHZ_USER`,`TENANT_ID`,`USER_DOMAIN`,`TOKEN_SCOPE_HASH`,`TOKEN_STATE`),

  KEY `IDX_AT_TBR_TS` (`TOKEN_BINDING_REF`,`TOKEN_STATE`),

  KEY `IDX_AT_CKID_AU_TID_UD_TSH_TS_2` (`CONSUMER_KEY_ID`,(lower(`AUTHZ_USER`)),`TENANT_ID`,`USER_DOMAIN`,`TOKEN_SCOPE_HASH`,`TOKEN_STATE`)

) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPRESSED;
```

## 添加数据的store procedure

```
DELIMITER //
CREATE PROCEDURE InsertRandomDataIntoTestOauth2AccessToken()
BEGIN
    DECLARE i INT DEFAULT 0;
    WHILE i < 1000 DO
      INSERT INTO test_oauth2_access_token(
        TOKEN_ID,
        ACCESS_TOKEN,
        REFRESH_TOKEN,
        CONSUMER_KEY_ID,
        AUTHZ_USER,
        TENANT_ID,
        USER_DOMAIN,
        USER_TYPE,
        GRANT_TYPE,
        VALIDITY_PERIOD,
        REFRESH_TOKEN_VALIDITY_PERIOD,
        TOKEN_SCOPE_HASH,
        TOKEN_STATE,
        TOKEN_STATE_ID,
        SUBJECT_IDENTIFIER,
        ACCESS_TOKEN_HASH,
        REFRESH_TOKEN_HASH,
        IDP_ID,
        TOKEN_BINDING_REF,
        CONSENTED_TOKEN
      )
      VALUES (
        CONCAT('token_', i),
        CONCAT('access_', i),
        CONCAT('refresh_', i),
        i,
        CONCAT('user_', i),
        i,
        CONCAT('domain_', i),
        IF(i MOD 2 = 0, 'type1', 'type2'),
        IF(i MOD 2 = 0, 'grant1', 'grant2'),
        i,
        i,
        CONCAT('scope_', i),
        IF(i MOD 2 = 0, 'ACTIVE', 'INACTIVE'),
        CONCAT('state_', i),
        CONCAT('subject_', i),
        CONCAT('access_hash_', i),
        CONCAT('refresh_hash_', i),
        i,
        CONCAT('ref_', i),
        IF(i MOD 2 = 0, 'YES', 'NO')
      );
      SET i = i + 1;
    END WHILE;
END //
DELIMITER ;
```

## 加入数据

```
call InsertRandomDataIntoTestOauth2AccessToken();
```

# 打开表的流程


```
#0  0x00007efc61303965 in pthread_cond_wait@@GLIBC_2.3.2 () from /lib64/libpthread.so.0
#1  0x0000000000ffb03b in wait at /export/home/pb2/build/sb_0-27500212-1520171728.22/mysql-5.7.22/storage/innobase/os/os0event.cc:165
#2  os_event::wait_low at /export/home/pb2/build/sb_0-27500212-1520171728.22/mysql-5.7.22/storage/innobase/os/os0event.cc:335
#3  0x00000000010a0ce9 in sync_array_wait_event at /export/home/pb2/build/sb_0-27500212-1520171728.22/mysql-5.7.22/storage/innobase/sync/sync0arr.cc:475
#4  0x0000000000f8c1c4 in TTASEventMutex<GenericPolicy>::wait at /export/home/pb2/build/sb_0-27500212-1520171728.22/mysql-5.7.22/storage/innobase/include/ut0mutex.ic:89
#5  0x0000000000f8c33b in spin_and_try_lock at /export/home/pb2/build/sb_0-27500212-1520171728.22/mysql-5.7.22/storage/innobase/include/ib0mutex.h:850
#6  enter at /export/home/pb2/build/sb_0-27500212-1520171728.22/mysql-5.7.22/storage/innobase/include/ib0mutex.h:707
#7  PolicyMutex<TTASEventMutex<GenericPolicy> >::enter at /export/home/pb2/build/sb_0-27500212-1520171728.22/mysql-5.7.22/storage/innobase/include/ib0mutex.h:987
#8  0x0000000001152f41 in dict_table_open_on_name at /export/home/pb2/build/sb_0-27500212-1520171728.22/mysql-5.7.22/storage/innobase/dict/dict0dict.cc:1238
#9  0x0000000000f72a73 in ha_innobase::open_dict_table at /export/home/pb2/build/sb_0-27500212-1520171728.22/mysql-5.7.22/storage/innobase/handler/ha_innodb.cc:6250
#10 0x0000000000f8273b in ha_innobase::open at /export/home/pb2/build/sb_0-27500212-1520171728.22/mysql-5.7.22/storage/innobase/handler/ha_innodb.cc:5888
#11 0x000000000081b33e in handler::ha_open at /export/home/pb2/build/sb_0-27500212-1520171728.22/mysql-5.7.22/sql/handler.cc:2759
#12 0x0000000000dc239a in open_table_from_share at /export/home/pb2/build/sb_0-27500212-1520171728.22/mysql-5.7.22/sql/table.cc:3353
#13 0x0000000000cc18b9 in open_table at /export/home/pb2/build/sb_0-27500212-1520171728.22/mysql-5.7.22/sql/sql_base.cc:3559
#14 0x0000000000cc52b6 in open_and_process_table at /export/home/pb2/build/sb_0-27500212-1520171728.22/mysql-5.7.22/sql/sql_base.cc:5145
#15 open_tables at /export/home/pb2/build/sb_0-27500212-1520171728.22/mysql-5.7.22/sql/sql_base.cc:5756
#16 0x0000000000cc5e62 in open_tables_for_query at /export/home/pb2/build/sb_0-27500212-1520171728.22/mysql-5.7.22/sql/sql_base.cc:6531
#17 0x0000000000d14ff6 in execute_sqlcom_select at /export/home/pb2/build/sb_0-27500212-1520171728.22/mysql-5.7.22/sql/sql_parse.cc:5127
#18 0x0000000000d18bce in mysql_execute_command at /export/home/pb2/build/sb_0-27500212-1520171728.22/mysql-5.7.22/sql/sql_parse.cc:2792
#19 0x0000000000d1aaad in mysql_parse at /export/home/pb2/build/sb_0-27500212-1520171728.22/mysql-5.7.22/sql/sql_parse.cc:5582
#20 0x0000000000d1bcca in dispatch_command at /export/home/pb2/build/sb_0-27500212-1520171728.22/mysql-5.7.22/sql/sql_parse.cc:1458
#21 0x0000000000d1cb74 in do_command at /export/home/pb2/build/sb_0-27500212-1520171728.22/mysql-5.7.22/sql/sql_parse.cc:999
#22 0x0000000000dedaec in handle_connection at /export/home/pb2/build/sb_0-27500212-1520171728.22/mysql-5.7.22/sql/conn_handler/connection_handler_per_thread.cc:300
#23 0x0000000001256a94 in pfs_spawn_thread at /export/home/pb2/build/sb_0-27500212-1520171728.22/mysql-5.7.22/storage/perfschema/pfs.cc:2190
#24 0x00007efc612ffdd5 in start_thread () from /lib64/libpthread.so.0
#25 0x00007efc5fdb8ead in clone () from /lib64/libc.so.6
```