### 快速创建大文件
- 使用dd命令直接创建文件；创建一个10G的文件。（test1文件真实存储，实际占用空间，通过这种方式创建文件占用空间的耗时比较长，与实际拷贝的速度接近）
  > dd if=/dev/zero of=test1 bs=1G count=10
- 使用truncate直接创建文件；这种方式创建的文件被称为“空洞文件”，文件的部分内容并没有实际存在于硬盘上，用du命令查看文件占用的空间为0，创建文件不会报空间不足，速度快，但是不会真实占用空间
  > truncate -s 10G test2
- 使用fallocate命令创建文件
  > fallocate 命令可以为文件预分配物理空间，du命令也可以看到文件的大小，如果空间不足会提示，且创建文件失败，速度很快
### lsblk/blkid工具使用
- 查看/dev/sda1磁盘的UUID
  > blkid /dev/sda1
- 查看所有磁盘的UUID
  > blkid -o list
- 列出系统上的块设备
  > lsblk
---
### dmicecode工具使用
```bash
# 获取不同模块的信息
dmidecode -t bios/system/baseboard/chassis/processor/memory/cache/connector/slot
# 获取dell的sn
dmidecode -s system-serial-number
# 获取bios版本
dmidecode -s bios-version
# 获取产品名
dmidecode -s system-product-name
```
### CentOS7 做链路聚合，依然能使用bond，默认情况下NetworkManager程序中集成了teamd功能就来配置链路聚合。
* 使用nmcli进行聚合
  ```bash
  # Example Adding a bonding master and two slave connection profiles
  nmcli con add type bond ifname mybond0 mode active-backup
  nmcli con add type bond-slave ifname eth1 master mybond0
  nmcli con add type bond-slave ifname eth2 master mybond0

  # Example Adding a team master and two slave connection profiles
  nmcli con add type team con-name Team1 ifname Team1 config team1-master-json.conf
  nmcli con add type team-slave con-name Team1-slave1 ifname em1 master Team1
  nmcli con add type team-slave con-name Team1-slave1 ifname em2 master Team1
  ```
* 使用nmtui进行集合
---
### 参考信息
* http://www.361way.com/nmcli-bond-teamd/4837.html
* https://access.redhat.com/documentation/zh_cn/red_hat_enterprise_linux/7/html/networking_guide/sec-configure_teamd_runners