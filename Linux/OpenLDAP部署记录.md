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
     dn: cn=module{0},cn=config
     changetype: modify
     add: olcModuleLoad
     olcModuleLoad: syncprov

     dn:cn=module{0},cn=config
     changetype: modify
     add: olcModuleLoad
     olcModuleLoad: ppolicy

     dn: cn=module{0},cn=config
     changetype: modify
     add: olcModuleLoad
     olcModuleLoad: back_monitor
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
---
> /etc/ldap/slapd.d/cn=config目录下，包含以下三个数据库：
  1. dn: olcDatabase={-1}frontend,cn=config
  2. dn: olcDatabase={0}config,cn=config
  3. dn: olcDatabase={1}mdb,cn=config
> olcDatabase: [{\<index\>}]\<type\>

> 数据库条目必须具备olcDatabaseConfig对象类

> frontend用于保存应用于所有其他数据库的数据库级别选项。后续的数据库定义也可能覆盖某些frontend设置。config和 frontend数据库总是隐式创建的,它们是在任何其他数据库之前创建的。

- olcDatabase={0}config.ldif中包含如下信息说明为SASL机制授权(集成身份认证)
  ```bash
  cat olcDatabase\=\{0\}config.ldif

  其中包含如下信息：
  olcAccess: {0}to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external, cn=auth manage   by * break
  ```
- olcDatabase={1}mdb.ldif中包含如下信息说明为简单授权（账号密码登录）
  ```bash
  cat olcDatabase\=\{1\}mdb.ldif

  其中包含如下信息：
  olcRootDN: cn=admin, dc=example, dc=cn
  olcRootPW: lkajsdiji3j4tlkfdkgj
  ```
- 访问控制
  ```bash
  LDAP中的控制访问，是通过对数据库添加 olcAccess 指令来实现的。该指令的范式为：

  olcAccess: to <what> [ by <who> [<access>] [<control>] ]+
  正如前面所说，该指令定义了什么资源（what）可以由何人（who），执行什么（access）。因此再对照前面的配置，就明白下面这行配置的含义了：

  olcAccess: to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage by * none

  这个配置的意思是：对于当前数据库范围的所有资源，允许 root 进行管理，其他人不赋予任何权限。同时， olcRootDN 所指定的ID名称，不受访问控制的约束。
  ```

  > 默认的访问控制策略是允许所有客户端读取。无论定义了什么访问控制策略，rootdn总是被允许对所有内容拥有完全权限（即身份验证、搜索、比较、读取和写入）。因此，在子句中显式列出rootdn是无用的。

  > 配置访问控制通过olcAccess实现
    ```bash
    olcAccess: {0}to attrs=userPassword by self write by anonymous auth by * none
    olcAccess: {1}to attrs=shadowLastChange by self write by * read
    olcAccess: {2}to * by * read

    olcAccess: to <what> [by <who> [<access>] [<control>] ]+
    <what>选择访问所应用的条目和/或属性，
    <who>指定授予哪些实体访问权限
    <access>指定授权的访问权限
    ```

> what的指定方式
```bash
<waht> ::= * |
  [dn[.<basic-style>]=<regex> | dn.<scope-style>=<DN>]
  [filter=<ldapfilter>] [attrs=<attrlist>]

按DN选择条目:
to * : 全部条目
to dn[.<basic-style>]=<regex> : 正则表达式匹配的条目
to dn.<scope-styple>=<DN> : dn请求范围内的条目
  其中，<scope-style>可以是base，one，subtree or children
    其中，base只匹配具有所提供的DN条目。（精确匹配，只匹配DN）
          one匹配其父项所提供的DN条目。（dn的下一级）
          subtree匹配子树中根为所提供的DN所有条目。（根为DN的所有条目，包括DN）
          children匹配DN下的所有条目（但不匹配由DN命名的条目）。（根为DN的所有条目，不包括DN）
```

### who的指定方式

|用户|描述|
|---|---|
|\*|所有对象，包括匿名和授权用户|
|anonymous|匿名未授权用户|
|users|授权用户|
|self|与目标条目直接关联的用户，比如用户条目自己|
|dn[.<basic-style>]=regex|符合正则匹配的用户|
|dn.<scope-style>=<DN>|DN所指定范围内的用户|
### access的指定方式：每个级别都意味着所有较低级别的访问。

|级别|权限|描述|
|---|---|---|
|none|=0|没有权限|
|disclose|=d|需要错误信息披露|
|auth|=dx|需要进行授权(bind)的操作|
|compare|=cdx|进行比较|
|search|=scdx|进行搜索过滤|
|read|=rscdx|进行读取搜索结果|
|write|=wrcdx|进行修改或重命名|
|manage|=mrscdx|进行管理|
> 从上面的表格可以看出，权限是向下兼容的，即如果给用户指定了 write 的权限，那么他同时会拥有 read 、 search 、 compare 、 auth 以及 disclose 的权限。

- [Linux 安装并配置 OpenLDAP 新编（5）访问控制](https://blog.csdn.net/yyp1998/article/details/133160723)