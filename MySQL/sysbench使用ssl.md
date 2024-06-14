
```
./sysbench_changed oltp_read_write.lua \  
    --db-driver=mysql \  
    --mysql-host=${host} \  
    --mysql-port=3306 \  
    --mysql-user=${user} \  
    --mysql-password=${password} \  
    --mysql-db=${database} \  
    --tables=${table_number} \  
    --table-size=${table_size} \  
    --report-interval=1 \  
    --time=600 \  
    --threads=${table_number} \  
    --percentile=99 \  
    --thread-init-timeout=300 \  
    --mysql-ssl=required --mysql-ssl-ca=/opt/DigiCert_Global_Root_G2.pem \  
    run | tee perf-${host}-${table_number}-${table_size}.log
```

这个文件是通过

```
strace -f -e trace=file mysql -hyoj-test-sbs-10g.mysql.database.azure.com -uyoj@yoj-test-sbs-10g
```

这个命令抓出来的。

我发现它会去读``/usr/lib/ssl/certs/607986c7.0`：这是SSL证书文件，用于验证SSL连接的身份。



