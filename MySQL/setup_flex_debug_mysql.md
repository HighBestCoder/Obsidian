# 创建虚拟机

```bash

vm_name="yoj-debug-mysql2";

az vm create \
    --name ${vm_name} \
    --image MicrosoftCBLMariner:cbl-mariner:cbl-mariner-2:latest \
    --assign-identity [system] \
    --resource-group migration-group \
    --admin-username yoj \
    --ssh-key-values 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDOfMy8MXU12DPRicqJLSjWsHFu5if/2XLaJMbFnZvEmZ9khDGCLgY/ENYAVbOvBYfIzdxKIoc+h6Xg8QiFv2TGPh7Jh5d+IKP7LHeGjsjsHg3ky7aL/f2ysYOd2+Rp1JbtVaF5laIHOSvwEmVK1EQ3VX3BD6xK/kp4GnEw9qRIDzH4yGck2UIy0dVaAKfm7A/6QDrXo2DRr9AciRa5zgyzHnV7N6m4cUT1Fk8LAJ6WcCxSyNCcJvnmN/zI0UEjwj+tpC8nwBsmavGYnxz3Q4sLO2yw7HfFpmXrVvXT44vNfPVV9rC7/d054czrGE/RPbgjPPGatA3za/E6L6YSCdbq6sSJXsTVnH/uZcwKShjifYZEW+o93e1MaAPGvj7mXL2/LB15HFah0B2zqOjfmKqBDPoQDXild+M/ze1Epiom+TuIWk+cJs2tm7A6FaL7JbYNoBHrC+XR2y15l588JdbdVAT9L88SpOZ+KLzNopAngxHfkW9uTU6HCQgHQ0b6Ivc= yoj@Yous-MacBook-Pro.local' \
    --os-disk-size-gb 16 \
    --public-ip-sku Standard \
    --location northeurope \
    --subscription 2941a09d-7bcf-42fe-91ca-1765f521c829 \
    --size Standard_D8ds_v4
```

# 创建磁盘

```Bash
disk_name="yoj-debug-mysql-src-disk";
az disk create \
    --resource-group migration-group \
    --name ${disk_name} \
    --sku Standard_LRS \
    --size-gb 512 \
    --location northeurope \
    --subscription 2941a09d-7bcf-42fe-91ca-1765f521c829

```
# 挂载磁盘

```Bash
az vm disk attach \
    --resource-group migration-group \
    --vm-name ${vm_name} \
    --name ${disk_name} \
    --subscription 2941a09d-7bcf-42fe-91ca-1765f521c829

```

# SSH到debug VM的初始化

```Bash
cd ~
cat <<"EOF"> init.sh
#!/bin/bash

# Check if script is run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Install necessary packages
tdnf install -y mariner-repos-extended
tdnf update
tdnf install -y diffutils openssh-server openssh-clients keyutils cifs-utils vim git jemalloc capstone

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
EOF

chmod +x init.sh
./init.sh
```

# 挂载磁盘到/src

```bash
cat <<"EOF">mount.sh
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
EOF
chmod +x mount.sh

disk_path=`fdisk -l | grep "^Disk " | grep ": 512 GiB" | awk '{print $2}' | sed "s,:,,g"`

mkdir -p /src

./mount.sh ${disk_path} /src
```

# 放ssh private key

安装

tdnf install dotnet-sdk-7.0
检查 
dotnet --version 

安装证书管理
dotnet tool install -g git-credential-manager

安装成功之后，需要重新连上linux

git-credential-manager configure
git config --global credential.azreposCredentialType oauth

然后下载代码

 git clone https://msdata.visualstudio.com/DefaultCollection/Database%20Systems/_git/orcasql-mysql mysql


# 修改CMakefiles.txt 8.0


为了在调试的时候，我们能够拿到符号表，相应的值。这里我们需要在编译的时候，带上编译信息。所以我们需要修改一下CMakefiles.txt和build.sh


```
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -g")
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
```

![[Pasted image 20240315111742.png]]

# 修改build.sh 8.0

```bash
cmake_args='-DWITH_BOOST=../source_downloads -DENABLE_EXPERIMENT_SYSVARS=ON -DWITHOUT_GROUP_REPLICATION=ON -DWITH_ZLIB=system -DWITH_NDB=OFF -DWITHOUT_NDBCLUSTER_STORAGE_ENGINE=ON -DMINIMAL_RELWITHDEBINFO=OFF -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_CXX_FLAGS=-O0 -DCMAKE_C_FLAGS=-O0'
```

# 修改 build.sh 5.7

```bash
cmake_args="-DWITH_BOOST=../source_downloads/mysql-boost/$MYSQL_BOOST_VERSION/content -DWITH_GMOCK=../source_downloads -DWITH_ZLIB=system"
```





# 拿token

```
Goto [https://msdata.visualstudio.com/_usersSettings/tokens](https://msdata.visualstudio.com/_usersSettings/tokens "https://msdata.visualstudio.com/_userssettings/tokens")  
1. click the +New Token button on top right.  
2. name of the PAT = Choose Expiration(UTC) =  custom define the expire time  
3. Organization = All accessible organizations  
4. Scopes = Custom defined  
5. Packaging = Read  
6. Click the Create button on bottom  
7. Copy the new genereated token and save it in a temporary file, we will use it later.
```

token大概长成这样`pvx5va`

# 编译msyql

注意换`6rbrd5va`成新的token

```Bash
tdnf install -y git vim capstone
cd /src

git clone msdata@vs-ssh.visualstudio.com:v3/msdata/Database%20Systems/orcasql-mysql

cd /src/orcasql-mysql
git checkout 50091de2082e1adf002c9019239d7249a7362dbc
./setupnuget.sh yoj sdfsdfsdfsdf5va
./init.sh
./build.sh
```

# 准备文件pfs-mount.sh

```Bash
cat <<"EOF"> pfs-mount.sh

#!/bin/bash

# Check if the correct number of arguments are passed
if [ "$#" -ne 2 ]; then
    echo "Usage: \$0 <username> <password>"
    exit 1
fi

USERNAME=$1
PASSWORD=$2

# Create the necessary directories
mkdir -p /app/work
mkdir -p /etc/smbcredentials

# Create the credentials file if it doesn't exist
CREDENTIALS_FILE="/etc/smbcredentials/${USERNAME}.cred"
if [ ! -f "${CREDENTIALS_FILE}" ]; then
    echo "username=${USERNAME}" > "${CREDENTIALS_FILE}"
    echo "password=${PASSWORD}" >> "${CREDENTIALS_FILE}"
    chmod 600 "${CREDENTIALS_FILE}"
fi

# Add the mount point to /etc/fstab
echo "//${USERNAME}.file.core.windows.net/share /app/work cifs nofail,credentials=${CREDENTIALS_FILE},dir_mode=0777,file_mode=0777,serverino,nosharesock,actimeo=30" >> /etc/fstab

# Mount the share
mount -t cifs //${USERNAME}.file.core.windows.net/share /app/work -o credentials=${CREDENTIALS_FILE},dir_mode=0777,file_mode=0777,serverino,nosharesock,actimeo=30

mkdir -p /src/start

echo "export MY_VERLAINE_KEY=${2}" > /src/start/fsenv
echo "export MY_VERLAINE_DOMAIN=file.core.windows.net" >> /src/start/fsenv
echo "export MY_VERLAINE_ACCOUNT=${1}" >> /src/start/fsenv
echo "export MY_VERLAINE_SHARE=share" >> /src/start/fsenv
EOF
```

# onebox上拿参数

接下来，我们需要拿pfs的参数:

这个脚本的两个参数，需要到onebox的meru server上去看:
```
# cat /etc/smbcredentials/*
username=dfsdata
password=w==
```

# debug server挂载pfs

然后我们运行这个脚本来挂载pfs

```Bash
./pfs-mount.sh dfsdata w==
```


# onebox server上copy文件

现在到onebox-meru server vm中准备copy文件

```
docker exec -it -u 0 MySQL /bin/bash
cd /app/work/temp/
cp -rf /mysql/lib ./

cp -rf my.ini verlaine.env launcher/vml_file_settings.json /app/work/temp/
```

这里会看到
```
cp: cannot create symbolic link './lib/private/libsyscall_intercept.so.0': Operation not supported
```
这个不重要。只是说软链接文件copy失败。后面我们会在debug节点上进行重建这个软链接。

# debug server pfs copy文件到debug vm

```Bash

mkdir -p /src/start
cd /src/start

cp -rf /app/work/temp/my.ini /app/work/temp/verlaine.env /app/work/temp/vml_file_settings.json ./
```

# debug vm上的启动脚本 (8.0)
```Bash
cd /src/start

cat <<"EOF"> start
#!/bin/bash

truncate -s 0 /var/log/messages

BASE="/src/start"

if [[ ! -e /mysql/lib ]]; then
    cp -rf /app/work/temp/lib /mysql/
fi

source ${BASE}/fsenv
source ${BASE}/verlaine.env

export MYFILE_MOUNT="/app/work"
export MOUNT_DIR="/app/work"
export FUSE_DIR="/app/work2"
export BASE_FOLDER="/mysql"
export DATA_FOLDER="$MOUNT_DIR/data"
export TEMP_FOLDER="$MOUNT_DIR/temp"
export BINLOGS_DIR="$MOUNT_DIR/binlogs"
export SETUP_COOKIE="$DATA_FOLDER/.setup"
export ENGINE_VERSION_COOKIE="$DATA_FOLDER/.dataversion"
export VERSION_UPGRADING_COOKIE="$DATA_FOLDER/.versionupgrading"
export BUILD_NUMBER_COOKIE="$DATA_FOLDER/.build_number"
export ENGINE_RUNNING_COOKIE="$DATA_FOLDER/.running"
export ENGINECONTAINERSTARTTIME="$DATA_FOLDER/.enginecontainerstarttime"
export DATAVERSIONUPGRADE="$DATA_FOLDER/.dataversionupgrade"
export GARBAGE_DATA_FILE=$DATA_FOLDER/''$'\003'
export INIT_FILE="$MOUNT_DIR/bootstrap.sql"
export MYSQLD_PID="-1"
export PRELOAD_LIBS=""
export IS_STANDALONE=0
export REPLICATION_SET_ROLE_FILE="$MOUNT_DIR/replication_set_role.cnf"
export REPLICATION_SET_ROLE="Single"
export LOG_DISK="/dev/disk0"
export VFS_TOOLS="$BASE_FOLDER/bin"
export VFS_HEADER_BASE_STR=$(cat /etc/hostname)
export REDO_FS_NAME="disk_for_redofs"
export BINLOG_FS_NAME="disk_for_binlogfs"
export MYSQL_MB=$((1024*1024))
export MYSQL_GB=$((MYSQL_MB*1024))
export REDOFS80D_LENGTH=16649289728

rm -rf ln -s /mysql/lib/private/libsyscall_intercept.so.0
ln -s /mysql/lib/private/libsyscall_intercept.so /mysql/lib/private/libsyscall_intercept.so.0

export VML_FILE_SETTINGS_JSON_PATH="${BASE}/vml_file_settings.json"
export LD_LIBRARY_PATH=/mysql/lib/private:$LD_LIBRARY_PATH
mkdir -p /mnt/temp
mkdir -p /tmp/mysql


dir_to_add="/src/orcasql-mysql/out/bin"
# 检查~/.bashrc中是否已经存在"orcasql-mysql"
cnt=$(grep -c "orcasql-mysql" ~/.bashrc)

if [[ $cnt -eq 0 ]]; then
    # 将路径添加到PATH变量，并保存到~/.bashrc文件中
    echo "export PATH=\$PATH:$dir_to_add" >> ~/.bashrc

    # 使改动立即生效
    source ~/.bashrc

    echo "Path added successfully."
else
    echo "Path is already in ~/.bashrc."
fi

# start with release version and with debug info
LD_PRELOAD="/mysql/lib/private/libsyscall.so /mysql/lib/private/libmyaio.so /usr/lib/libjemalloc.so.2" \
 /src/orcasql-mysql/out/runtime_output_directory/mysqld                                                \
 --defaults-file=${BASE}/my.ini                                                                        \
 --basedir=/mysql                                                                                      \
 --datadir=/app/work/data                                                                              \
 --console                                                                                             \
 --core-file                                                                                           \
 --user=root
EOF

chmod +x start
```

# debug vm上的启动脚本(5.7)

```bash
#!/bin/bash

set -e

truncate -s 0 /var/log/messages

BASE="/src/start"

if [[ ! -e /mysql/lib ]]; then
    cp -rf /app/work/temp/lib /mysql/
fi

source ${BASE}/fsenv
source ${BASE}/verlaine.env

export MYFILE_MOUNT="/app/work"
export MOUNT_DIR="/app/work"
export FUSE_DIR="/app/work2"
export BASE_FOLDER="/mysql"
export DATA_FOLDER="$MOUNT_DIR/data"
export TEMP_FOLDER="$MOUNT_DIR/temp"
export BINLOGS_DIR="$MOUNT_DIR/binlogs"
export SETUP_COOKIE="$DATA_FOLDER/.setup"
export ENGINE_VERSION_COOKIE="$DATA_FOLDER/.dataversion"
export VERSION_UPGRADING_COOKIE="$DATA_FOLDER/.versionupgrading"
export BUILD_NUMBER_COOKIE="$DATA_FOLDER/.build_number"
export ENGINE_RUNNING_COOKIE="$DATA_FOLDER/.running"
export ENGINECONTAINERSTARTTIME="$DATA_FOLDER/.enginecontainerstarttime"
export DATAVERSIONUPGRADE="$DATA_FOLDER/.dataversionupgrade"
export GARBAGE_DATA_FILE=$DATA_FOLDER/''$'\003'
export INIT_FILE="$MOUNT_DIR/bootstrap.sql"
export MYSQLD_PID="-1"
export PRELOAD_LIBS=""
export IS_STANDALONE=0
export REPLICATION_SET_ROLE_FILE="$MOUNT_DIR/replication_set_role.cnf"
export REPLICATION_SET_ROLE="Single"
export LOG_DISK="/dev/disk0"
export VFS_TOOLS="$BASE_FOLDER/bin"
export VFS_HEADER_BASE_STR=$(cat /etc/hostname)
export REDO_FS_NAME="disk_for_redofs"
export BINLOG_FS_NAME="disk_for_binlogfs"
export MYSQL_MB=$((1024*1024))
export MYSQL_GB=$((MYSQL_MB*1024))
export REDOFS80D_LENGTH=16649289728

rm -rf /mysql/lib/libsyscall_intercept.so.0
ln -s /mysql/lib/libsyscall_intercept.so /mysql/lib/libsyscall_intercept.so.0

export VML_FILE_SETTINGS_JSON_PATH="${BASE}/vml_file_settings.json"
export LD_LIBRARY_PATH=/mysql/lib:$LD_LIBRARY_PATH
mkdir -p /mnt/temp
mkdir -p /tmp/mysql


dir_to_add="/src/orcasql-mysql/out/bin"
# 检查~/.bashrc中是否已经存在"orcasql-mysql"
cnt=$(grep -c "orcasql-mysql" ~/.bashrc)

if [[ $cnt -eq 0 ]]; then
    # 将路径添加到PATH变量，并保存到~/.bashrc文件中
    echo "export PATH=\$PATH:$dir_to_add" >> ~/.bashrc

    # 使改动立即生效
    source ~/.bashrc

    echo "Path added successfully."
else
    echo "Path is already in ~/.bashrc."
fi

mkdir -p /app/work/binlogs/

# start with release version and with debug info
LD_PRELOAD="/mysql/lib/libsyscall.so /mysql/lib/libmyaio.so /usr/lib/libjemalloc.so.2" \
 /src/orcasql-mysql/out/sql/mysqld                                                                     \
 --defaults-file=${BASE}/my.ini                                                                        \
 --basedir=/mysql                                                                                      \
 --datadir=/app/work                                                                                   \
 --console                                                                                             \
 --core-file                                                                                           \
 --user=root
```

# 连接 mysql

```Bash
ln -s /tmp/mysql/mysql.sock /tmp/mysql.sock
 mysql -uazure_superuser
```


# 连接

```bash
 mysql -uazure_superuser
```

# 日志

注意：日志都是打到了/var/log/messages文件