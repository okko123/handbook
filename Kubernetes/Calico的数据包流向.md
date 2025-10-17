### Docker + Calico 环境下，数据包的流向
- 在 Docker + Calico 环境下，数据包的流向会变得比纯 Docker 环境更复杂，因为 Calico 使用了全新的网络栈（L3路由）而非 Docker 默认的桥接模式。
- veth pair，结合 Docker/Calico 的环境，来看 veth pair 是如何工作的。
  1. 创建桥梁：
     - 当 Docker/Calico 创建一个 Pod/容器时，它会同时创建一个 veth pair。
     - 它将其中一端（例如 veth1）放入容器的网络命名空间，并重命名为大家熟悉的 eth0。这就是容器内部看到的"网卡"。
     - 另一端（例如 veth0）则留在宿主机的根网络命名空间中。在 Calico 中，它的名字通常像 cali12345...（以 Calico 接口的 ID 开头）。
   2. 分配地址：
      - Docker/Calico 会为容器内的 eth0 分配一个 IP 地址（例如 10.244.1.2）。
      - 同时，宿主机端的 cali12345 也会被配置并启用。
   3. 数据流动：
      - 容器访问外部：当容器内的进程想要访问互联网（例如 ping 8.8.8.8），数据包从容器的 eth0 发出。
      - 由于 eth0 是 veth pair 的一端，数据包会立刻出现在宿主机的 cali12345 接口上。
      - 然后，数据包进入宿主机的网络协议栈，根据宿主机的路由表和 iptables 规则进行后续处理（是通过 tunl0 隧道发送到其他节点，还是通过宿主机的物理网卡 eth0 访问互联网）。
   4. 外部访问容器：
      - 当数据包从外部发往容器的 IP (10.244.1.2) 时，它首先到达宿主机的物理网卡。
      - 宿主机内核根据其路由表（"去往 10.244.1.2 的包要从 cali12345 口发出"）将数据包发送到 cali12345。
      - 数据包立刻通过 veth pair 出现在容器内部的 eth0 上，被容器内的应用程序接收。
### 总结
- 在 Docker + Calico 环境中：
  1. 路由主导：数据包路径首先由内核路由表（由 Calico 的 Felix 组件设置）决定。
  2. 策略执行：iptables（特别是 Calico 的自定义链）主要负责安全策略的执行（允许/拒绝），并在 Service 场景下与 kube-proxy 协作完成 DNAT/SNAT。
  3. 关键链：
     - cali-FORWARD：是 Pod 与非本地地址通信的策略核心。
     - cali-PREROUTING / cali-POSTROUTING：处理 NAT 和相关标记。
     - cali-to-endpoint / cali-from-endpoint：执行具体的入站和出站网络策略。
- 通过结合路由和 iptables 规则链，Calico 实现了一个高性能、可扩展且安全的 L3 容器网络。要深入调试：
  - 命令 iptables-save -c（查看规则和计数器）
  - ip route（查看路由表）是必不可少的工具。
---
- veth pair主要特点总结
  1. 成对出现：永远是两个接口一起创建，一起销毁。
  2. 跨命名空间连接：它的核心作用就是连接不同的网络命名空间，最典型的就是容器和宿主机。
  3. 双向通信：就像一根网线，数据可以双向流动。
  4. 纯软件实现：由 Linux 内核模拟，不依赖任何硬件。
  5. 是"通道"而非"交换机"：veth pair 本身只是一个管道，它没有 MAC 地址学习功能，也不进行二层交换。三层路由和策略由宿主机协议栈处理。
### 参考连接
1. [使用iptables规则链分析在docker+calico环境下数据包的流向](https://www.jianshu.com/p/099ecf623eb5)