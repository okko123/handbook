vyos
- 安装install image
- 配置网卡信息
# 进入配置模式
vyos@vyos:~$ configure

# 设置网卡描述
vyos@vyos# set interfaces ethernet eth0 description 'PUBLIC NETWORK'
vyos@vyos# set interfaces ethernet eth1 description 'PRIVATE NETWORK'

# 配置ip地址
vyos@vyos# set interfaces ethernet eth0 address 172.16.81.200/24
vyos@vyos# set protocols static route 0.0.0.0/0 next-hop '172.16.81.254'
vyos@vyos# set interfaces ethernet eth1 address 192.168.1.254/24

# 配置内网出公网
vyos@vyos# set nat source rule 100 description 'TO INTERNET'
vyos@vyos# set nat source rule 100 source address 192.168.1.0/24
vyos@vyos# set nat source rule 100 outbound-interface eth0
vyos@vyos# set nat source rule 100 translation address masquerade

# 防火墙
vyos@vyos# set zone-policy zone public interface eth0
vyos@vyos# set zone-policy zone private interface eth1
vyos@vyos# firewall name private-public rule 1 action accept
vyos@vyos# firewall name private-public rule 1 state established enable
vyos@vyos# firewall name private-public rule 1 state related enable

# 保存信息
vyos@vyos# commit
vyos@vyos# save
---
## 参考信息
- [VyOS安装和配置](https://blog.csdn.net/allway2/article/details/106888649)
- [VyOS软路由系统基本设置 ](https://www.cnblogs.com/technology178/p/9486563.html)