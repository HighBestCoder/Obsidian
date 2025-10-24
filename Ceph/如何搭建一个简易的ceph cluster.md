编译好了之后：

```
cd build.
MON=1 OSD=1 MDS=0 MGR=1 ../src/vstart.sh -n -d --without-dashboard


cd /ceph/ceph/build

# 设置环境变量
source /ceph/ceph/build/vstart_environment.sh

# 或者手动设置
export CEPH_CONF=/ceph/ceph/build/ceph.conf
export PYTHONPATH=/ceph/ceph/src/pybind:/ceph/ceph/build/lib/cython_modules/lib.3:$PYTHONPATH
export LD_LIBRARY_PATH=/ceph/ceph/build/lib:$LD_LIBRARY_PATH
export PATH=/ceph/ceph/build/bin:$PATH

# 现在运行
ceph -s

# 1. 完全停止
../src/stop.sh

# 2. 重启（保留现有集群数据）
MON=1 OSD=1 MDS=0 MGR=1 ../src/vstart.sh -d --without-dashboard

# 3. 清理并重新创建集群
../src/stop.sh
rm -rf out dev

MON=1 OSD=1 MDS=0 MGR=1 ../src/vstart.sh -n -d --without-dashboard


ceph osd metadata osd.0


# 4. 查看集群状态
bin/ceph -s


```

拿到ceph的disk

# 加载数据

```bash
#!/bin/bash
POOL_NAME="mypool"
BIN_DIR="/ceph/ceph/build/bin"

# 创建 RBD 存储池，64个PG，副本数为1
echo "Creating RBD pool..."
ceph osd pool create $POOL_NAME 64 64

# 设置副本数为1
ceph osd pool set $POOL_NAME size 1
ceph osd pool set $POOL_NAME min_size 1

# 启用 RBD 应用
ceph osd pool application enable $POOL_NAME rbd

# 上传文件（继续使用 rados put，因为 rbd 也是用 RADOS 存储）
cd $BIN_DIR
count=0
for file in *; do
    if [ -f "$file" ]; then
        echo "Uploading $file..."
        rados -p $POOL_NAME put "$file" "$file"
        ((count++))
    fi
done

echo "上传完成！共上传 $count 个文件"
rados -p $POOL_NAME ls
```

# 修复rocksdb的测试流程

# 完整的 OSD.0 RocksDB 修复步骤

根据你的 OSD.0 信息，以下是完整的操作步骤：

## 第0步：停止 Ceph 集群

```bash
cd /ceph/ceph/build
../src/stop.sh
```

## 第1步：导出 BlueFS 中的 RocksDB 数据

```bash
cd /ceph/ceph/build

# 导出 RocksDB 数据
ceph-bluestore-tool --path /ceph/ceph/build/dev/osd0 \
    --command bluefs-export \
    --out-dir /tmp/osd0-rocksdb

# 验证导出的数据
ls -lh /tmp/osd0-rocksdb/
```

## 第2步：使用 RocksDB ldb 工具修复数据

```bash
apt install rocksdb-tools
# 修复 RocksDB 数据库
ldb --db=/tmp/osd0-rocksdb/db repair

# 可选：检查修复后的数据
ldb --db=/tmp/osd0-rocksdb/db manifest_dump
```

查看并删除文件

# 1. 先列出所有文件
ceph-bluestore-tool --path /ceph/ceph/build/dev/osd0 bluefs-ls

# 2. 删除特定的损坏文件
ceph-bluestore-tool --path /ceph/ceph/build/dev/osd0 bluefs-rm --target-file db/000028.sst

# 3. 再次列出确认删除
ceph-bluestore-tool --path /ceph/ceph/build/dev/osd0 bluefs-ls

# 通过日志恢复bluefs的核心流程
ceph-bluestore-tool --path /ceph/ceph/build/dev/osd0 bluefs-import --input-file /tmp/osd0-rocksdb/db/000028.sst --dest-file "db/000028.sst"

 ceph-bluestore-tool --path /ceph/ceph/build/dev/osd0 repair --deep 0 --debug
 

ceph-bluestore-tool --path /ceph/ceph/build/dev/osd0 bluefs-rm --target-file db/000028.sst
ceph-bluestore-tool --path /ceph/ceph/build/dev/osd0 bluefs-ls
ceph-bluestore-tool --path /ceph/ceph/build/dev/osd0 bluefs-import --input-file /tmp/osd0-rocksdb/db/000028.sst --dest-file "db/000028.sst"

# 导入所有的数据

```
#!/bin/bash
set -e

BASE_PATH="/ceph/ceph/build/dev/osd0"
IMPORT_DIR="/tmp/osd0-rocksdb"

echo "导入: db.wal/000035.log"
ceph-bluestore-tool --path ${BASE_PATH} bluefs-import --input-file ${IMPORT_DIR}/db.wal/000035.log --dest-file "db.wal/000035.log"

echo "导入: db/000031.sst"
ceph-bluestore-tool --path ${BASE_PATH} bluefs-import --input-file ${IMPORT_DIR}/db/000031.sst --dest-file "db/000031.sst"

echo "导入: db/MANIFEST-000034"
ceph-bluestore-tool --path ${BASE_PATH} bluefs-import --input-file ${IMPORT_DIR}/db/MANIFEST-000034 --dest-file "db/MANIFEST-000034"

echo "导入: db/LOCK"
ceph-bluestore-tool --path ${BASE_PATH} bluefs-import --input-file ${IMPORT_DIR}/db/LOCK --dest-file "db/LOCK"

echo "导入: db/IDENTITY"
ceph-bluestore-tool --path ${BASE_PATH} bluefs-import --input-file ${IMPORT_DIR}/db/IDENTITY --dest-file "db/IDENTITY"

echo "导入: db/CURRENT"
ceph-bluestore-tool --path ${BASE_PATH} bluefs-import --input-file ${IMPORT_DIR}/db/CURRENT --dest-file "db/CURRENT"

echo "导入: db/OPTIONS-000032"
ceph-bluestore-tool --path ${BASE_PATH} bluefs-import --input-file ${IMPORT_DIR}/db/OPTIONS-000032 --dest-file "db/OPTIONS-000032"

echo "导入: db/000032.sst"
ceph-bluestore-tool --path ${BASE_PATH} bluefs-import --input-file ${IMPORT_DIR}/db/000032.sst --dest-file "db/000032.sst"

echo "导入: db/000028.sst"
ceph-bluestore-tool --path ${BASE_PATH} bluefs-import --input-file ${IMPORT_DIR}/db/000028.sst --dest-file "db/000028.sst"

echo "导入: db/OPTIONS-000037"
ceph-bluestore-tool --path ${BASE_PATH} bluefs-import --input-file ${IMPORT_DIR}/db/OPTIONS-000037 --dest-file "db/OPTIONS-000037"

echo "导入: sharding/def"
ceph-bluestore-tool --path ${BASE_PATH} bluefs-import --input-file ${IMPORT_DIR}/sharding/def --dest-file "sharding/def"

```

# 整个目录的导入导出

```
#!/bin/bash
# Enhanced BlueFS File Re-import Script with safety checks
# This script will import all exported BlueFS files back into BlueFS

EXPORT_DIR="${1:-/tmp/osd0-rocksdb}"
OSD_PATH="${2:-/ceph/ceph/build/dev/osd0}"
DRY_RUN="${3:-false}"  # Set to "true" to see what would be imported without actually doing it

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}===================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_header "BlueFS File Re-import Script"
echo "Export Directory: $EXPORT_DIR"
echo "OSD Path: $OSD_PATH"
if [ "$DRY_RUN" = "true" ]; then
    print_warning "DRY RUN MODE - No actual imports will be performed"
fi
echo ""

# Validate inputs
if [ ! -d "$EXPORT_DIR" ]; then
    print_error "Export directory $EXPORT_DIR does not exist"
    exit 1
fi

if [ ! -d "$OSD_PATH" ]; then
    print_error "OSD path $OSD_PATH does not exist"
    exit 1
fi

# Check if ceph-bluestore-tool is available
if ! command -v ceph-bluestore-tool &> /dev/null; then
    print_error "ceph-bluestore-tool not found in PATH"
    exit 1
fi

# List current BlueFS files before import
print_header "Current BlueFS State (before import)"
if [ "$DRY_RUN" = "false" ]; then
    echo "Listing current files..."
    ceph-bluestore-tool --path "$OSD_PATH" bluefs-ls 2>/dev/null || print_warning "Could not list current BlueFS files"
fi
echo ""

# Counters
TOTAL_FILES=0
SUCCESS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

# Function to import a single file
import_file() {
    local source_file="$1"
    local dest_path="$2"

    TOTAL_FILES=$((TOTAL_FILES + 1))

    if [ "$DRY_RUN" = "true" ]; then
        echo -e "${BLUE}[DRY RUN]${NC} Would import: $dest_path"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        return 0
    fi

    # Import the file
    if ceph-bluestore-tool --path "$OSD_PATH" bluefs-import \
        --input-file "$source_file" \
        --dest-file "$dest_path" 2>&1; then
        print_success "Imported: $dest_path"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        return 0
    else
        print_error "Failed: $dest_path"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return 1
    fi
}

# Function to process a directory
process_directory() {
    local dir_name="$1"
    local full_path="$EXPORT_DIR/$dir_name"

    if [ ! -d "$full_path" ]; then
        return
    fi

    print_header "Processing directory: $dir_name"

    local dir_file_count=0

    # Process each file in the directory
    for file in "$full_path"/*; do
        if [ ! -f "$file" ]; then
            continue
        fi

        local filename=$(basename "$file")

        # Skip hidden files
        if [[ "$filename" == .* ]]; then
            print_warning "Skipping hidden file: $filename"
            SKIP_COUNT=$((SKIP_COUNT + 1))
            continue
        fi

        local dest_file="${dir_name}/${filename}"
        dir_file_count=$((dir_file_count + 1))

        echo -n "[$dir_file_count] "
        import_file "$file" "$dest_file"
    done

    if [ $dir_file_count -eq 0 ]; then
        print_warning "No files found in $dir_name"
    fi
    echo ""
}

# Main import process
print_header "Starting Import Process"
echo ""

# Process standard BlueFS directories
for dir in "db" "db.wal" "db.slow"; do
    if [ -d "$EXPORT_DIR/$dir" ]; then
        process_directory "$dir"
    fi
done

# Process root directory files
print_header "Processing Root Directory Files"
root_count=0
for file in "$EXPORT_DIR"/*; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        if [[ "$filename" != .* ]]; then
            root_count=$((root_count + 1))
            echo -n "[$root_count] "
            import_file "$file" "$filename"
        fi
    fi
done

if [ $root_count -eq 0 ]; then
    print_warning "No files found in root directory"
fi
echo ""

# Summary
print_header "Import Summary"
echo "Total files processed: $TOTAL_FILES"
print_success "Successfully imported: $SUCCESS_COUNT"
if [ $FAIL_COUNT -gt 0 ]; then
    print_error "Failed: $FAIL_COUNT"
fi
if [ $SKIP_COUNT -gt 0 ]; then
    print_warning "Skipped: $SKIP_COUNT"
fi
echo ""

# List files after import
if [ "$DRY_RUN" = "false" ] && [ $SUCCESS_COUNT -gt 0 ]; then
    print_header "BlueFS State After Import"
    echo "Listing imported files..."
    ceph-bluestore-tool --path "$OSD_PATH" bluefs-ls 2>/dev/null || print_warning "Could not list BlueFS files"
    echo ""
fi

# Next steps
print_header "Next Steps"
if [ "$DRY_RUN" = "true" ]; then
    echo "This was a dry run. To perform actual import, run:"
    echo "  $0 $EXPORT_DIR $OSD_PATH false"
elif [ $FAIL_COUNT -gt 0 ]; then
    print_warning "Some files failed to import. Please check the errors above."
    echo ""
    echo "You may want to:"
    echo "  1. Check BlueFS logs for errors"
    echo "  2. Try importing failed files individually"
    echo "  3. Verify source files are not corrupted"
else
    print_success "All files imported successfully!"
    echo ""
    echo "Recommended next steps:"
    echo "  1. Verify BlueFS integrity:"
    echo "     ceph-bluestore-tool --path $OSD_PATH bluefs-ls"
    echo ""
    echo "  2. Note: The OSD may still fail to start because RocksDB MANIFEST"
    echo "     may reference old file metadata. The import created new files"
    echo "     with new inodes, which RocksDB doesn't know about."
    echo ""
    echo "  3. To fix this, you need to either:"
    echo "     a) Export the database and repair MANIFEST:"
    echo "        ceph-bluestore-tool --path $OSD_PATH bluefs-export --out-dir /tmp/db-repair"
    echo "        cd /tmp/db-repair/db && rm -f MANIFEST-* CURRENT"
    echo "        (then let RocksDB rebuild on next start)"
    echo ""
    echo "     b) Or simply recreate the OSD:"
    echo "        cd /ceph/ceph/build"
    echo "        rm -rf dev/osd0/*"
    echo "        ../src/vstart.sh -n"
fi
echo ""

exit $([ $FAIL_COUNT -eq 0 ] && echo 0 || echo 1)
```


## Step 1. 定位日志头（log header）

在 `fsck.log` 或调试输出中，首先找到 BlueFS 的日志头位置：

```
2025-10-22 23:38:47 INFO: 找到日志头:
disk_offset = 6469255168, seq = 1, uuid = c203c395-19ed-49df-ac69-9608c7283a33
at _replay_find_log()
```

说明：
- `seq = 1` 是最早的日志序列号；
- `disk_offset = 6469255168` 通常是 `log_fnode.extents[0]` 的起始物理位置；
- 该偏移对应 BlueFS 日志块的首个 extent。

紧接着，会出现日志跳转指令：

```
[OP_JUMP] disk_offset: 6469255168 找到 jump_seq = 1703, offset = 65536
```

这表示：
- 当前日志块通过 `OP_JUMP` 跳转到新的日志段；
- `jump_seq = 1703` 说明下一个有效日志序列号为 1704；
- 这个跳转指令位于 `extent[0]` 尾部。

---

## Step 2. 使用 fix_search 验证跳转目标

在 `fix_search` 输出中找到 `seq = 1704` 的记录：

```
Found UUID at offset: 6465060864, seq: 1704, internal_offset: 6
```

该记录代表新的日志段的起始位置。

根据 BlueFS 超级块日志：

```
super.log_fnode.extents[1] = {.offset = 6465060864, .length=4194304, bdev=1}
```

可以确认：
- `extent[1]` 起点 = `6465060864`；
- `length = 4194304`；
- 对应 `fix_search` 中的 `seq = 1704`。

---

## Step 3. 验证 extent 长度是否正确

从 `fix_search` 日志末尾可见：

```
Found UUID at offset: 6465433600, seq: 1795
Found UUID at offset: 6465437696, seq: 1796
Found UUID at offset: 6465441792, seq: 1797
Found UUID at offset: 6469255168, seq: 1
```

计算偏移差：
```
6469255168 - 6465060864 = 4194304
```

该差值恰好等于 `extent[1].length`，验证了日志块连续性与长度匹配性。

---

## Step 4. 核心结论

1. `seq = 1` 的日志块位置（`6469255168`）是日志头及 `extent[0]` 的起点；
2. `[OP_JUMP]` 跳转指令正确指向 `seq = 1704`；
3. `seq = 1704` 所在物理位置 `6465060864` 对应 `extent[1]`；
4. 通过偏移差计算验证 `extent[1]` 长度 = `4194304`；
5. 日志文件的物理布局和 BlueFS 超级块记录一致。

---

## ✅ 最终结论

通过比对 `BlueFS::_replay_find_log()` 输出与 `fix_search` 结果，可以精确确认：
- BlueFS 日志链（seq 跳转）完整；
- `log_fnode.extents` 描述正确；
- 日志未出现截断或重叠。

这意味着 BlueFS 的日志区域是 **一致且可安全重放** 的。


# Example 1

```
找到日志头: disk_offset = 11999297404928, seq = 1, uuid = 2868d135-cae5-4c1c-9e09-8316df57161f at _replay_find_log(/home/src/os/bluestore/BlueFS.cc:1127)

[OP_JUMP] disk_offset: 11999297404928 找到jump_seq = 1722305527, offset = 196608 at _replay_find_log(/home/src/os/bluestore/BlueFS.cc:1210)
```

结论1
```
这里找到日志头11999297404928, seq = 1, 下一个序号 = 1722305528 =   1722305527 + 1  
extent[0].length = 196608
```
但是fix_search中没有seq = 1722305528

那我们看一下旧一点的头是否可以用？

我们在fix_search中发现:

```
Found UUID at offset: 11998150709248, seq: 1722309253, internal_offset: 6
Found UUID at offset: 11998178902016, seq: 1, internal_offset: 6
Found UUID at offset: 11998293458944, seq: 1722180199, internal_offset: 6
Found UUID at offset: 11998293483520, seq: 1722180200, internal_offset: 6
Found UUID at offset: 11998293508096, seq: 1722180201, internal_offset: 6
Found UUID at offset: 11998293532672, seq: 1722180202, internal_offset: 6
```
也就是11998178902016这里有一个seq=1.然后在这个位置的`fsck.log`


```
找到日志头: disk_offset = 11998178902016, seq = 1, uuid = 2868d135-cae5-4c1c-9e09-8316df57161f at _replay_find_log(/home/src/os/bluestore/BlueFS.cc:1127)
[OP_JUMP] disk_offset: 11998178902016 找到jump_seq = 1722064198, offset = 196608 at _replay_find_log(/home/src/os/bluestore/BlueFS.cc:1210)
```

这个日志头的下一条是1722064198 + 1 = 1722064199.但是这一条记录在fix_search里面好像没有。

# 再次尝试

我们应该找到jump_seq最大的值。

cat fsck.osd.3.log  | grep jump_seq > /tmp/res.log
cat /tmp/res.log   | awk '{print $9'} | grep -v 找 | sort -n | tail

然后找到最大值是, 2870589149

然后我们再看fsck.log -> 


```
找到日志头: disk_offset = 8642563080192, seq = 1, uuid = 2868d135-cae5-4c1c-9e09-8316df57161f at _replay_find_log(/home/src/os/bluestore/BlueFS.cc:1127)

[OP_JUMP] disk_offset: 8642563080192 找到jump_seq = 2870589149, offset = 196608 at _replay_find_log(/home/src/os/bluestore/BlueFS.cc:1210)
```

那么接下来就是要跳转到 2870589149 + 1 = 2870589150.在fix_search中的位置是

Found UUID at offset: 681950707712, seq: 2870589150, internal_offset: 6

然后末尾是在这里

Found UUID at offset: 681954893824, seq: 2870589296, internal_offset: 6
Found UUID at offset: 682016014336, seq: 1388941352, internal_offset: 6

所以长度的话，应该是
682016014336 - 681950707712 = 65306624

我们再看一下原来的结构：

```
super.log_fnode.extents[0] = {.offset = 8642560655360, .length=196608, bdev=1} at _open_super(/home/src/os/bluestore/BlueFS.cc:905)

super.log_fnode.extents[1] = {.offset = 5884097200128, .length=4194304, bdev=1} at _open_super(/home/src/os/bluestore/BlueFS.cc:905)
```

正确的结构应该是

```
super.log_fnode.extents[0] = {.offset = 8642563080192, .length=196608, bdev=1} 

super.log_fnode.extents[1] = {.offset = 681950707712, .length=65306624, bdev=1}
```

这里还需要注意的是，后面的length这个长度需要是64K的整数倍。所以这里还需要修剪extents[1].length为64K的整数倍。

```
Found UUID at offset: 681954893824, seq: 2870589296, internal_offset: 6 <-- 这里最后一个版本
Found UUID at offset: 682016014336, seq: 1388941352, internal_offset: 6
```

但是，如果我们用682016014336来作为末尾，那么就会出问题，因为:

```
682016014336 - 681950707712 = 65306624
```

但是65306624不是64K的整数倍。需要681954893824往上64K取整对齐。
最终我们的结果是:

```
// 设置第一个扩展区 - 初始日志位置

super.log_fnode.extents[0].offset = 8642563080192ULL;

super.log_fnode.extents[0].length = 196608;

super.log_fnode.extents[0].bdev = dev_backup;

  

// 设置第二个扩展区 - 跳转目标位置（完整日志区）

super.log_fnode.extents[1].offset = 681950707712ULL;

super.log_fnode.extents[1].length = 4259840;

super.log_fnode.extents[1].bdev = dev_backup;

  

// 更新总分配大小

super.log_fnode.allocated = 196608 + 4259840;

super.log_fnode.allocated_commited = 196608 + 4259840;

super.log_fnode.size = 196608 + 4259840;
```

# OSD.8

第一步：

找到fsck日志里面的最后一行`[MAP] `

```
2025-10-23 03:04:36 4170 INFO: 140564847609152 [MAP] jump_seq = 3278856923, offset = 1858546630656 at _replay_find_log(/home/src/os/bluestore/BlueFS.cc:1239)
```

因为MAP用的是std::map，所以最后一行一定是最大的

第二步：

以`3278856923`最大序号为关键字。找到

```
2025-10-23 02:41:57 4170 INFO: 140564847609152 找到日志头: disk_offset = 1858546630656, seq = 1, uuid = 7d7e8401-9942-48d3-995b-e415f24a3993 at _replay_find_log(/home/src/os/bluestore/BlueFS.cc:1127)
2025-10-23 02:41:57 4170 INFO: 140564847609152 [OP_JUMP] disk_offset: 1858546630656 找到jump_seq = 3278856923, offset = 327680 at _replay_find_log(/home/src/os/bluestore/BlueFS.cc:1210)
```

从这两行，我们知道：

extent[0] = {.offset = 1858546630656, .length 327680}

第三步：





