
# 15个PG unknown

![[96c31fc819d32dd8f2f871bf492fe5d.jpg]]
# 有4个OSD Down

![[693cc3b3b3f302bbbd982d744410caa.jpg]]


故障根因初判：osd 使用raid 卡缓存加速（raid0）,没有BBU。赶上突然掉电。

# 四个OSD出错原因

![[9b5ac5db39634bd5dfd96a57c68780a.png]]

# fsck出错

![[728178199dca0b8f60b8a737f821e9f.jpg]]

# 修复环境

编译环境
1：编译容器在control01节点，docker exec -it ceph_comp bash 进入容器
2：打patch 方式，将patch 拷贝到ceph_comp容器的目录，进入容器之后/tmp/apply_pathch.sh  patch_name
3：使用git 查看分支，切换到cd /ceph/ceph 
4： 编译路径cd /ceph/ceph/build/

容器拷贝文件方式：
1：从容器拷贝文件到本地  docker cp ceph_comp:/ceph/ceph/build/bin/ceph-bluestore-tool .
2： 从本地拷贝文件到容器  docker cp ./filename  ceph_comp:/tmp

目前ceph 状态
1：control02 节点的osd4 容器已经up，数据在同步。
2：control03 节点的osd22 容器在跑fix_search 程序，可使用tmux at -t 0 进入tmux 终端，查看运行结果。
3：执行ceph 命令可以在control01 物理机直接执行ceph -s 查看状态

osd 容器内执行命令
1：编译好的命令位于osd 容器的/tmp 目录，可以使用决定路径/tmp/fix_search 或者相对路径cd /tmp/ && ./fix_search 执行命令


# 出错日志

从osd.4, osd.5, osd.22的出错日志看来：就是在这里出错。

![[728178199dca0b8f60b8a737f821e9f.jpg]]

体现在代码里面就是：

```C++

int BlueFS::_replay(bool noop, bool to_stdout)
{
  dout(10) << __func__ << (noop ? " NO-OP" : "") << dendl;
  ino_last = 1;  // by the log
  log_seq = 0;

  FileRef log_file;
  log_file = _get_file(1);

  log_file->fnode = super.log_fnode;
  if (!noop) {
    log_file->vselector_hint =
      vselector->get_hint_for_log();
  } else {
    // do not use fnode from superblock in 'noop' mode - log_file's one should
    // be fine and up-to-date
    ceph_assert(log_file->fnode.ino == 1);
    ceph_assert(log_file->fnode.extents.size() != 0);
  }
  dout(10) << __func__ << " log_fnode " << super.log_fnode << dendl;
  if (unlikely(to_stdout)) {
    std::cout << " log_fnode " << super.log_fnode << std::endl;
  } 

  FileReader *log_reader = new FileReader(
    log_file, cct->_conf->bluefs_max_prefetch,
    false,  // !random
    true);  // ignore eof

  bool seen_recs = false;

  boost::dynamic_bitset<uint64_t> used_blocks[MAX_BDEV];

  if (!noop) {
    if (cct->_conf->bluefs_log_replay_check_allocations) {
      for (size_t i = 0; i < MAX_BDEV; ++i) {
	if (alloc_size[i] != 0 && bdev[i] != nullptr) {
	  used_blocks[i].resize(round_up_to(bdev[i]->get_size(), alloc_size[i]) / alloc_size[i]);
	}
      }
      // check initial log layout
      int r = _check_allocations(log_file->fnode,
				 used_blocks, true, "Log from super");
      if (r < 0) {
	return r;
      }
    }
  }
  
  while (true) {
    ceph_assert((log_reader->buf.pos & ~super.block_mask()) == 0);
    uint64_t pos = log_reader->buf.pos;
    uint64_t read_pos = pos;
    bufferlist bl;
    {
      int r = _read(log_reader, read_pos, super.block_size,
		    &bl, NULL);
      if (r != (int)super.block_size && cct->_conf->bluefs_replay_recovery) {
	r += do_replay_recovery_read(log_reader, pos, read_pos + r, super.block_size - r, &bl);
      }
      assert(r == (int)super.block_size);
      read_pos += r;
    }
    uint64_t more = 0;
    uint64_t seq;
    uuid_d uuid;
    {
      auto p = bl.cbegin();
      __u8 a, b;
      uint32_t len;
      decode(a, p);
      decode(b, p);
      decode(len, p);
      decode(uuid, p);
      decode(seq, p);
      if (len + 6 > bl.length()) {
	more = round_up_to(len + 6 - bl.length(), super.block_size);
      }
    }
    if (uuid != super.uuid) {
      if (seen_recs) {
	dout(10) << __func__ << " 0x" << std::hex << pos << std::dec
		 << ": stop: uuid " << uuid << " != super.uuid " << super.uuid
		 << dendl;
      } else {
	derr << __func__ << " 0x" << std::hex << pos << std::dec
		 << ": stop: uuid " << uuid << " != super.uuid " << super.uuid
		 << ", block dump: \n";
	bufferlist t;
	t.substr_of(bl, 0, super.block_size);
	t.hexdump(*_dout);
	*_dout << dendl;
      }
      break;
    }
    if (seq != log_seq + 1) {
      if (seen_recs) {
	dout(10) << __func__ << " 0x" << std::hex << pos << std::dec
		 << ": stop: seq " << seq << " != expected " << log_seq + 1
		 << dendl;;
      } else {
	derr << __func__ << " 0x" << std::hex << pos << std::dec
	     << ": stop: seq " << seq << " != expected " << log_seq + 1
	     << dendl;;
      }
      break;
    }
    ///.... 后面有其他代码
  }
  if (!noop) {
    vselector->add_usage(log_file->vselector_hint, log_file->fnode);
  }

  dout(10) << __func__ << " log file size was 0x"
           << std::hex << log_file->fnode.size << std::dec << dendl;
  if (unlikely(to_stdout)) {
    std::cout << " log file size was 0x"
              << std::hex << log_file->fnode.size << std::dec << std::endl;
  }

  delete log_reader;

  if (!noop) {
    // verify file link counts are all >0
    for (auto& p : file_map) {
      if (p.second->refs == 0 &&
	  p.second->fnode.ino > 1) {
	derr << __func__ << " file with link count 0: " << p.second->fnode
	     << dendl;
	return -EIO;
      }
    }
  }

  dout(10) << __func__ << " done" << dendl;
  return 0;
}
```

看日志，出问题就是出在：

```C++
    if (uuid != super.uuid) {
      if (seen_recs) {
	dout(10) << __func__ << " 0x" << std::hex << pos << std::dec
		 << ": stop: uuid " << uuid << " != super.uuid " << super.uuid
		 << dendl;
      } else {
	derr << __func__ << " 0x" << std::hex << pos << std::dec
		 << ": stop: uuid " << uuid << " != super.uuid " << super.uuid
		 << ", block dump: \n";
      }
      break;
    }
    if (seq != log_seq + 1) {
      if (seen_recs) {
	dout(10) << __func__ << " 0x" << std::hex << pos << std::dec
		 << ": stop: seq " << seq << " != expected " << log_seq + 1
		 << dendl;;
      } else {
	derr << __func__ << " 0x" << std::hex << pos << std::dec
	     << ": stop: seq " << seq << " != expected " << log_seq + 1
	     << dendl;;
      }
      break;
    }
```

也就是发现uuid != super.uuid的时候，就会退出。那么接下来就需要去了解一下bluefs super block以及_replay的逻辑。

# BlueFS的设计

BlueFS作为一个非常简易的文件系统，首先我们可以看一下super block。也就是文件系统的引导块。

- super block位于磁盘的第二个4K块。也就是4096 ~ 8192。super block本身要存放的内容并不多。所以4K是绝对足够的。

这里可以将这个super block以json的形式打开，然后看一下：

```json
{
  "super": {
    "dev_name": "sdc",
    "uuid": "8e0025bd-a850-44ca-b4e1-fab8013b82ba",
    "version": 112070,
    "block_size": 4096,
    "log_fnode": {
      "ino": 1,
      "size": 196608,
      "allocated": 4390912,
      "alloc_commit": 4390912,
      "extents": [
        {
          "offset": 3159221141504,
          "length": 196608,
          "bdev": 1
        },
        {
          "offset": 3159216947200,
          "length": 4194304,
          "bdev": 1
        }
      ]
    }
  }
}
```

当然，在c++代码中，super block的磁盘结构是如下定义的：

```C++

```