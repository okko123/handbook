## OpenLDAP部署记录
* 环境设定，实验的操作系统CentOS Linux release 7.6.1810
* OpenLDAP 2.4.44
---
### 安装步骤
```bash
yum install openldap-server openldap-clients -y
#Log
cat >> /etc/rsyslog.conf << EOF
local4.* /var/log/ldap.log
EOF
/etc/init.d/rsyslog restart

#Add LDAP schema
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/core.ldif
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/openldap.ldif
```
---
## OpenLDAP的配置文件语法变更
- 需要注意的是：从2.4.23版本开始，OpenLDAP从传统的扁平的配置文件(slapd.conf) 切换到OLC风格的配置文件，并且将是缺省的配置方法。使用OLC风格的配置文件的一大好处是当配置需要被更改时，这一动态的后台配置（cn=config）不需要重启服务就可以生效。老用户可以通过设置了-f和-F参数的命令slaptest 将现有配置迁移到新的OLC风格的配置。传统的OLC是以ldif格式（这样可以保证可读性）保存在/etc/openldap/slapd.d 目录中的。用户目前还不一定需要进行这一配置文件的转换，但是未来老的方法将可能不被支持。
- 使用方法
  ```bash
  #验证slapd.conf文件的语法是否存在错误
  slaptest -v -d 1 -f /etc/openldap/slapd.conf

  # 清理/etc/openldap/slapd.d的文件，并生成OLC文件
  test -d /etc/openldap/slapd.d && rm -rf /etc/openldap/slapd.d/* || mkdir /etc/openldap/slapd.d
  slaptest -f /etc/openldap/slapd.conf -F /etc/openldap/slapd.d
  chown -R ldap.ldap /etc/openldap/slapd.d
  ```
---
## slap工具使用
- 备份配置
  ```bash
  slapcat -n 0 -l config.ldif
  ```
- 备份数据
  ```bash
  slapcat -n 1 -l data.ldif
  ```
- 恢复数据

---
## 参考连接
* http://www.bewindoweb.com/223.html
* https://segmentfault.com/a/1190000014683418
* https://github.com/sios-tech/ansible-openldap-rhel7/blob/master/roles/ldap/tasks/main.yml
* https://wiki.gentoo.org/wiki/Centralized_authentication_using_OpenLDAP/zh-cn
