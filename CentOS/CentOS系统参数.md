# CentOS系统参数调整

## sysctl的内核参数调整
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

## file-max / file-nr
cat /proc/sys/fs/file-max；这个文件决定了系统级别所有进程可以打开的文件描述符的数量限制，如果内核中遇到VFS: file-max limit <number> reached的信息，那么就提高这个值。

cat /proc/sys/fs/file-nr；这个是一个状态指示的文件，一共三个值，第一个代表全局已经分配的文件描述符数量，第二个代表自由的文件描述符（待重新分配的），第三个代表总的文件描述符的数量。
## 参考连接
* [内核sysctl手册说明](https://www.kernel.org/doc/Documentation/networking/ip-sysctl.txt)
* [内核参数查询](https://sysctl-explorer.net/)