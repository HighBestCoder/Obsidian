
# Env prepare
```
docker run -idt --name rocky9-ceph rockylinux:9.3 /bin/bash
# or use host network
# docker run -idt --network=host --name rocky9-ceph rockylinux:9.3 /bin/bash

docker exec -it -u 0 rocky9-ceph /bin/bash
```

# Compile ceph

```
yum update
yum install -y git vim epel-release yum-utils device-mapper-persistent-data lvm2

sed -i "s,enabled=0,enabled=1,g" /etc/yum.repos.d/rocky-devel.repo
yum update

cd /opt
git clone https://github.com/ceph/ceph.git
# or use internal git repo
# git clone https://gitee.com/mirrors/ceph.git

cd ceph
git checkout v17.2.5

sed -i "s,centos|fedora,rocky|fedora,g" ./install-deps.sh

./install-deps.sh
./do_cmake.sh

cd build
ninja

# Then all the binarys are in ./build/bin/ dir.
```

