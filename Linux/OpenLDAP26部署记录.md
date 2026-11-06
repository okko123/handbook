## OpenLDAP 2.6 部署
- 系统: ubunt 26.04
- 软件版本: OpenLDAP 2.6.16
- dc使用的域名: example.cn
- Provider的IP地址: 192.168.1.10
- Consumer的IP地址: 192.168.1.20
- 注意事项
  1. OpenLDAP 2.4 升级到 2.6，ldapi:// 的调用命令格式（如 ldapsearch -Y EXTERNAL -H ldapi:///）完全没有变；但 2.6 对 cn=config 的 Schema 校验、数据库模块（必须为 MDB）以及默认 ACL 权限要求更加严苛。这也就是为什么在 2.4 里能正常初始化并用 ldapi:/// 查出的配置，放到 2.6 里如果 LDIF 文件的 dn 命名规范不完全严谨（如未加 {0}、{-1} 等隐式编号前缀或缺失 config 库声明），就会报 No such object (32) 的根本原因
  2. OpenLDAP 2.6：完全删除了 BDB 和 HDB 模块的代码。back_mdb（LMDB 内存映射数据库）成为唯一的标准后端。
     - 通过 ldapi:// 进行管理时：所有动态加载配置必须使用 olcModuleload: back_mdb.la（或内建 back_mdb）。
     - 配置节点统一命名为 olcDatabase={1}mdb,cn=config，如果使用旧的 bdb 模块配置通过 ldapi:// 写入，2.6 会直接抛出非法属性或找不到模块的错误。
### 准备工作，编译安装程序
```bash
# 安装系统包
apt install libltdl-dev gcc make libssl-dev libcrypt-dev libsasl2-dev -y
# 下载源码包
wget https://mirror-hk.koddos.net/OpenLDAP/openldap-release/openldap-2.6.16.tgz
tar xf openldap-2.6.16.tgz
cd openldap-2.6.16
# 编译
./configure \
    --prefix=/usr/local/openldap \
    --sysconfdir=/etc \
    --localstatedir=/var \
    --enable-slapd \
    --enable-crypt \
    --enable-modules \
    --disable-sql \
    --enable-mdb \
    --enable-memberof \
    --enable-refint \
    --enable-ppolicy \
    --enable-syncprov \
    --enable-accesslog \
    --with-tls=openssl \
    --with-cyrus-sasl \
    --with-systemd \
    --with-threads
 make depend
 make
 make install
```
### 创建用户
```bash
useradd -r -M -d /var/lib/ldap -s /sbin/nologin ldap
mkdir -p /var/lib/ldap /etc/openldap/slapd.d /var/run/ldap
chown -R ldap:ldap /var/lib/ldap /etc/openldap/slapd.d /var/run/ldap
```
### 创建密码
```bash
PATH=$PATH:/usr/local/openldap/bin/:/usr/local/openldap/sbin/
slappasswd -h '{SSHA}' -s '123456'

{SSHA}82J4ze/+bPpGkY6LuciNOXUZFbnYzodF
```
### 创建基础配置，进行初始化
```bash
cat > /tmp/base.ldif <<'EOF'
dn: cn=config
objectClass: olcGlobal
cn: config
olcArgsFile: /var/run/ldap/slapd.args
olcPidFile: /var/run/ldap/slapd.pid


dn: cn=module,cn=config
objectClass: olcModuleList
cn: module
olcModulepath:  /usr/local/openldap/libexec/openldap
olcModuleload:  back_mdb.la

dn: cn=schema,cn=config
objectClass: olcSchemaConfig
cn: schema

include: file:///etc/openldap/schema/core.ldif
include: file:///etc/openldap/schema/cosine.ldif
include: file:///etc/openldap/schema/inetorgperson.ldif
include: file:///etc/openldap/schema/nis.ldif

dn: olcDatabase=frontend,cn=config
objectClass: olcDatabaseConfig
objectClass: olcFrontendConfig
olcDatabase: frontend


dn: olcDatabase=mdb,cn=config
objectClass: olcDatabaseConfig
objectClass: olcMdbConfig
olcDatabase: mdb
olcDbMaxSize: 1073741824
olcSuffix: dc=example,dc=cn
olcRootDN: cn=admin,dc=example,dc=cn
olcRootPW: {SSHA}82J4ze/+bPpGkY6LuciNOXUZFbnYzodF
olcDbDirectory: /var/lib/ldap
olcDbIndex: objectClass eq
olcDbIndex: cn,uid eq,sub
olcDbIndex: mail eq
olcDbIndex: entryCSN,entryUUID eq

dn: olcDatabase=monitor,cn=config
objectClass: olcDatabaseConfig
olcDatabase: monitor
olcRootDN: cn=config
olcMonitoring: FALSE
EOF

# 对slapd配置进行初始化
/usr/local/openldap/sbin/slapadd -F /etc/openldap/slapd.d -n 0 -l /tmp/base.ldif

# 初始化创建数据
cat > /tmp/base-init.ldif <<'EOF'
dn: dc=example,dc=cn
objectClass: top
objectClass: dcObject
objectClass: organization
o: Example Org
dc: example

dn: cn=admin,dc=example,dc=cn
objectClass: organizationalRole
cn: admin
description: LDAP administrator
EOF

/usr/local/openldap/sbin/slapadd -F /etc/openldap/slapd.d -n 1 -l /tmp/base-init.ldif

# 添加权限配置
cat > /tmp/fix-config-acl.ldif <<'EOF'
dn: olcDatabase={0}config,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to *
  by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth manage
  by * break
EOF

/usr/local/openldap/sbin/slapmodify -n 0 -F /etc/openldap/slapd.d -w < /tmp/fix-config-acl.ldif

# 检查配置
/usr/local/openldap/sbin/slaptest -u -F /etc/openldap/slapd.d

chown -R ldap:ldap /var/lib/ldap /etc/openldap/slapd.d
```
### 创建systemd配置文件
```bash
cat > /usr/lib/systemd/system/slapd.service <<'EOF'
[Unit]
Description=OpenLDAP Server Daemon
After=syslog.target network-online.target
Documentation=man:slapd
Documentation=man:slapd-config
Documentation=man:slapd-mdb

[Service]
Type=notify
Environment="SLAPD_URLS=ldap:/// ldapi:///" "SLAPD_OPTIONS="
#EnvironmentFile=/etc/sysconfig/slapd
ExecStart=/usr/local/openldap/libexec/slapd -u ldap -g ldap -d 0 -h ${SLAPD_URLS} $SLAPD_OPTIONS

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now slapd
```

### 添加配置
```bash

# 导入
cat > /tmp/memberof.ldif  <<'EOF'
dn: olcOverlay={0}memberof,olcDatabase={1}mdb,cn=config
changetype: add
objectClass: olcOverlayConfig
objectClass: olcMemberOf
olcOverlay: {0}memberof
olcMemberOfDangling: ignore
olcMemberOfRefInt: TRUE
olcMemberOfGroupOC: groupOfUniqueNames
olcMemberOfMemberAD: uniqueMember
olcMemberOfMemberOfAD: memberOf
EOF

ldapadd -YEXTERNAL -H ldapi:/// -f /tmp/memberof.ldif

cat > /tmp/refint.ldif <<'EOF'
dn: olcOverlay={1}refint,olcDatabase={1}mdb,cn=config
changetype: add
objectClass: olcOverlayConfig
objectClass: olcRefintConfig
olcOverlay: {1}refint
olcRefintAttribute: owner
olcRefintAttribute: manager
olcRefintAttribute: uniqueMember
olcRefintAttribute: member
olcRefintAttribute: memberOf
EOF

ldapadd -YEXTERNAL -H ldapi:/// -f /tmp/refint.ldif

cat > /tmp/ppolicy.ldif <<'EOF'
dn: olcOverlay=ppolicy,olcDatabase={1}mdb,cn=config
changetype: add
objectClass: olcOverlayConfig
objectClass: olcPPolicyConfig
olcOverlay: ppolicy
olcPPolicyDefault: cn=ppolicy,ou=policies,dc=example,dc=cn
olcPPolicyHashCleartext: TRUE
olcPPolicyUseLockout: TRUE
EOF

ldapadd -YEXTERNAL -H ldapi:/// -f /tmp/ppolicy.ldif

# 检查
ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b olcDatabase={1}mdb,cn=config
```
### 启用TLS 证书(LDAPS / StartTLS)
- 自签(演示);生产建议用内网 CA，添加域名ldap.example.cn
  ```bash
  mkdir -p /etc/openldap/certs && cd /etc/openldap/certs

  openssl req -newkey rsa:2048 \
  -nodes \
  -keyout ldap.key \
  -x509 \
  -days 3650 \
  -out ldap.crt -subj "/CN=ldap.example.cn"

  chown -R ldap:ldap /etc/openldap/certs
  chmod 600 ldap.key

  # 主从侧的ldap.crt 配置文件都需要同时更新
  ```
- 启用 TLS:
  ```bash
  cat > /tmp/tls.ldif <<'EOF'
  dn: cn=config
  changetype: modify
  add: olcTLSCertificateFile
  olcTLSCertificateFile: /etc/openldap/certs/ldap.crt
  -
  add: olcTLSCertificateKeyFile
  olcTLSCertificateKeyFile: /etc/openldap/certs/ldap.key
  -
  add: olcTLSCACertificateFile
  olcTLSCACertificateFile: /etc/openldap/certs/ldap.crt
  EOF

  # 正常情况下，导入会出现失败，并出现以下报错
  ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/tls.ldif

  SASL/EXTERNAL authentication started
  SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
  SASL SSF: 0
  modifying entry "cn=config"
  ldap_modify: Insufficient access (50)

  # SASL/EXTERNAL 已经认证成功，说明 ldapi:/// 和 root 身份映射没问题；问题出在 cn=config 的 olcAccess 没给这个身份 write/manage 权限，所以改 cn=config 时返回 50。

  # OpenLDAP 2.6 + 编译安装 + 空 slapd.d 初始化 这个组合下，cn=config 数据库默认没有写 ACL。
  # 为什么会出现这种情况
  # OpenLDAP 的 cn=config 数据库本身不会自动给你一套“管理员能改配置”的 ACL。它通常需要显式写入类似：
  ```
- 修复，添加权限
  ```bash
  # 先确认 cn=config 的 ACL。返回下面的结果，说明没有配置
  ldapsearch -Y EXTERNAL -H ldapi:/// -b "olcDatabase={0}config,cn=config" olcAccess

  SASL/EXTERNAL authentication started
  SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
  SASL SSF: 0
  # extended LDIF
  #
  # LDAPv3
  # base <olcDatabase={0}config,cn=config> with scope subtree
  # filter: (objectclass=*)
  # requesting: olcAccess
  #

  # search result
  search: 2
  result: 32 No such object

  # numResponses: 1

  ### 开始修复 ACL 权限
  systemctl stop slapd

  cat > /tmp/fix-config-acl.ldif <<'EOF'
  dn: olcDatabase={0}config,cn=config
  changetype: modify
  replace: olcAccess
  olcAccess: {0}to *
    by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth manage
    by * break
  EOF

  /usr/local/openldap/sbin/slapmodify -n 0 -F /etc/openldap/slapd.d -w < /tmp/fix-config-acl.ldif
  /usr/local/openldap/sbin/slaptest -u -F /etc/openldap/slapd.d

  chown -R ldap:ldap /etc/openldap/slapd.d/

  systemctl start slapd

  # 重新查询 cn=config 的 ACL
  ldapsearch -Y EXTERNAL -H ldapi:/// -b "olcDatabase={0}config,cn=config" olcAccess

  SASL/EXTERNAL authentication started
  SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
  SASL SSF: 0
  # extended LDIF
  #
  # LDAPv3
  # base <olcDatabase={0}config,cn=config> with scope subtree
  # filter: (objectclass=*)
  # requesting: olcAccess
  #

  # {0}config, config
  dn: olcDatabase={0}config,cn=config
  olcAccess: {0}to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external
   ,cn=auth manage by * break

  # search result
  search: 2
  result: 0 Success

  # numResponses: 2
  # numEntries: 1
  ```
- 重新导入tls.ldif文件
  ```bash
  # 导入成功后，会出现如下信息
  ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/tls.ldif

  SASL/EXTERNAL authentication started
  SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
  SASL SSF: 0
  modifying entry "cn=config"
  ```
- 修改systemd配置文件，启用ldaps
  ```bash
  cat > /usr/lib/systemd/system/slapd.service <<'EOF'
  [Unit]
  Description=OpenLDAP Server Daemon
  After=syslog.target network-online.target
  Documentation=man:slapd
  Documentation=man:slapd-config
  Documentation=man:slapd-mdb
  
  [Service]
  Type=notify
  Environment="SLAPD_URLS=ldap:/// ldapi:/// ldaps:///" "SLAPD_OPTIONS="
  #EnvironmentFile=/etc/sysconfig/slapd
  ExecStart=/usr/local/openldap/libexec/slapd -u ldap -g ldap -d 0 -h ${SLAPD_URLS} $SLAPD_OPTIONS
  
  [Install]
  WantedBy=multi-user.target
  EOF
  
  systemctl daemon-reload
  systemctl restart slapd
  
  systemctl status slapd
  ● slapd.service - OpenLDAP Server Daemon
       Loaded: loaded (/usr/lib/systemd/system/slapd.service; disabled; preset: enabled)
       Active: active (running) since Mon 2026-11-02 06:51:12 UTC; 2h 14min ago
   Invocation: 72923e0724e74ecb89641f5a1e401e20
         Docs: man:slapd
               man:slapd-config
               man:slapd-mdb
     Main PID: 92103 (slapd)
        Tasks: 2 (limit: 1919)
       Memory: 3.6M (peak: 4.2M)
          CPU: 13ms
       CGroup: /system.slice/slapd.service
               └─92103 /usr/local/openldap/libexec/slapd -u ldap -g ldap -d 0 -h "ldap:/// ldapi:/// ldaps:///"
  
  Nov 02 06:51:12 ldap slapd[92103]: @(#) $OpenLDAP: slapd 2.6.16 (Nov  2 2026 06:06:34) $
                                             root@ldap:/home/nuc/openldap-2.6.16/servers/slapd
  Nov 02 06:51:12 ldap slapd[92103]: slapd starting
  
  # 检查636端口是否开放
  ss -nltp|grep slapd
  LISTEN 0      2048         0.0.0.0:389       0.0.0.0:*    users:(("slapd",pid=92103,fd=7))
  LISTEN 0      2048         0.0.0.0:636       0.0.0.0:*    users:(("slapd",pid=92103,fd=10))
  LISTEN 0      2048            [::]:389          [::]:*    users:(("slapd",pid=92103,fd=8))
  LISTEN 0      2048            [::]:636          [::]:*    users:(("slapd",pid=92103,fd=11))
  ```
### 主从复制(delta-syncrepl 增量同步)
#### Provider 侧配置
1. 开启 accesslog 增量日志
   ```bash
   # 创建access log 目录
   mkdir -p /var/lib/ldap/accesslog
   chown -R ldap:ldap /var/lib/ldap/accesslog

   cat > /tmp/accesslog.ldif <<'EOF'
   # 建 accesslog 库(记录变更,供增量同步;编号 {2})
   dn: olcDatabase={2}mdb,cn=config
   changetype: add
   objectClass: olcDatabaseConfig
   objectClass: olcMdbConfig
   olcDatabase: {2}mdb
   olcDbDirectory: /var/lib/ldap/accesslog
   olcSuffix: cn=accesslog
   olcRootDN: cn=admin,cn=accesslog
   olcDbIndex: entryCSN,entryUUID eq
   olcDbMaxSize: 1073741824
  
   # 主库 overlay syncprov(静态编译,无需 olcModuleLoad)
   dn: olcOverlay=syncprov,olcDatabase={1}mdb,cn=config
   changetype: add
   objectClass: olcOverlayConfig
   objectClass: olcSyncProvConfig
   olcOverlay: syncprov
   olcSpCheckpoint: 100 10
   olcSpSessionlog: 100
  
   # accesslog 库的 syncprov
   dn: olcOverlay=syncprov,olcDatabase={2}mdb,cn=config
   changetype: add
   objectClass: olcOverlayConfig
   objectClass: olcSyncProvConfig
   olcOverlay: syncprov
   olcSpNoPresent: TRUE
   olcSpReloadHint: TRUE
  
   # accesslog 库的 accesslog overlay(记录变更日志)
   dn: olcOverlay=accesslog,olcDatabase={1}mdb,cn=config
   changetype: add
   objectClass: olcOverlayConfig
   objectClass: olcAccessLogConfig
   olcOverlay: accesslog
   olcAccessLogDB: cn=accesslog
   olcAccessLogOps: writes
   olcAccessLogSuccess: TRUE
   olcAccessLogPurge: 07+00:00 01+00:00
   EOF
  
   # 成功后，显示如下内容
   /usr/local/openldap/bin/ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/accesslog.ldif
  
   SASL/EXTERNAL authentication started
   SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
   SASL SSF: 0
   adding new entry "olcDatabase={2}mdb,cn=config"
  
   adding new entry "olcOverlay=syncprov,olcDatabase={1}mdb,cn=config"
  
   adding new entry "olcOverlay=syncprov,olcDatabase={2}mdb,cn=config"
  
   adding new entry "olcOverlay=accesslog,olcDatabase={1}mdb,cn=config"
   ```
2. 修改配置
   ```bash
   vim /etc/openldap/ldap.conf

   # 添加内容，指定自签证书的路径
   TLS_CACERT /etc/openldap/certs/ldap.crt
   TLS_REQCERT demand
   ```
3. 创建同步专用账号
   ```bash
   # 创建密码，密码为123456
   /usr/local/openldap/sbin/slappasswd -s 123456
   {SSHA}Ox3LbbNbJChPk8c3oNlVF9xWXbUwHaZh

   cat > /tmp/syncuser.ldif <<'EOF'
   dn: cn=syncuser,dc=example,dc=cn
   objectClass: simpleSecurityObject
   objectClass: organizationalRole
   cn: syncuser
   userPassword: {SSHA}Ox3LbbNbJChPk8c3oNlVF9xWXbUwHaZh
   description: LDAP replication account
   EOF

   # 导入账号
   /usr/local/openldap/bin/ldapadd -x -H ldaps://ldap.example.cn -D "cn=admin,dc=example,dc=cn" -W -f /tmp/syncuser.ldif
   ```
#### Consumer 侧配置
1. 增量拉取
   ```bash
   cat > /tmp/syncrepl.ldif <<'EOF'
   dn: olcDatabase={1}mdb,cn=config
   changetype: modify
   add: olcSyncrepl
   olcSyncrepl: rid=001
     provider=ldaps://ldap.example.cn:636
     bindmethod=simple
     binddn="cn=syncuser,dc=example,dc=cn"
     credentials="123456"          # ⚠️ 必须写【明文密码】,不是 {SSHA} hash!
     searchbase="dc=example,dc=cn"
     type=refreshAndPersist
     interval=00:00:01:00
     retry="60 +"
     logbase="cn=accesslog"
     logfilter="(&(objectClass=auditWriteObject)(reqResult=0))"
     syncdata=accesslog
     tls_cacert=/etc/openldap/certs/ldap.crt
   EOF

   /usr/local/openldap/bin/ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/syncrepl.ldif
   ```
2. 修改配置
   ```bash
   vim /etc/openldap/ldap.conf

   # 添加内容，指定自签证书的路径
   TLS_CACERT /etc/openldap/certs/ldap.crt
   TLS_REQCER
   ```