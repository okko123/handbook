# OpenLDAP部署记录
* 操作系统: CentOS Linux release 7.6.1810
* OpenLDAP: 2.4.44
---
### RPM文件部署
- 安装
  ```bash
  yum install openldap-servers openldap-clients samba -y

  #Log
  cat >> /etc/rsyslog.conf << EOF
  local4.* /var/log/ldap.log
  EOF

  /etc/init.d/rsyslog restart

  systemctl start slapd
  ```
- OpenLDAP的配置文件生成
  > 需要注意的是：从2.4.23版本开始，OpenLDAP从传统的扁平的配置文件(slapd.conf) 切换到OLC风格的配置文件，并且将是缺省的配置方法。使用OLC风格的配置文件的一大好处是当配置需要被更改时，这一动态的后台配置（cn=config）不需要重启服务就可以生效。老用户可以通过设置了-f和-F参数的命令slaptest将现有配置迁移到新的OLC风格的配置。传统的OLC是以ldif格式（这样可以保证可读性）保存在/etc/openldap/slapd.d 目录中的。用户目前还不一定需要进行这一配置文件的转换，但是未来老的方法将可能不被支持。
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

  #修改slapd的配置(不能动态修改)，修改以下内容。然后重新生成配置
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
### docker方式部署
- 使用docker拉起容器
  ```bash
  mkdir -p /data/slapd/{database, config}

  docker run \
  --name ldap-hn \
  --env LDAP_ORGANISATION="NEW Company" \
  --env LDAP_DOMAIN="example.cn" \
  --env LDAP_ADMIN_PASSWORD="123456" \
  --env LDAP_REPLICATION=false \
  --env LDAP_TLS_VERIFY_CLIENT=never \
  --hostname ldap.example.cn \
  --volume /data/slapd/database:/var/lib/ldap \
  --volume /data/slapd/config:/etc/ldap/slapd.d \
  -p 389:389 \
  -p 636:636 \
  --detach osixia/openldap:1.5.0
  ```
- 进入容器，使用ldif方式修改配置
  1. 添加syncprov、ppolicy模块
     ```bash
     cat > module.ldif <<EOF
     dn:cn=module{0},cn=config
     changetype: modify
     add: olcModuleLoad
     olcModuleLoad: ppolicy

     dn: cn=module{0},cn=config
     changetype: modify
     add: olcModuleLoad
     olcModuleLoad: syncprov
     EOF
     ldapadd -Y EXTERNAL -H ldapi:/// -f module.ldif

     # 检查模块是否被正常导入
     ldapsearch -H ldapi:// -Y EXTERNAL -b "cn=config" -LLL -Q   "objectClass=olcModuleList"
     ```
  2. 导入ppolicy模块定义（schema）
     ```bash
     ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/ppolicy.ldif

     # 检查schema是否成功导入；成功添加后会出现dn: cn={4}ppolicy,cn=schema,cn=config的条目
     ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=schema,cn=config dn
     ```
  3. 加载ppolicy的overlay
     ```bash
     cat > ppolicy_overlay.ldif <<EOF
     dn: olcOverlay=ppolicy,olcDatabase={1}mdb,cn=config
     changetype: add
     objectClass: olcOverlayConfig
     objectClass: olcPPolicyConfig
     olcOverlay: ppolicy
     olcPPolicyDefault: cn=ppolicy,ou=policies,dc=xxx,dc=com
     olcPPolicyHashCleartext: TRUE
     olcPPolicyUseLockout: TRUE
     EOF

     ldapadd -YEXTERNAL -H ldapi:/// -f ./ppolicy_overlay.ldif
     ```
  4. 配置ppolicy的默认规则。例如：密码三个月到期，过期后再使用五次后将自动锁定，必须找管理员解  锁；不能修改最近5次使用过的密码；连续5次输入错误密码，自动锁定账号5分钟
     ```bash
     cat > default_ppolicy.ldif <<EOF
     dn: ou=policies,dc=xxx,dc=com
     objectClass: organizationalUnit
     objectClass: top
     ou: policies

     dn: cn=ppolicy,ou=policies,dc=xxx,dc=com
     cn: ppolicy
     objectClass: pwdPolicy
     objectClass: device
     objectClass: top
     pwdAttribute: userPassword
     pwdMinAge: 0
     pwdMaxAge: 7776000
     pwdInHistory: 5
     pwdCheckQuality: 0
     pwdMinLength: 5
     pwdExpireWarning: 6480000
     pwdGraceAuthNLimit: 5
     pwdLockout: TRUE
     pwdLockoutDuration: 300
     pwdMaxFailure: 5
     pwdFailureCountInterval: 30
     pwdMustChange: FALSE
     pwdAllowUserChange: TRUE
     pwdSafeModify: FALSE
     EOF

     ldapadd -x -D'cn=admin,dc=xxx,dc=com' -W -H ldapi:/// -f default_ppolicy.ldif
     ```