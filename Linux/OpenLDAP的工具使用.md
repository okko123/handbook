
### ldapmodify、ldapadd工具-用于导入ldif配置
> 导入配置
  ```bash
  #添加 LDAP schema
  ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/core.ldif
  ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
  ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif
  ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
  ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/openldap.ldif
  ```
### ldapsearch工具-用户查询信息
> 查询用户信息
  ```bash
  # 获取用户的dn、memberof信息
  ldapsearch -x -LLL -H ldap:/// -b uid=john,ou=people,dc=example,dc=com dn memberof

  # 获取用户的全部属性
  ldapsearch -x -LLL -H ldap:/// -b uid=john,ou=people,dc=example,dc=com

  # 指定过滤条件：按照dn:cn=admin,dc=example,dc=org进行过滤
  ldapsearch -x -H ldap://192.168.0.1:389 -b cn=admin,dc=example,dc=com -D "cn=admin,dc=example,dc=com" -w admin

  # 指定dn:ou=devlop,dc=example,dc=cn下，返回cn/sn/mail信息
  ldapsearch -x -H ldap://192.168.0.1:389 -D cn=admin,dc=example,dc=com -b "ou=devlop,dc=example,dc=com" -W cn=* cn sn mail

  # 查询指定dn:下，所有ou的信息
  ldapsearch -x -H ldap://192.168.0.1:389 -D cn=admin,dc=example,dc=com -b "dc=example,dc=com" -W  ou=*
  ```
> 查询已加载的模块
  ```bash
  ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=module{0},cn=config
  ```
### ldapwhoami工具
```bash
ldapwhoami -H ldap:// -x -ZZ
```
---
### slap开头的命令是服务端工具
- 备份配置
  ```bash
  slapcat -n 0 -l config.ldif
  ```
- 备份数据
  ```bash
  slapcat -n 1 -l data.ldif
  ```
---
### 主主模式、主从模式
> 当主主节点或主从节点openldap的基础配置一致时，openldap会自动同步数据。例如：清空从节点上的数据，然后从新接入，数据会自动从主节点上同步至从节点
---
### 参考信息
- [配置 OpenLDAP Pasword policy (ppolicy)](https://blog.csdn.net/cuiaamay/article/details/52438777)
- [How to enable MemberOf using OpenLDAP](https://www.adimian.com/blog/2014/10/how-to-enable-memberof-using-openldap/)
- [自助修改ldap密码，Self Service Password](https://ltb-project.org/doku.php)
- [查看用户信息，Service Desk](https://ltb-project.org/doku.php)
- https://wiki.archlinux.org/index.php/OpenLDAP_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)
- http://www.bewindoweb.com/223.html
- https://segmentfault.com/a/1190000014683418
- https://github.com/sios-tech/ansible-openldap-rhel7/blob/master/roles/ldap/tasks/main.yml
- https://wiki.gentoo.org/wiki/Centralized_authentication_using_OpenLDAP/zh-cn
- https://www.openldap.org/doc/admin24/tls.html
- [syncrep的配置参数](http://www.zytrax.com/books/ldap/ch6/#syncrepl)