### powerDNS递归器配置
- 版本为：5.3.5
- 实现监听abc.example.com，其余域名交给公网DNS解析
- 修改配置文件，使用RPZ实现功能
- 开启webUI
- 注意:
  1. 当启用了 DNSSEC 校验（默认 dnssec.validation: process 或 validate）且转发的域名（如 example.abc）是私有/内部域名，或者上游权威服务器（192.168.1.1）未配置完整的 DNSSEC 信任链时，PowerDNS Recursor 会因为无法验证上游返回结果的 DNSSEC 签名（验证失败），从而直接拒绝该解析（返回 SERVFAIL 或忽略该响应）。
```bash
# 安装pdns-recursor
apt install pdns-recursor -y

# 修改配置
cat > /etc/powerdns/recursor.conf <<EOF
dnssec:
  # validation: process # default
  validation: off
  trustanchorfile: /usr/share/dns/root.key
recursor:
  hint_file: /usr/share/dns/root.hints
  include_dir: /etc/powerdns/recursor.d
  security_poll_suffix: ''
  # 将example.com 的域名解析转发到其他DNS上
  forward_zones:
    - zone: example.com
      forwarders:
        - 192.168.1.1:53
  rpzs:
  - name: /etc/powerdns/rpz.d/override.rpz
    policyName: "custom-overrides"
incoming:
 # listen:
 # - 127.0.0.1 # default
outgoing:
 # source_address:
 # - 0.0.0.0 # default
webservice:
  webserver: true
  address: 0.0.0.0
  port: 8082
  api_key: "YourSecretApiKey123"
  allow_from:
    - 192.168.0.0/24
EOF

mkdir -p /etc/powerdns/rpz.d

cat > /etc/powerdns/rpz.d/override.rpz <<EOF
$TTL 60
@   IN  SOA local.rpz. hostmaster.local.rpz. 1 3600 1800 604800 86400
@   IN  NS  localhost.

abc.example.com. IN A 172.168.1.21
EOF

# 重启服务
systemctl restart pdns-recursor

# 或者清空全局Packet Cache
rec_control wipe-cache
```