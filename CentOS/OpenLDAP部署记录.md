# OpenLDAP部署记录
* 操作系统: CentOS Linux release 7.6.1810
* OpenLDAP: 2.4.44
---
### 安装步骤
```bash
yum install openldap-servers openldap-clients samba -y

#Log
cat >> /etc/rsyslog.conf << EOF
local4.* /var/log/ldap.log
EOF

/etc/init.d/rsyslog restart

systemctl start slapd
```
---
## OpenLDAP的配置文件生成
- 需要注意的是：从2.4.23版本开始，OpenLDAP从传统的扁平的配置文件(slapd.conf) 切换到OLC风格的配置文件，并且将是缺省的配置方法。使用OLC风格的配置文件的一大好处是当配置需要被更改时，这一动态的后台配置（cn=config）不需要重启服务就可以生效。老用户可以通过设置了-f和-F参数的命令slaptest将现有配置迁移到新的OLC风格的配置。传统的OLC是以ldif格式（这样可以保证可读性）保存在/etc/openldap/slapd.d 目录中的。用户目前还不一定需要进行这一配置文件的转换，但是未来老的方法将可能不被支持。
- 使用slapd.conf文件生成olc配置文件。样例文件[slapd.conf](conf/slapd.conf)
  ```bash
  #验证slapd.conf文件的语法是否存在错误
  slaptest -v -d 1 -f /etc/openldap/slapd.conf

  # 清理/etc/openldap/slapd.d的文件，并生成OLC文件
  test -d /etc/openldap/slapd.d && rm -rf /etc/openldap/slapd.d/* || mkdir /etc/openldap/slapd.d
  slaptest -f /etc/openldap/slapd.conf -F /etc/openldap/slapd.d
  chown -R ldap.ldap /etc/openldap/slapd.d
  systemctl start slapd
  ```
- 使用slapd.ldif文件生成olc配置文件。样例文件[slapd.ldif](conf/slapd.ldif)
  ```bash
  test -d /etc/openldap/slapd.d && rm -rf /etc/openldap/slapd.d/* || mkdir /etc/openldap/slapd.d
  slapadd -d -1 -F /etc/openldap/slapd.d -n 0 -l /etc/openldap/slapd.ldif
  chown -R ldap.ldap /etc/openldap/slapd.d
  systemctl start slapd
  ```
- 配置ldaps
  ```bash
  #创建自签证书
  openssl req -new -x509 -nodes -out slapdcert.pem -keyout slapdkey.pem -days 365
  mv slapdcert.pem /etc/openldap/certs/slapdcert.pem
  mv slapdkey.pem /etc/openldap/certs/slapdkey.pem

  #修改slapd的配置(不能动态修改)，修改以下内容
  olcTLSCertificateFile: /dir/cert.pem
  olcTLSCertificateKeyFile: /dir/key.pem

  #配置客户端不验证证书是否可用
  cat >> /etc/openldap/ldap.conf <<EOF
  TLS_REQCERT allow
  EOF

  #生成密码
  slappasswd -s password
  ```
---
## slap开头的命令是服务端工具
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
## ldap开头的命令是客户端工具
```bash
#Add LDAP schema
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/core.ldif
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/openldap.ldif
```
---
## 参考连接
* https://wiki.archlinux.org/index.php/OpenLDAP_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)
* http://www.bewindoweb.com/223.html
* https://segmentfault.com/a/1190000014683418
* https://github.com/sios-tech/ansible-openldap-rhel7/blob/master/roles/ldap/tasks/main.yml
* https://wiki.gentoo.org/wiki/Centralized_authentication_using_OpenLDAP/zh-cn
* https://www.openldap.org/doc/admin24/tls.html
* [syncrep的配置参数](http://www.zytrax.com/books/ldap/ch6/#syncrepl)