## python ldap插件使用笔记
- ldap 包括一系列的执行命令，包括增、删、改、查等基本操作。在这些操作中又有“同步/异步”和“基本/扩展”的区别。下面的接口是一组添加的接口：
  ```bash
  LDAPObject.add(dn, modlist) → int
  LDAPObject.add_s(dn, modlist) → None
  LDAPObject.add_ext(dn, modlist[, serverctrls=None[, clientctrls=None]]) → int
  LDAPObject.add_ext_s(dn, modlist[, serverctrls=None[, clientctrls=None]]) → None
  ```
- 在这组接口中 add 与 add_ext 是异步接口，带 s 后缀的是同步接口，调用后会返回调用的msgid。由于 OpenLdap 会开启多个进程所以添加多个节点时使用异步调用会大大提高性能。但是需要注意的是调用结果需要通过 result 接口来返回结果，如果不执行 result 就结束可能会有意想不到的结果。
### 初始化
- ldap.initialize
  ```python
  import ldap
  l = ldap.initialize("ldap://ldap.abc.com")
  l.set_option()
  
  ```
### 搜索
search_s
### 添加
add_s
### 修改
modify_s
MOD_ADD
MOD_DELETE
MOD_REPLACE
### 删除
delete_s



olcAccess: {0}to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth manage by * break
olcAccess: {1}to attrs=userPassword,shadowLastChange by self write by dn="cn=admin,dc=abc,dc=com" write by anonymous auth by * none
olcAccess: {2}to * by self read by dn="cn=admin,dc=abc,dc=com" write by * none
olcAccess: {3}to * by self write by * read
