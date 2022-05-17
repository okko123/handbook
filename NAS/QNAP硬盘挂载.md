## QNAP 硬盘挂载
### 有RAID1的挂盘操作过程
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
### 无RAID的挂盘操作过程
由于QNAP使用lvm生成卷，因此需要扫描lvm，恢复卷后才能进行挂载
- 扫描信息数据分区的信息
  - mdadm --assemble --scan --run
  - lvmdiskscan；扫描lvm卷
  - lvscan；检查卷是否被激活
  - vgchange -ay /dev/vg01；激活指定vg卷
  - vgscan
  - vgdisplay
  -
---
- [如何从损坏的RAID系统挂载磁盘？](https://qastack.cn/unix/78804/how-to-mount-a-disk-from-destroyed-raid-system)
- [如何挂载另一个lvm硬盘](https://www.cnblogs.com/wuchanming/p/4878116.html)