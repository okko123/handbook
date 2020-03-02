# CentOS系统参数调整

## sysctl的内核参数调整
```bash
# tcp backlog队列
kernel.panic = 5

# tcp ipv4的调整
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_tw_reuse = 0

net.core.netdev_max_backlog = 262144
net.core.rmem_max = 8388608
net.core.wmem_max = 8388608


net.core.somaxconn = 262144

# 关闭IPv6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1

```
