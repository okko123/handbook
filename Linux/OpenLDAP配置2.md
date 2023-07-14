### 使用LDIF配置主从
```bash
# 导入syncprov、ppolicy模块
ldapmodify -Y EXTERNAL -H ldapi:// <<EOF
dn: cn=module{0},cn=config
changetype: modify
add: olcModuleLoad
olcModuleLoad: syncprov
-
add: olcModuleLoad
olcMoudleLoad: ppolicy
EOF

# 
ldapmodify -Y EXTERNAL -H ldapi:// <<EOF
dn: olcOverlay=syncprov,olcDatabase={1}mdb,cn=config
changetype: add
objectClass: olcOverlayConfig
objectClass: olcSyncProvConfig
olcOverlay: syncprov
olcSpNoPresent: TRUE
olcSpCheckpoint: 100 10
olcSpSessionlog: 100
EOF

ldapmodify -Y EXTERNAL -H ldapi:// <<EOF
dn: olcOverlay=ppolicy,olcDatabase={1}mdb,cn=config
changetype: add
objectClass: olcOverlayConfig
objectClass: olcPPolicyConfig
olcOverlay: ppolicy
olcPPolicyDefault: cn=ppolicy,ou=policies,dc=example,dc=cn
olcPPolicyHashCleartext: TRUE
olcPPolicyUseLockout: TRUE
EOF

# 在目标节点上配置来源节点的信息
ldapmodify -Y EXTERNAL -H ldapi:// <<EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcSyncRepl
olcSyncrepl:
  rid=105
  provider=ldap://ldap01.example.cn
  binddn="cn=admin,dc=example,dc=cn"
  bindmethod=simple
  credentials="123456"
  searchbase="dc=example,dc=cn"
  type=refreshAndPersist
  interval=00:00:00:10
  retry="60 +"
  timeout=1
  starttls=critical
EOF

# 查询CSN时间
ldapsearch -z1 -LLL -x -s base -H ldap://127.0.0.1 -D cn=admin,dc=example,dc=cn -w 123456 -b dc=example,dc=cn contextCSN
```
---
### 添加monitor模块
```bash
ldapmodify -Y EXTERNAL -H ldapi:// <<EOF
dn: cn=module{0},cn=config
changetype: modify
add: olcModuleLoad
olcModuleLoad: {1}back_monitor
EOF

ldapadd -Y EXTERNAL -H ldapi:// <<EOF
dn: cn=monitor,dc=example,dc=cn
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: monitor
description: LDAP monitor
userPassword: {SSHA}ZKQHg79rtsvLdX5i+pJ+zYGmNLypxtUA
EOF

ldapadd -Y EXTERNAL -H ldapi:// <<EOF
dn: olcDatabase={2}monitor,cn=config
objectClass: olcDatabaseConfig
objectClass: olcMonitorConfig
olcDatabase: {2}monitor
olcAccess: {0}to dn.subtree="cn=monitor" by dn.base="cn=monitor,dc=example,dc=cn" read by * none
EOF

ldapmodify -Y EXTERNAL -H ldapi:// <<EOF
dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to *
  by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" read
  by dn.base="cn=manager,dc=company,dc=de" read
  by dn.base="cn=monitor,dc=company,dc=de" read
  by * none
EOF

# 检查
ldapsearch -Q -LLL -H ldapi:/// -Y EXTERNAL -b 'cn=config' '(|(olcDatabase=monitor)(objectClass=olcMonitorConfig))'
ldapsearch -X -H ldapi:/// -D cn=Monitor -W -b cn=monitor
```
---
### 监控字段解析
```bash
# 连接数信息
cn=connection,cn=monitor

# 该子系统包含有关已执行操作的信息。
cn=Operations,cn=Monitor

# 该子系统包含当前服务的统计信息。
cn=Statistics,cn=Monitor

# 它包含启动时启用的最大线程数和当前的后台负载。
cn=Threads,cn=Monitor

# 它包含三个子条目，其中包含服务器的开始时间、当前时间和运行时间。
cn=Time,cn=Monitor

# 当前读/写等待者的数量。
cn=Waiters,cn=Monitor
```
---
### 同步延迟检查脚本
- [1](https://github.com/tart/tart-monitoring/blob/master/check_syncrepl.py#L184)
- [Monitoring OpenLDAP](https://www.ibm.com/docs/en/instana-observability/225?topic=technologies-monitoring-openldap)
- [OpenLDAP replication](https://ubuntu.com/server/docs/service-ldap-replication)
- [OpenLDAP Monitoring](https://www.openldap.org/doc/admin26/monitoringslapd.html)
- [Symas OpenLDAP Knowledge Base](https://kb.symas.com/cnmonitor-reference.html)
---
