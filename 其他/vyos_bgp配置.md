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
### 参考链接
- [VyOS 10 VyOS与cisco路由器建立BGP邻居，并开启BFD6](https://zhuanlan.zhihu.com/p/139295488)