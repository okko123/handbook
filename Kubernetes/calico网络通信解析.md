## Calico 网络通信解析
在 Kubernetes 集群中，Calico 区别于 Flannel 的最显著特征，就是其宣称可以不借助隧道技术，是建立在纯三层协议上的解决方案。也就是说，Calico 通过建立一些路由信息，就构建了单节点/多节点网络命名空间隔离下的通信网络。
- 容器网络与主机网络
  > 容器隔离是建立 Docker 容器的基本要素。其中网络命名空间隔离，从逻辑上将容器和宿主机的网络进行分割。宿主机与容器的网络包互不干扰，互不可达。如果物理主机只有一张网卡eth0(与公网互联)，在未做配置的情况下，网卡留在宿主机网络命名空间下，宿主机可访问公网，而容器的网络包悉数显示为“网络不可达”；而如果物理上是两张网卡 eth0, eth1，分别将两张网卡提供给宿主机和容器，则两者可分别访问公网，互不干扰。此处所描述的物理主机不算是真正物理意义上的主机，而是一个直接运行操作系统的机器。即XEN/KVM虚拟出来的机器也算物理主机(确实不够严谨:)，下同
  ```bash
  +-----------------------+
  | +-------------------+ |
  | |    Host Network   #=[] eth0  <---------+
  | +-------------------+ |                  |
  |                       |                  +----> Internet
  | +-------------------+ |                  |
  | | Container Network #=[] eth1  <---------+
  | +-------------------+ |
  |                       |
  |     Physical Host     |
  +-----------------------+
  ```
  > 在物理主机上安排这么多网卡不太现实，一般性的解决方案都是打通容器与宿主机之间的网络，让宿主机承担路由器的作用，借此实现容器在多节点集群内的通信。Calico 支持下的容器网络，容器会被添加上一个 veth-pair (虚拟以太网设备)。veth-pair 都是成对出现，可以理解成一根逻辑上的网线，一端连接容器，一端与宿主机连通。
  ```bash
  +-----------------------+
  | +-------------------+ |
  | |    Host Network   #=[] eth0  <-------------> Internet
  | +--------[]---------+ |               
  |          || cali.xyz  |
  |          ||           |                 
  |     eth0 ||           |
  | +--------[]---------+ |                 
  | | Container Network | | 
  | +-------------------+ |
  |                       |
  |     Physical Host     |
  +-----------------------+
  ```
  > 宿主机侧的 veth 被命名成了 cali96417d7dcac ，容器侧的 veth 被重命名成 eth0 。容器侧的网络包又将如何发送到宿主机呢？默认路由规则将容器内发起的 IP 数据报导向网关 169.254.1.1 。那么 169.254.1.1 是哪台机器呢？整个 Kubernetes 集群中都是找不到 169.254.1.1 这个 IP 。

  > 事实上，无需关注 IP 169.254.1.1 ，这就是一个莫须有的私网 IP ，仅仅是为了给 eth0 –> cali.xyz 建立路由关系。IP 报文装填上源 IP 地址和目的 IP 地址之后，交由二层协议继续装填上源 MAC 和目的 MAC 。重新整理下目标，网络包需要从容器的 eth0 发送到宿主机的 cali.xyz 。由于三层路由表明下一跳是 169.254.1.1 ，而目标是给二层协议的目的 MAC 装上 cali.xyz 的 MAC 地址。如何实现 IP -> MAC 解析呢？ARP 协议专业做这件事，唯一的问题是 cali.xyz 的 IP 不是 169.254.1.1 ，不过没关系，配置上 proxy_arp 就可以让 cali.xyz 不关心 ARP 请求的 who-is 169.254.1.1，对任何 ARP 请求都直接响应自己的 MAC 地址 ee:ee:ee:ee:ee:ee。至于所有 cali* 网卡的 MAC 地址都是 ee:ee:ee:ee:ee:ee 潜在的冲突问题？其实根本不存在，网络包到达宿主机后，该目的 MAC 地址即被卸下，准备装填一个新的下一跳继续转发。
---
- 网卡配置
  ```bash
  # 宿主机侧网卡 cali.xyz
  $ ip addr
  14: cali96417d7dcac@if4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP
      link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netnsid 2
      inet6 fe80::ecee:eeff:feee:eeee/64 scope link
         valid_lft forever preferred_lft forever

  # 宿主机侧网卡 cali.xyz 配置
  $ cat /proc/sys/net/ipv4/conf/cali96417d7dcac/proxy_arp
  1

  # 容器侧网卡 eth0
  $ ip addr
  eth0@if14: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue
      link/ether 8e:f0:89:10:19:9e brd ff:ff:ff:ff:ff:ff
      inet 172.20.250.3/32 scope global eth0
         valid_lft forever preferred_lft forever

  # 容器侧路由
  $ ip route 
  default via 169.254.1.1 dev eth0
  169.254.1.1 dev eth0 scope link
  ```
- 容器间通信
  > 虽然容器侧发送的网络包已经达到了宿主机，但容器与容器通信尚未完成？继续跟踪达到宿主机的网络包。容器 A 向容器 B 发出的网络包已经到达了宿主机，因为未达到目的地，还需要寻找下一跳。还是走三层路由协议，宿主机侧有关于该物理主机上所有容器的路由信息，其中一条 172.20.251.4 dev calib7124528292 scope link 为这个网络包指明了下一跳的方向，走 calib7124528292 网卡，具体的二层封包 MAC 地址已经被 Calico 永久写了一条邻接条目。
  ```bash
  # 容器 B 侧网卡 eth0
  $ ip addr
  eth0@if15: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue
      link/ether 5e:83:d9:f7:e1:aa brd ff:ff:ff:ff:ff:ff
      inet 172.20.250.4/32 scope global eth0
         valid_lft forever preferred_lft forever

  # 宿主机侧路由信息 & 邻接条目
  $ ip route
  172.20.250.4 dev cali6a4afa28fb1 scope link
  $ ip neigh
  172.20.250.4 dev cali6a4afa28fb1 lladdr 5e:83:d9:f7:e1:aa PERMANENT
  +-----------------------+
  | +-------------------+ |                 
  | | Container Network | | 
  | |       ( B )       | |
  | |    172.20.250.4   | |
  | +--------[]---------+ |
  |     eth0 ||           |
  |          ||           |
  |          || cali.uvw  |
  | +--------[]---------+ |
  | |    Host Network   #=[] eth0  <-------------> Internet
  | +--------[]---------+ |               
  |          || cali.xyz  |
  |          ||           |                 
  |     eth0 ||           |
  | +--------[]---------+ |                 
  | | Container Network | | 
  | |       ( A )       | |
  | |    172.20.250.3   | |
  | +-------------------+ |
  |                       |
  |     Physical Host     |
  +-----------------------+
  ```
- 跨物理主机容器间通信
跨物理主机的容器间通信与同一主机下的容器间通信并不大的区别。需要关注的就是物理主机间关于容器路由记录的同步。Calico 一般是将 Pod CIDR 划分成若干段，每台物理主机持有一个 IP 段。需要跨主机的网络包，根据目的 IP 先被被宿主机侧的路由信息路由到另一个物理主机上的宿主机，然后是宿主机将网络包路由到目的容器。
  ```bash
  172.20.24.0/23 via 172.16.254.113 dev em1 proto bird
  172.20.112.0/23 via 172.16.254.115 dev em1 proto bird
  172.20.148.0/23 via 172.16.254.112 dev em1 proto bird
  ```
    > 我这里为每个物理主机划分了 /23 子网段。虽然目前看到的都是三层路由下的网络通信，但 Calico 也还是支持 IPIP 和 VXLAN 这样的 Overlay 模式的。以后有需要的时候再了解吧
---
-[Calico 网络通信解析](https://www.ffutop.com/posts/2019-12-24-how-calico-works/)