vyos
- 安装install image
- 配置网卡信息

> 进入配置模式
```bash
vyos@vyos:~$ configure
```
> 设置网卡描述
```bash
vyos@vyos# set interfaces ethernet eth0 description 'PUBLIC NETWORK'
vyos@vyos# set interfaces ethernet eth1 description 'PRIVATE NETWORK'
```
> 配置ip地址
```bash
vyos@vyos# set interfaces ethernet eth0 address 172.16.81.200/24
vyos@vyos# set protocols static route 0.0.0.0/0 next-hop '172.16.81.254'
vyos@vyos# set interfaces ethernet eth1 address 192.168.1.254/24
```
> 配置内网出公网
```bash
vyos@vyos# set nat source rule 100 description 'TO INTERNET'
vyos@vyos# set nat source rule 100 source address 192.168.1.0/24
vyos@vyos# set nat source rule 100 outbound-interface eth0
vyos@vyos# set nat source rule 100 translation address masquerade
```
> 防火墙
```bash
vyos@vyos# set zone-policy zone public interface eth0
vyos@vyos# set zone-policy zone private interface eth1
vyos@vyos# firewall name private-public rule 1 action accept
vyos@vyos# firewall name private-public rule 1 state established enable
vyos@vyos# firewall name private-public rule 1 state related enable
```
# 保存信息
vyos@vyos# commit
vyos@vyos# save
---
# bgp配置
- vyos版本: 1.3.0-rc6
- 网络机构图
  ![](img/BGP_01.png)
- R1: ip网段，AS-NUMBER
  - eth0: 192.168.202.1/24
  - eth1: 192.168.10.254/24
  - AS: 65537
- R2: ip网段，AS-NUMBER
  - eth0: 192.168.202.2/24
  - eth1: 192.168.20.254/24
  - AS: 65547
- R1路由配置
  ```bash
  configure
  set system host-name 'R1'
  set interfaces ethernet eth0 address '192.168.202.1/24'
  set interfaces ethernet eth1 address '192.168.10.254/24'

  set protocols bgp 65537 address-family ipv4-unicast network '192.168.10.0/24'
  set protocols bgp 65537 neighbor 192.168.202.2 remote-as '65547'
  set protocols bgp 65537 parameters router-id '192.168.202.1'
  ```
- R2路由配置
  ```bash
  set system host-name 'R2'
  set interfaces ethernet eth0 address '192.168.202.2/24'
  set interfaces ethernet eth1 address '192.168.20.254/24'

  set protocols bgp 65537 address-family ipv4-unicast network '192.168.20.0/24'
  set protocols bgp 65537 neighbor 192.168.202.1 remote-as '65537'
  set protocols bgp 65537 parameters router-id '192.168.202.2'
  ```
- 检查
  ```bash
  show ip bgp summary
  show ip route
  show ip bgp
  ```
---
## 参考信息
- [VyOS 10 VyOS与cisco路由器建立BGP邻居，并开启BFD6](https://zhuanlan.zhihu.com/p/139295488)
- [VyOS安装和配置](https://blog.csdn.net/allway2/article/details/106888649)
- [VyOS软路由系统基本设置 ](https://www.cnblogs.com/technology178/p/9486563.html)