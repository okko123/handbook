## powerdns使用笔记
### 使用docker拉起powerdns-auth
```bash
# 创建数据目录、配置目录
mkdir -p /data/pdns-auth/conf
chown -R 953.953 /data/pdns-auth

# 使用sqlite3作为后端数据库，创建表
cd /data/pdns-auth
sqlite3 pdns.sqlite3
PRAGMA foreign_keys = 1;

CREATE TABLE domains (
  id                    INTEGER PRIMARY KEY,
  name                  VARCHAR(255) NOT NULL COLLATE NOCASE,
  master                VARCHAR(128) DEFAULT NULL,
  last_check            INTEGER DEFAULT NULL,
  type                  VARCHAR(8) NOT NULL,
  notified_serial       INTEGER DEFAULT NULL,
  account               VARCHAR(40) DEFAULT NULL,
  options               VARCHAR(65535) DEFAULT NULL,
  catalog               VARCHAR(255) DEFAULT NULL
);

CREATE UNIQUE INDEX name_index ON domains(name);
CREATE INDEX catalog_idx ON domains(catalog);


CREATE TABLE records (
  id                    INTEGER PRIMARY KEY,
  domain_id             INTEGER DEFAULT NULL,
  name                  VARCHAR(255) DEFAULT NULL,
  type                  VARCHAR(10) DEFAULT NULL,
  content               VARCHAR(65535) DEFAULT NULL,
  ttl                   INTEGER DEFAULT NULL,
  prio                  INTEGER DEFAULT NULL,
  disabled              BOOLEAN DEFAULT 0,
  ordername             VARCHAR(255),
  auth                  BOOL DEFAULT 1,
  FOREIGN KEY(domain_id) REFERENCES domains(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX records_lookup_idx ON records(name, type);
CREATE INDEX records_lookup_id_idx ON records(domain_id, name, type);
CREATE INDEX records_order_idx ON records(domain_id, ordername);


CREATE TABLE supermasters (
  ip                    VARCHAR(64) NOT NULL,
  nameserver            VARCHAR(255) NOT NULL COLLATE NOCASE,
  account               VARCHAR(40) NOT NULL
);

CREATE UNIQUE INDEX ip_nameserver_pk ON supermasters(ip, nameserver);


CREATE TABLE comments (
  id                    INTEGER PRIMARY KEY,
  domain_id             INTEGER NOT NULL,
  name                  VARCHAR(255) NOT NULL,
  type                  VARCHAR(10) NOT NULL,
  modified_at           INT NOT NULL,
  account               VARCHAR(40) DEFAULT NULL,
  comment               VARCHAR(65535) NOT NULL,
  FOREIGN KEY(domain_id) REFERENCES domains(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX comments_idx ON comments(domain_id, name, type);
CREATE INDEX comments_order_idx ON comments (domain_id, modified_at);


CREATE TABLE domainmetadata (
 id                     INTEGER PRIMARY KEY,
 domain_id              INT NOT NULL,
 kind                   VARCHAR(32) COLLATE NOCASE,
 content                TEXT,
 FOREIGN KEY(domain_id) REFERENCES domains(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX domainmetaidindex ON domainmetadata(domain_id);


CREATE TABLE cryptokeys (
 id                     INTEGER PRIMARY KEY,
 domain_id              INT NOT NULL,
 flags                  INT NOT NULL,
 active                 BOOL,
 published              BOOL DEFAULT 1,
 content                TEXT,
 FOREIGN KEY(domain_id) REFERENCES domains(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX domainidindex ON cryptokeys(domain_id);


CREATE TABLE tsigkeys (
 id                     INTEGER PRIMARY KEY,
 name                   VARCHAR(255) COLLATE NOCASE,
 algorithm              VARCHAR(50) COLLATE NOCASE,
 secret                 VARCHAR(255)
);

CREATE UNIQUE INDEX namealgoindex ON tsigkeys(name, algorithm);

# 启动服务
docker run \
--volume /data/pdns-auth:/var/lib/powerdns \
--volume /data/pdns-auth/conf:/etc/powerdns/pdns.d \
--name pdns-auth \
--hostname pdns-auth.example.int \
-p 8082:8082/tcp \
-p 8081:8081/tcp \
-p 53:53/tcp \
-p 53:53/udp \
--detach \
powerdns/pdns-auth-46:4.6.4
```
### 创建zone，创建条目，测试
> pdnsutil create-zone test.com

> 测试域名解析：dig @192.168.0.1 www.test.com

---
- [Generic SQLite 3 backend](https://doc.powerdns.com/authoritative/backends/generic-sqlite3.html)
- [【工具】PowerDNS最新4.6版的安装及使用](https://zhuanlan.zhihu.com/p/467704808)
---
```bash
# 
pdnsutil list-all-zones

pdnsutil create-zone example.org ns1.example.com

pdnsutil create-zone ZONE [nsname] 创建一个空的域
pdnsutil add-record ZONE NAME TYPE [ttl] content  添加解析记录
pdnsutil delete-rrset ZONE NAME TYPE        删除解析记录
pdnsutil replace-rrset ZONE NAME TYPE [ttl] 替换(修改)解析记录
pdnsutil increase-serial example.org 刷新serial号码
pdnsutil show-zone example.org

pdns_control reload

```

使用pdnsutil 添加解析记录，不会更改serial number，导致primary节点不会通知secondary节点更新数据
- auth的配置，secondary服务器地址172.16.81.199
```bash
cat > auth.conf <<EOF
api=yes
api-key=pdns_api_key
webserver=yes
webserver-loglevel=detailed
webserver-address=0.0.0.0
webserver-allow-from=0.0.0.0/0
webserver-port=8081

loglevel=7
log-dns-details=yes
log-dns-queries=yes
log-timestamp=yes

allow-axfr-ips=172.16.81.0/24
allow-dnsupdate-from=172.16.81.0/24

also-notify=172.16.81.199

dnsupdate=yes
forward-dnsupdate=yes

primary=yes
secondary=no

resolver=223.5.5.5
expand-alias=yes
EOF
```

### pdns-recursor递归器配置
- big.wind\int.example.org的域名解析，转发到172.16.81.199的权威服务器上解析
  ```bash
  cat > recursor.conf <<EOF
  api-key=pdns
  api-config-dir=/etc/powerdns/recursor.d

  webserver=yes
  webserver-loglevel=detailed
  webserver-address=0.0.0.0
  webserver-allow-from=172.16.0.0/16
  webserver-port=8082

  loglevel=5
  log-common-errors=yes
  log-rpz-changes=yes

  dnssec=off
  forward-zones=big.wind=172.16.81.199,int.example.org=172.16.81.199

  forward-zones-recurse=baidu.com=223.5.5.5,.=223.6.6.6
  EOF
  ```
- 清理指定域名的缓存
  - rec_control wipe-cache www.example.com
- 清理指定域名下的所有缓存
  - rec_control wipe-cache example.com$
- 导出缓存
  - rec_control dump-cache /tmp/cache