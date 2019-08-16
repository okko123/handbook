# 使用Bind9 建立DNS服务
* 环境设定，实验的操作系统CentOS Linux release 7.6.1810
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

  * 参考连接
    - [nsupdate文档](https://linux.die.net/man/8/nsupdate)
	- [错误记录](https://blog.51cto.com/3108485/1911116)