### 引言

##### MySQL事务执行的顺序
---
1. change_data_page                              -- 修改 Buffer Pool 里的数据页
2. write_redo_log_buffer(changed_data_page_record) -- 记录数据变更到 redo log buffer
3. write_redo_log_buffer(tx="prepare")            -- 追加 "prepare" redo log 记录
4. fsync(redo_log_file)                            -- 刷盘 redo log（确保 "prepare" 持久化）
5. write_binlog_buffer()                           -- 记录 binlog 到 binlog buffer
6. fsync(binlog_buffer)                            -- 刷盘 binlog（确保 binlog 持久化）
7. write_redo_log_buffer(tx="commit")             -- 追加 "commit" redo log 记录
8. fsync(redo_log_file)                            -- 刷盘 redo log（确保事务彻底提交）

##### redo log文件record排列

```
[ 数据变更 redo log ] → [ 数据变更 redo log ] → ... → [ "prepare" redo log ] → [ "commit" redo log ]
```

更详细的情况如下：
```
|   TxID: T1  |   PageID: A  |   操作: UPDATE  |   旧值: x  |   新值: y  | (数据变更 redo log) |
|   TxID: T1  |   PageID: B  |   操作: INSERT  |   旧值: -  |   新值: z  | (数据变更 redo log) |
|   TxID: T1  |   状态: PREPARE | (事务进入 prepare 状态) |
|   TxID: T1  |   状态: COMMIT  | (事务提交) |
```

对普通的事务来说

1. change_data_page                               -- 修改 Buffer Pool 里的数据页
2. write_redo_log_buffer(changed_data_page_record) -- 记录数据变更到 redo log buffer
3. write_undo_log_buffer(changed_data_rows)        -- 记录 undo log（回滚用）
4. write_redo_log_buffer(tx="prepare")             -- 追加 "prepare" redo log 记录
5. fsync(redo_log_file)                             -- 刷盘 redo log（确保 "prepare" 持久化）
6. write_binlog_buffer()                            -- 记录 binlog 到 binlog buffer
7. fsync(binlog_buffer)                             -- 刷盘 binlog（确保 binlog 持久化）
8. write_redo_log_buffer(tx="commit")              -- 追加 "commit" redo log 记录
9. fsync(redo_log_file)                             -- 刷盘 redo log（确保事务彻底提交）
10. **undo log 由后台线程异步刷盘**

需要注意的是，undo log是异步刷写的。就算是因为crash，如果需要回滚。也可以根据redo log来回滚。这是因为redo log里面的记录可以恢复出undo log。

redo log会将checkpoint lsn写在redo log file固定的file position，每次会将这个位置写到固定的位置。然后每次启动的时候，就会从这个位置读出checkpoint_lsn，然后通过下面这个公式，算出后面要读取的最后的redo log record的位置，拿到write_lsn。

| **步骤**                  | **操作**                                                                |
| ----------------------- | --------------------------------------------------------------------- |
| **1. 计算 redo log 文件索引** | `file_index = (checkpoint_lsn % total_redo_log_size) / log_file_size` |
| **2. 计算文件内偏移量**         | `file_offset = checkpoint_lsn % log_file_size`                        |
| **3. 读取 redo log 记录**   | 从 `file_index` 和 `file_offset` 处开始扫描 redo log                         |
| **4. 解析 redo log**      | 逐条读取 redo log 记录，回放到 buffer pool                                      |

crash recovery的原则


![[Pasted image 20250212153859.png]]
如上图所示，

1，在第一种异常情况下，redo log 和binlog都没有写入，主备是一致的。丢弃。

2，第二异常情况， **`redo log`已经落入磁盘**，binlog不完整。回滚。

3,  第三种：redo log已经落盘成功。binlog完整，重新提交。

需要注意的是，`innodb_flush_log_at_trx_commit 为1`时才能保证redo log是在binlog写入前是已经落盘的，如果是0或者2，则有可能出现节点崩溃时，redo log没有写入到磁盘而丢失，而binlog是完整的情况，造成主备不一致。

链接：https://zhuanlan.zhihu.com/p/686976503  


---
1. Introduction

2. Feature Overview

Database recovery in SQL Server follows the [ARIES](https://people.eecs.berkeley.edu/~brewer/cs262/Aries.pdf) recovery model and consists of the following phases:

- Analysis: Starts from the beginning of the last successful checkpoint [[PB(1]](https://microsoftapc-my.sharepoint.com/personal/yoj_microsoft_com/Documents/Documents/Constant%20Time%20Recovery%20Design%20Spec.docx#_msocom_1) [[PA2]](https://microsoftapc-my.sharepoint.com/personal/yoj_microsoft_com/Documents/Documents/Constant%20Time%20Recovery%20Design%20Spec.docx#_msocom_2) (or the oldest page LSN) and traverses the log to the end of log to identify the state of each transaction and whether they were active at the time of the crash and, therefore, need to be undone during recovery. It also identifies the oldest dirty page in the system.

分析阶段是从最小的成功的checkpoint位置开始。然后遍历redo log，在这个过程中:

[1] 可以知道每个事务的状态，然后判断在crash的时候，它们是不是active的

[2] 如果判断出是active的事务，那么可能需要撤销这个改动

[3] 同时，它也会识别出最旧的系统中的脏页。

- Redo: Starts from the minimum of

3. the begin log record of the oldest active transaction [[HK3]](https://microsoftapc-my.sharepoint.com/personal/yoj_microsoft_com/Documents/Documents/Constant%20Time%20Recovery%20Design%20Spec.docx#_msocom_3) in the system as of the time of the crash,
4. the beginning of the last successful checkpoint
5. the oldest dirty page LSN [[HK4]](https://microsoftapc-my.sharepoint.com/personal/yoj_microsoft_com/Documents/Documents/Constant%20Time%20Recovery%20Design%20Spec.docx#_msocom_4) in the system

redo在做recovery的时候，会尝试从三个最小值开始做重做日志

[1] 离crash最近的active事务的开始位置。

[2] 最后一个成功的checkpoint的位置

[3] 找到的离当前位置最近的一个脏页的lsn

Q: 这个可能需要看一下mysql是如何处理的。

and traverses the log forward to the end of log, redoing all operations to bring the database to the state it was at the time of the crash.

出发点是这个三个最小值 。然后往redo log后面走，redoing所有的redo日志。尝试把系统的状态恢复到crash的时候的状态。

Even though checkpoint had flushed all pages, we still need to start Redo from the oldest active transaction in order to redo some logical operations and reacquire all the locks by transactions that were active at the time of the crash (in FULL recovery).

尽管checkpoint已经成功地把所有的pages都刷写到了磁盘。但是我们还是需要从最近的active事务的起始位置开始。

重做这些operations，主要是:

[1] 把一些逻辑操作重新做一下

[2] 可能需要拿锁，那么就需要再拿一下锁。

[[HK5]](https://microsoftapc-my.sharepoint.com/personal/yoj_microsoft_com/Documents/Documents/Constant%20Time%20Recovery%20Design%20Spec.docx#_msocom_5) [[PA6]](https://microsoftapc-my.sharepoint.com/personal/yoj_microsoft_com/Documents/Documents/Constant%20Time%20Recovery%20Design%20Spec.docx#_msocom_6) This allows us to bring the database online during the Undo phase, since we have reacquired the appropriate locks to synchronize concurrent access.

前面的意思是说，有了前面的两个阶段的准备，那么接下来的undo阶段，就是可行的。因为我们已经拿到所有的锁。

- Undo: For each transaction that was active as of the time of the crash, traverses the log backward, undoing the operations that this transaction performed.

- 对于每个在crash的时候，如果是active的事务而言。就需要我们往后遍历redo log，undo这个active的事务在crash前做过的Operations.

- The database is generally available during this time (in FULL recovery[[HK7]](https://microsoftapc-my.sharepoint.com/personal/yoj_microsoft_com/Documents/Documents/Constant%20Time%20Recovery%20Design%20Spec.docx#_msocom_7) [[PA8]](https://microsoftapc-my.sharepoint.com/personal/yoj_microsoft_com/Documents/Documents/Constant%20Time%20Recovery%20Design%20Spec.docx#_msocom_8) ) and the locks that were acquired during Redo are synchronizing concurrent access.

这个时候的系统是online/可用的。因为所有要拿的锁都拿到了。

Q: 不清楚MySQL是不是这样的。

- However, these locks are preventing access to the uncommitted data which means that the database is partially available until the Undo phase is complete and the locks get released.

但是，这些锁会阻止访问这些没有提交的数据。这也就意味着database是半可用的，直到undo阶段完成。然后锁完全释放了才是可用的。

Based on this design, the recovery time is proportional to the longest transaction size and therefore has been causing availability problem to customers with long running transactions over the years. In cloud environments, failures are considerably more frequent compared to on-premises and, therefore, exacerbate the problem.

基于这种设计，恢复时间与最长的事务规模成正比，因此多年来，对于运行长时间事务的客户而言，一直存在可用性问题。在云环境中，与本地环境相比，故障发生的频率要高得多，这进一步加剧了该问题。

这里主要是考虑到如果事务很大，或者事务很长，那么恢复时间就会比较久。

Over the last few years we have had several Sev2 incidents with outages of multiple hours or even days due to long running recovery, especially in SQL DW, where we are using the SIMPLE recovery model and the database is completely unavailable until the end of Redo.

这里是说导致的一些后果，就是会出现较长时间的恢复期，然后数据库这个时候是半可用，或者是不可用的。