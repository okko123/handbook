# 查看/dev/sda1磁盘的UUID
blkid /dev/sda1
# 查看所有磁盘的UUID
blkid -o list
# dmicecode工具使用
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
## CentOS7 做链路聚合，依然能使用bond，默认情况下NetworkManager程序中集成了teamd功能就来配置链路聚合。
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
### 参考信息
* http://www.361way.com/nmcli-bond-teamd/4837.html
* https://access.redhat.com/documentation/zh_cn/red_hat_enterprise_linux/7/html/networking_guide/sec-configure_teamd_runners