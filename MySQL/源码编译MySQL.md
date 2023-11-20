# 编译

```Cpp
apt-get install -y gcc-8 g++-8 libssl-dev libaio-dev libisal-dev libncurses5-dev libnuma-dev bison cmake g++ git perl-modules sed unzip tar systemtap-sdt-dev pkg-config patchelf zlib1g-dev

mkdir -p build
cd build
cmake .. -DCMAKE_EXPORT_COMPILE_COMMANDS=1 -DCMAKE_INSTALL_PREFIX=/opt/mysql -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DENABLED_LOCAL_INFILE=ON -DWITH_INNODB_MEMCACHED=ON -DWITH_INNOBASE_STORAGE_ENGINE=1 -DDOWNLOAD_BOOST=1 -DWITH_BOOST=../download -DWITH_DEBUG=1

make -j16
make install
```


# 配置

```Cpp
groupadd mysql
useradd -g mysql mysql

#mysql数据目录
mkdir -p /src/mysql/data

#mysql日志目录
mkdir -p /src/mysql/logs

#mysql 建立连接时存放.sock 文件的目录
mkdir /var/lib/mysql


#修改目录权限为mysql
chown -R mysql:mysql /src/mysql
chown -R mysql:mysql /src/mysql

mkdir -p /usr/local/mysql
chown -R mysql:mysql /usr/local/mysql
chown -R mysql:mysql /var/lib/mysql

cat <<"EOF" > /etc/my.cnf
# For advice on how to change settings please see
# http://dev.mysql.com/doc/refman/8.0/en/server-configuration-defaults.html

[mysqld]
#
# Remove leading # and set to the amount of RAM for the most important data
# cache in MySQL. Start at 70% of total RAM for dedicated server, else 10%.
# innodb_buffer_pool_size = 128M
#
# Remove the leading "# " to disable binary logging
# Binary logging captures changes between backups and is enabled by
# default. It's default setting is log_bin=binlog
# disable_log_bin
#
# Remove leading # to set options mainly useful for reporting servers.
# The server defaults are faster for transactions and fast SELECTs.
# Adjust sizes as needed, experiment to find the optimal values.
# join_buffer_size = 128M
# sort_buffer_size = 2M
# read_rnd_buffer_size = 2M
#
# Remove leading # to revert to previous value for default_authentication_plugin,
# this will increase compatibility with older clients. For background, see:
# https://dev.mysql.com/doc/refman/8.0/en/server-system-variables.html#sysvar_default_authentication_plugin
# default-authentication-plugin=mysql_native_password

datadir=/src/mysql/data
socket=/usr/local/mysql/mysql.sock
sql_mode=STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITut

log-error=/src/mysql/logs/mysql.log
pid-file=/src/mysql/logs/mysql.pid
#设置不区分大小写
lower_case_table_names=1
EOF


chown -R mysql:mysql /etc/my.cnf
chmod 644 /etc/my.cnf

cd /opt/mysql/bin/
./mysqld --initialize --user=mysql --basedir=/src/mysql --datadir=/src/mysql/data

#  查看密码
cd /src/mysql/logs/
cat mysql.log  | grep " temporary password"

ln -s /usr/local/mysql/mysql.sock /tmp/mysql.sock

# 连进数据库之后，运行sql
alter user 'root'@'localhost' identified by 'fedora12@' ;



```

#