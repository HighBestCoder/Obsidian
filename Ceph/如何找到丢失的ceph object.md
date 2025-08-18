
首先通过标记lost的pg里面list unfound

```json
root@yoj-arm-test:/ceph/0427# cat 7.5b2_list_unfound.log
{
    "num_missing": 1,
    "num_unfound": 1,
    "objects": [
        {
            "oid": {
                "oid": "rbd_data.11c804ec8012d5.000000000000f8e3",
                "key": "",
                "snapid": -2,
                "hash": 4062754226,
                "max": 0,
                "pool": 7,
                "namespace": ""
            },
            "need": "31228'1054954",
            "have": "0'0",
            "flags": "none",
            "clean_regions": "clean_offsets: [], clean_omap: 0, new_object: 1",
            "locations": []
        }
    ],
    "state": "NotRecovering",
    "available_might_have_unfound": true,
    "might_have_unfound": [],
    "more": false
}
```

这样，我们可以找到对应的rbd object 以及相应的offset。

# 找到所有volume的信息

```bash
#!/bin/bash

# 获取所有的 Ceph 池，排除 rgw 池
pools=$(ceph osd pool ls | grep -v "rgw")

# 对每个池进行操作
for pool_name in $pools; do
    # 列出该池中的所有 RBD 镜像
    rbd_ls=$(rbd ls -p $pool_name)

    # 对池中的每个镜像进行操作
    for item in $rbd_ls; do
        # 获取 block_name_prefix
        name_prefix=$(rbd info ${pool_name}/${item} | grep block_name_prefix | awk -F ':' '{print $2}' | xargs)

        # 输出镜像的路径
        echo "${pool_name} ${item} ${name_prefix}"
    done
done
```

通过这个bash可以找到volume以及volume对应的`rbd_data.11c804ec8012d5`。

找到volume之后，就可以通过`rbd_data.11c804ec8012d5`找到哪些volume丢失了。