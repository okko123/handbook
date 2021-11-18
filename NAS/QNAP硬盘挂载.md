## QNAP 硬盘挂载

### 操作过程
- 扫描信息数据分区的信息
  - mdadm --examine --scan /dev/sdc3
- 查询软RAID的信息
  - cat /proc/mdstat
- 停止
  - mdadm --manage --stop /dev/md/NAS\:0
- 只要有最少数量的设备可用，就立即运行任何组装的阵列，而不是等到所有预期的设备都出现时。
  - mdadm -A -R /dev/md9 /dev/sdb2
- 挂载软RAID
  - mount /dev/md9 /mnt/
  ---
  - [如何从损坏的RAID系统挂载磁盘？](https://qastack.cn/unix/78804/how-to-mount-a-disk-from-destroyed-raid-system)