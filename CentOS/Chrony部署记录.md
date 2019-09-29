# 使用chrony代替NTPD做时间同步
* 操作系统: CentOS Linux release 7.6.1810
* chrony: 3.2

|IP|角色|
|-|-|
|192.168.1.1|NTPD|
|192.168.1.2|NTPD-Client|

* 服务端
```bash
cat > /etc/chrony.conf <<'EOF'
server 0.cn.pool.ntp.org
server 1.cn.pool.ntp.org
server 2.cn.pool.ntp.org
server 3.cn.pool.ntp.org
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony
allow 192.168.1.0/24
logchange 0.5
bindaddress 192.168.1.1
ratelimit interval 1 burst 16
EOF

##firewall开启端口
firewall-cmd  --add-port=123/udp --permanent
firewall-cmd  --add-port=323/udp --permanent
```

* 客户端
```bash
#手动测试
ntpdata 192.168.1.1

#配置chrony客户端同步时间
cat > /etc/chrony.conf <<'EOF'
server 192.168.1.1
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony
logchange 0.5
bindaddress 192.168.1.2
ratelimit interval 1 burst 16
EOF
```

* 参考资料
  - [官方文档](https://chrony.tuxfamily.org/doc/3.5/chrony.conf.html)