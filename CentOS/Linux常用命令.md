# 查看/dev/sda1磁盘的UUID
blkid /dev/sda1
# 查看所有磁盘的UUID
blkid -o list


CentOS7 做链路聚合，依然能使用bond，默认情况下NetworkManager程序中集成了teamd功能就来配置链路聚合。
http://www.361way.com/nmcli-bond-teamd/4837.html
