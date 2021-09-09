# 使用Bind9 部署DNS服务
* 操作系统: CentOS Linux release 7.6.1810
* Bind9: 9.9.4
```bash
yum install bind -y

#修改配置文件，主要的点：listen-on、allow-query、forwarders
cat > /etc/named.conf <<'EOF'
options {
    listen-on port 53 { 192.168.0.1; };
	listen-on-v6 port 53 { none; };
	directory 	"/var/named";
	dump-file 	"/var/named/data/cache_dump.db";
	statistics-file "/var/named/data/named_stats.txt";
	memstatistics-file "/var/named/data/named_mem_stats.txt";
	max-cache-size 512m;
	cleaning-interval 1;    // clean cache every 1 minutes
	max-cache-ttl 30;        // limit cached record to a 60s TTL
	max-ncache-ttl 30;       // limit cache neg. resp. to a 60s TTL
	recursing-file  "/var/named/data/named.recursing";
	secroots-file   "/var/named/data/named.secroots";
	allow-query     { 192.168.0.0/24; };

	recursion yes;

	forwarders {
        168.63.129.16;
    };
	forward	only;
	dnssec-enable yes;
	dnssec-validation yes;

	bindkeys-file "/etc/named.iscdlv.key";

	managed-keys-directory "/var/named/dynamic";

	pid-file "/run/named/named.pid";
	session-keyfile "/run/named/session.key";
};

#使用named -V 是否开启xml的编译参数
statistics-channels {
     inet 127.0.0.1 port 8080 allow { 127.0.0.1; };
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
	type hint;
	file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
EOF
```

* 建立解析域
```bash
#创建解析域的配置
cat >>  /etc/named.rfc1912.zones << 'EOF'
zone "test.com" IN {
        type master;
        file "named.test.com";
        allow-update { none; };
};
EOF

#创建区域文件
cd /var/named
cp named.empty named.test.com
```bash
cat > named.test.com<<EOF
$TTL 86400
@   IN  SOA     dns01.test.com. root.test.com. (
        2011071001  ;Serial
        3600        ;Refresh
        1800        ;Retry
        604800      ;Expire
        86400       ;Minimum TTL
)
@       IN  NS          dns01.test.com.
@       IN  PTR         fedora.local.
dns01           IN  A   192.168.1.160
client          IN  A   192.168.1.136
160     IN  PTR         dns01.test.com.
136     IN  PTR         client.test.com.
EOF
#启动前检查配置项是否正确
named-checkconf
named-checkzone "test.com" /var/named/named.test.com

#启动服务
systemctl start named
```
* 使用动态更新zone
  - 需要在解析域的配置中修改allow-update，将none改为IP地址
  - 在允许IP的机器上执行nsupdate，对zone进行CRUD
  ```bash
  nsupdate
  > server 192.168.0.1
  > update delete oldhost.example.com A
  > update add newhost.example.com 86400 A 172.16.1.1
  > send
  ```
* 遇到问题
  - 在/var/named/data/named.run的日志中出现error (broken trust chain) resolving 'www.baidu.com/A/IN': 1.1.0.1#53。由于开启DNSsec验证导致，在bind9的配置文件中将dnssec-enable、dnssec-validation关闭即可。
---
### 参考连接
  - [nsupdate文档](https://linux.die.net/man/8/nsupdate)
  - [错误记录](https://blog.51cto.com/3108485/1911116)
  - [开启xml端口](https://kb.isc.org/docs/aa-00769)
  - [bind9配置解析](https://xieyugui.wordpress.com/2017/06/11/bind-9-10-%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0/)