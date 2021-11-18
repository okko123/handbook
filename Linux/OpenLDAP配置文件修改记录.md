## 使用ldif文件初始化OpenLDAP
```bash
# 修改root DN、修改访问规则、修改root DN的密码
cat > new.ldif <<EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=example,dc=cn
-
replace: olcAccess
olcAccess: {0}to attrs=userPassword,shadowLastChange by self write by anonymous auth by dn="cn=admin,dc=example,dc=cn" write by * none
olcAccess: {1}to dn.base="" by * read
olcAccess: {2}to * by self write by dn="cn=admin,dc=example,dc=cn" write by * read
-
replace: olcRootDN
olcRootDN: cn=admin,dc=example,dc=cn

dn: olcDatabase={1}mdb,cn=config
#olcRootDN: cn=admin,dc=example,dc=com
changetype: modify
replace: olcRootPW
olcRootPW: {SSHA}tlPDHrj3KEaHhP9dLrn92/1WA99ljt0y
EOF
sudo ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f new.ldif
```
---
## 修改用户密码
```bash
#更改自己的用户密码；（需要知道自己的旧密码）
ldappasswd -H ldap://server_domain_or_IP -x -D "user_dn" -W -A -S

#使用rootDN修改普通用户密码
ldappasswd -H ldap://server_domain_or_IP -x -D "cn=admin,dc=example,dc=com" -W -S "uid=bob,ou=people,dc=example,dc=com"

#修改rootDN的密码
1.Finding the Current RootDN Information（查找rootDN的信息）
sudo ldapsearch -H ldapi:// -LLL -Q -Y EXTERNAL -b "cn=config" "(olcRootDN=*)" dn olcRootDN olcRootPW | tee ~/newpasswd.ldif
2.
```
---
## 初始化目录
cat > user.ldif <<EOF
dn: dc=example, dc=cn
dc: example
o: My Company
objectclass: organization
objectclass: dcObject

dn: cn=Manager, dc=example, dc=cn
cn: Manager
sn: Manager
objectclass: person
EOF
ldapadd -D "cn=admin, dc=example, dc=cn" -W  -f user.ldif


cat > repl.ldif <<EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcSyncrepl
olcSyncrepl: rid=105
  provider=ldap://ldap2.example.org
  bindmethod=simple
  binddn="cn=admin,dc=example,dc=cn" credentials=51trpdq_emWYsfbu
  searchbase="dc=example,dc=cn"
  schemachecking=on
  type=refreshAndPersist retry="60 +"

dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcUpdateRef
olcUpdateRef: ldap://ldap2.example.org
EOF
ldapadd -Q -Y EXTERNAL -H ldapi:/// -f repl.ldif


## 添加模块
# Load syncprov module
dn: cn=module{0},cn=config
changetype: modify
add: olcModuleLoad
olcModuleLoad: syncprov

# Add syncprov on config
dn: olcOverlay=syncprov,olcDatabase={0}config,cn=config
changetype: add
objectClass: olcOverlayConfig
objectClass: olcSyncProvConfig
olcOverlay: syncprov

# Add syncprov on backend
dn: olcOverlay=syncprov,olcDatabase={1}mdb,cn=config
changetype: add
objectClass: olcOverlayConfig
objectClass: olcSyncProvConfig
olcOverlay: syncprov

# Add sync replication on backend
dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcSyncRepl
olcSyncRepl: rid=103 provider=ldap://10.111.105.101 binddn="cn=admin,dc=example,dc=cn" bindmethod=simple credentials="51trpdq_emWYsfbu" searchbase="dc=example,dc=cn" type=refreshAndPersist interval=00:00:00:10 retry="60 +" timeout=1 starttls=critical
-
add: olcLimits
olcLimits: dn.exact="cn=admin,dc=example,dc=cn" time.soft=unlimited time.hard=unlimited size.soft=unlimited size.hard=unlimited

## 其他功能
- 查看到当前系统中已经加载的模块：
ldapsearch -H ldapi:// -Y EXTERNAL -b "cn=config" -LLL -Q "objectClass=olcModuleList"



---
# 参考信息
- [How To Change Account Passwords on an OpenLDAP Server](https://www.digitalocean.com/community/tutorials/how-to-change-account-passwords-on-an-openldap-server)