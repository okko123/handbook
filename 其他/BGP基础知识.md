### BGP报文交互中的角色
- Speaker
  > 发送BGP报文的设备称为BGP发言者（Speaker），它接收或产生新的报文信息，并发布（Advertise）给其它BGP Speaker。
- Peer
  > 相互交换报文的Speaker之间互称对等体（Peer）。若干相关的对等体可以构成对等体组（Peer Group）。
- BGP的路由器号（Router ID）
  > BGP的Router ID是一个用于标识BGP设备的32位值，通常是IPv4地址的形式，在BGP会话建立时发送的Open报文中携带。对等体之间建立BGP会话时，每个BGP设备都必须有唯一的Router ID，否则对等体之间不能建立BGP连接。

  > BGP的Router ID在BGP网络中必须是唯一的，可以采用手工配置，也可以让设备自动选取。缺省情况下，BGP选择设备上的Loopback接口的IPv4地址作为BGP的Router ID。如果设备上没有配置Loopback接口，系统会选择接口中最大的IPv4地址作为BGP的Router ID。一旦选出Router ID，除非发生接口地址删除等事件，否则即使配置了更大的地址，也保持原来的Router ID。
---
### 路由反射器：
> 为保证IBGP对等体之间的连通性，需要在IBGP对等体之间建立全连接关系。假设在一个AS内部有n台设备，那么建立的IBGP连接数就为n(n-1)/2。当设备数目很多时，设备配置将十分复杂，而且配置后网络资源和CPU资源的消耗都很大。在IBGP对等体间使用路由反射器可以解决以上问题。
- 路由反射器相关角色。在一个AS内部关于路由反射器有以下几种角色：
  - 路由反射器RR（Route Reflector）：允许把从IBGP对等体学到的路由反射到其他IBGP对等体的BGP设备，类似OSPF网络中的DR。
  - 客户机（Client）：与RR形成反射邻居关系的IBGP设备。在AS内部客户机只需要与RR直连。
  - 非客户机（Non-Client）：既不是RR也不是客户机的IBGP设备。在AS内部非客户机与RR之间，以及所有的非客户机之间仍然必须建立全连接关系。
  - 始发者（Originator）：在AS内部始发路由的设备。Originator_ID属性用于防止集群内产生路由环路。
  - 集群（Cluster）：路由反射器及其客户机的集合。Cluster_List属性用于防止集群间产生路由环路。

- 路由反射器原理：
  > 同一集群内的客户机只需要与该集群的RR直接交换路由信息，因此客户机只需要与RR之间建立IBGP连接，不需要与其他客户机建立IBGP连接，从而减少了IBGP连接数量。

  > RR 突破了“从 IBGP 对等体获得的 BGP 路由， BGP 设备只发布给它的 EBGP 对等体。”的限制，并采用独有的 Cluster_List 属性和 Originator_ID 属性防止路由环路。RR 向 IBGP 邻居发布路由规则如下：
    - 从非客户机学到的路由，发布给所有客户机。
    - 从客户机学到的路由，发布给所有非客户机和客户机（发起此路由的客户机除外）。
    - 从EBGP对等体学到的路由，发布给所有的非客户机和客户机。
---
## 参考信息
1. [【网络干货】最全BGP路由协议技术详解](https://zhuanlan.zhihu.com/p/126754314)
2. [BGP基础知识](https://zhuanlan.zhihu.com/p/390098491)