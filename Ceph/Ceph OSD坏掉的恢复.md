
以下为在 OSD.5 无法启动（错误为 `bluefs _replay 0x0 stop uuid ... != super.uuid ...`）的情况下，尝试导出 PG 数据并恢复 OSD 的详细处理流程。

---

## 场景说明

- 目标 OSD：`osd.5`
    
- 错误信息：`bluefs _replay 0x0 stop uuid ... != super.uuid ...`
    
- 磁盘路径：`/dev/disk/by-partlabel/KOLLA_CEPH_DATA_BS_5_B`
    
- OSD 数据目录：`/var/lib/ceph/osd/ceph-5`
    
- 目标操作：导出 PG → 重建 OSD → 重新导入 PG 至新 OSD.5
    

---

## 操作流程

### 1. 停止 OSD.5 守护进程

在所有操作开始之前，需确保 OSD.5 处于停止状态。

```bash
systemctl stop ceph-osd@5
```

确认 OSD 进程已退出：

```bash
ps -ef | grep ceph-osd | grep '\-i 5'
```

---

### 2. 查询 osd.5 所持有的 PG 列表

执行如下命令获取 PG 列表：

```bash
ceph pg ls-by-osd 5
```

记录所有 `PGID`，供后续导出使用。

当然，如果ceph osd完全死透，你可以假设坏掉的pg都在这个osd上。导出失败了就标记这个pg不在这个osd上。

---

### 3. 导出 osd.5 上的 PG 数据（如可访问）

使用 `ceph-objectstore-tool` 执行离线导出：

```bash
ceph-objectstore-tool \
  --data-path /var/lib/ceph/osd/ceph-5 \
  --op export \
  --pgid <pgid> \
  --file /tmp/<pgid>.export
```

示例：

```bash
ceph-objectstore-tool \
  --data-path /var/lib/ceph/osd/ceph-5 \
  --op export \
  --pgid 8.f \
  --file /tmp/pg_8.f.export
```

**注意：** 若 BlueFS 元数据严重损坏，部分 PG 导出操作可能失败。在此情况下，该 PG 的数据应依赖集群中其他副本恢复。

---

### 4. 清除 osd.5 原有数据

执行磁盘擦除操作，清空原有的 OSD 数据内容：

```bash
ceph-volume lvm zap /dev/disk/by-partlabel/KOLLA_CEPH_DATA_BS_5_B --destroy
```

若使用 raw 模式部署，也可使用：

```bash
ceph-bluestore-tool zap \
  --dev /dev/disk/by-partlabel/KOLLA_CEPH_DATA_BS_5_B \
  --force
```

---

### 5. 重建 osd.5 实例（保留原 OSD ID）

执行以下命令重建 OSD 实例，并指定原有的 osd-id：

```bash
ceph-volume lvm create \
  --bluestore \
  --data /dev/disk/by-partlabel/KOLLA_CEPH_DATA_BS_5_B \
  --osd-id 5 \
  --osd-uuid $(uuidgen)
```

系统会自动创建新的 `osd.5` 数据目录和相关初始化元数据。

这里使用了ceph-volume重建osd.5，你也可以使用你熟悉的工具来重建osd.5。

---

### 6. 导入之前导出的 PG 数据

若希望继续将原 PG 数据导入新建的 OSD.5，需要再次确保 osd.5 停止运行：

```bash
systemctl stop ceph-osd@5
```

然后使用以下命令逐个导入 PG：

```bash
ceph-objectstore-tool \
  --data-path /var/lib/ceph/osd/ceph-5 \
  --op import \
  --file /tmp/<pgid>.export
```

示例：

```bash
ceph-objectstore-tool \
  --data-path /var/lib/ceph/osd/ceph-5 \
  --op import \
  --file /tmp/pg_8.f.export
```

---

### 7. 启动 osd.5 并修复 PG

完成导入后启动 osd.5：

```bash
systemctl start ceph-osd@5
```

执行 PG 修复：

```bash
ceph pg repair <pgid>
```

---

## 注意事项

- 若部分 PG 无法导出或导入，应将其标记为失效，并依赖集群的其他副本完成数据恢复。
    
- 对导出的 PG 文件进行校验和备份，防止在导入过程中损坏。
    
- 若集群中存在多个无法访问的 PG 副本，建议评估数据完整性风险后进行操作。
    
- 建议操作前执行完整的 `ceph health detail` 和 `ceph osd tree` 输出分析。
    

---

该流程适用于在 BlueFS 元数据出错导致 OSD 无法启动时，最大限度尝试保留可访问 PG 的数据。若导出失败，也可仅完成 OSD 重建，由 Ceph 自动完成 PG 副本修复。

启动ceph docker container

```bash
docker run -idt --privileged --device=/dev/sdf --cap-add=SYS_ADMIN -v /dev:/dev -v /ceph:/ceph --name ceph2 ubuntu:22.04 /bin/bash
```

# 编译之后，测试集群

```bash
cd /ceph 
cat README.md
cd build
ps aux | grep ceph | awk '{print $2}' | xargs -i kill -9 {}
MON=1 MDS=0 OSD=0 VSTART_DEST="/ceph/ceph/build/out" ../src/vstart.sh -d -n -x
```

然后再用这个脚本添加一个osd进去

```
#!/bin/bash
set -e

CEPH_SRC_DIR="/ceph/ceph"
BUILD_DIR="$CEPH_SRC_DIR/build"
OUT_DIR="$BUILD_DIR/out"
OSD_DISK="/dev/sdf"
CEPH_BIN="$BUILD_DIR/bin"
CEPH_CONF="$OUT_DIR/ceph.conf"
CEPH_KEYRING="$OUT_DIR/keyring"

# Step 1: 检查设备是否存在
if [ ! -b "$OSD_DISK" ]; then
    echo "[!] 设备 $OSD_DISK 不存在，退出"
    exit 1
fi

echo "[*] 清理 $OSD_DISK 上的旧数据"
dd if=/dev/zero of=$OSD_DISK bs=1M count=10 status=none || true
wipefs -a $OSD_DISK || true

# Step 2: 创建新的 OSD ID
OSD_ID=$($CEPH_BIN/ceph osd create)
echo "[*] 分配到新的 OSD ID: $OSD_ID"

OSD_DATA_DIR="$OUT_DIR/osd.$OSD_ID"
mkdir -p "$OSD_DATA_DIR"

# Step 3: 格式化设备为 BlueStore 并初始化
echo "[*] 格式化设备为 BlueStore 并写入 OSD 数据"
# 格式化 BlueStore
$CEPH_BIN/ceph-osd \
  --mkfs \
  -i $OSD_ID \
  --osd-objectstore bluestore \
  --osd-data "$OSD_DATA_DIR" \
  --block-device "$OSD_DISK" \
  --conf "$CEPH_CONF" \
  --keyring "$CEPH_KEYRING" \
  --no-mon-config

# Step 4: 启动 OSD 守护进程
echo "[*] 启动 ceph-osd 守护进程（ID=$OSD_ID）"
$CEPH_BIN/ceph-osd \
  -i $OSD_ID \
  --osd-data "$OSD_DATA_DIR" \
  --conf "$CEPH_CONF" \
  --keyring "$CEPH_KEYRING" \
  --debug-osd 20 --debug-bluestore 30 --debug-bluefs 30 &

# Step 5: 标记为 in & 检查状态
sleep 5
$CEPH_BIN/ceph osd crush add osd.$OSD_ID 1.0 host=localhost root=default
$CEPH_BIN/ceph osd in osd.$OSD_ID
$CEPH_BIN/ceph -s


```


注意：这里一定要在build目录里面运行这个。运行成功之后。

```bash
ln -s /ceph/ceph/build/out /etc/ceph
export PATH=$PATH:$(pwd)/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$(pwd)/lib
```

然后就可以运行`ceph -s`

```
# create test-pool
ceph osd pool create test-pool 64 64
```

# 放些文件到test-pool

```
root@c47b315aad39:/ceph/ceph/build/bin# cat ./put.sh 
#!/bin/bash

# 指定你的Ceph集群池的名称
POOL_NAME="test-pool"

# 遍历当前目录下的所有文件
for file in $(ls)
do
    # 使用rados命令将文件放入Ceph集群池中
    rados -p $POOL_NAME put $file $file
done

```




