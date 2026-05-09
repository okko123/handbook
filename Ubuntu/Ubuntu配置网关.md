## ubuntu 24.04 配置为网关
1. 修改sysctl配置
```bash
cat > /etc/sysctl.d/90-custom.conf <<EOF
net.ipv4.ip_forward = 1
EOF
```
2. 配置iptables
```bash
apt install -y iptables-persistent

# 1. 在WAN口上开启IP伪装（MASQUERADE），这是NAT的核心规则
iptables -t nat -A POSTROUTING -o enp1s0 -j MASQUERADE

# 2. 允许内网到外网的流量转发
iptables -A FORWARD -i enp2s0 -o enp1s0 -j ACCEPT

# 3. 允许外网已建立的连接数据返回内网
iptables -A FORWARD -i enp1s0 -o enp2s0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# 4, 之后如果修改了规则，可以手动保存
netfilter-persistent save

# 重启系统
reboot
```