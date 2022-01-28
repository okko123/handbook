# 系统参数调整

### sysctl的内核参数调整
```bash
kernel.panic = 5
# tcp backlog队列
net.core.somaxconn = 262144
net.ipv4.tcp_abort_on_overflow = 0
# syn+ack包尝试发送的次数。每次重试等待时间为2的幂次。最后一次为等待时长31秒。最终超时连接需要经历63秒
net.ipv4.tcp_synack_retries = 5
# 初始化tcp连接时，尝试发送syn包的次数。每次重试等待时间为2的幂次。最后一次为等待时长63秒。最终超时连接需要经历127秒
net.ipv4.tcp_syn_retries = 6

# tcp 半队列大小，但需要需要listen backlog、smaxconn、max_syn_backlog同时调整，会影响半队列大小
net.ipv4.tcp_max_syn_backlog = 262144

# tcp ipv4的调整
net.ipv4.tcp_syncookies = 1
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_tw_reuse = 0
net.ipv4.tcp_tw_recycle = 0

# 以下是为未了解的参数
net.ipv4.netfilter.ip_conntrack_max
net.ipv4.tcp_slow_start_after_idle
net.ipv4.route.gc_timeout
net.ipv4.tcp_fastopen
net.ipv4.icmp_ignore_bogus_error_responses
# 网络设备接收数据包的速率比内核处理这些包的速率快时，允许送到队列的数据包的最大数目？
net.core.netdev_max_backlog = 262144
# 最大的TCP 数据接收缓冲（字节）？
net.core.rmem_max = 8388608
# 最大的TCP 数据发送缓冲（字节）？
net.core.wmem_max = 8388608




# 关闭IPv6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1

```

### file-max / file-nr
> cat /proc/sys/fs/file-max；这个文件决定了系统级别所有进程可以打开的文件描述符的数量限制，如果内核中遇到VFS: file-max limit <number> reached的信息，那么就提高这个值。

> cat /proc/sys/fs/file-nr；这个是一个状态指示的文件，一共三个值，第一个代表全局已经分配的文件描述符数量，第二个代表自由的文件描述符（待重新分配的），第三个代表总的文件描述符的数量。
### 桥接参数
- bridge-nf-call-arptables
  - 0: 关闭
  - 1: 将桥接的 ARP 流量传递到 arptables 的 FORWARD 链。
- bridge-nf-call-iptables
  - 0: 关闭
  - 1: 将桥接的 IPv4 流量传递到 iptables 的链。
### arp参数
- arp_ignore: 定义不同的模式来发送回复以响应接收到的解析本地目标 IP 地址的 ARP 请求
  - 0：响应任意网卡上接收到的对本机IP地址的arp请求（包括环回网卡上的地址），而不管该目的IP是否在接收网卡上。
  - 1：只响应目的IP地址为接收网卡上的本地地址的arp请求。
  - 2：只响应目的IP地址为接收网卡上的本地地址的arp请求，并且arp请求的源IP必须和接收网卡同网段。
  - 3：如果ARP请求数据包所请求的IP地址对应的本地地址其作用域（scope）为主机（host），则不回应ARP响应数据包，如果作用域为全局（global）或链路（link），则回应ARP响应数据包。
  - 4~7：保留未使用
  - 8：不回应所有的arp请求
- arp_announce: 作用是控制系统在对外发送arp请求时，如何选择arp请求数据包的源IP地址。（比如系统准备通过网卡发送一个数据包a，这时数据包a的源IP和目的IP一般都是知道的，而根据目的IP查询路由表，发送网卡也是确定的，故源MAC地址也是知道的，这时就差确定目的MAC地址了。而想要获取目的IP对应的目的MAC地址，就需要发送arp请求。arp请求的目的IP自然就是想要获取其MAC地址的IP，而arp请求的源IP是什么呢？ 可能第一反应会以为肯定是数据包a的源IP地址，但是这个也不是一定的，arp请求的源IP是可以选择的，控制这个地址如何选择就是arp_announce的作用）
  - 0: 使用任何本地地址，在任何接口上配置
  - 1: 尽量避免不在目标地址中的本地地址此接口的子网
  - 2: 始终为此目标使用最佳本地地址

## 参考连接
* [内核sysctl手册说明](https://www.kernel.org/doc/Documentation/networking/ip-sysctl.txt)
* [内核参数查询](https://sysctl-explorer.net/)
* [Linux内核参数之arp_ignore和arp_announce](https://www.jianshu.com/p/734640384fda)