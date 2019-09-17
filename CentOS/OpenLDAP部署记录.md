## OpenLDAP部署记录
* 环境设定，实验的操作系统CentOS Linux release 7.6.1810
* OpenLDAP 2.4.44
### 安装步骤
```bash
yum install openldap-server openldap-clients -y

#Add LDAP schema
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/core.ldif
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/openldap.ldif
```

---
## 参考连接
* http://www.bewindoweb.com/223.html
* https://segmentfault.com/a/1190000014683418
* https://github.com/sios-tech/ansible-openldap-rhel7/blob/master/roles/ldap/tasks/main.yml
* https://wiki.gentoo.org/wiki/Centralized_authentication_using_OpenLDAP/zh-cn
