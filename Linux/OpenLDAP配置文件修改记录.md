<!-- TOC -->
- [使用ldif文件初始化OpenLDAP](#使用ldif文件初始化OpenLDAP)
- [修改用户密码](#修改用户密码)
<!-- /TOC -->
### 使用ldif文件初始化OpenLDAP
---
- 修改root DN、修改访问规则、修改root DN的密码
  ```bash
  cat > init.ldif <<EOF
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
  -
  replace: olcRootPW
  olcRootPW: {SSHA}tlPDHrj3KEaHhP9dLrn92/1WA99ljt0y
  EOF

  ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f init.ldif
  ```
---
- 初始化目录
  ```bash
  cat > user.ldif <<EOF
  dn: dc=example, dc=cn
  dc: example
  o: My Company
  objectclass: organization
  objectclass: dcObject
  
  dn: cn=admin, dc=example, dc=cn
  cn: Manager
  sn: Manager
  objectclass: person
  EOF

  ldapadd -D "cn=admin, dc=example, dc=cn" -W  -f user.ldif
  ```
---
- 添加模块；syncprov/ppolicy/memberof/refint
  ```bash
  cat > module.ldif <<EOF
  dn: cn=module{0},cn=config
  changetype: modify
  add: olcModuleLoad
  olcModuleLoad: syncprov
  -
  add: olcModuleLoad
  olcModuleLoad: ppolicy
  -
  add: olcModuleLoad
  olcModuleLoad: memberof
  -
  add: olcModuleLoad
  olcModuleLoad: refint
  EOF

  ldapadd -Y EXTERNAL -H ldapi:/// -f module.ldif

  # 查看到当前系统中已经加载的模块：
  ldapsearch -H ldapi:// -Y EXTERNAL -b "cn=config" -LLL -Q "objectClass=olcModuleList"
  ```
---
- 修改访问规则
  - olcAccess的语法规则
    > olcAccess: to \<what\> \[ by \<who\> \[\<accesslevel\>\] \[\<control\>\] \]+

      > 允许 what 被 who 访问，分配 accesslevel 级别的权限。

      > 如果不配置 olcAccess ，则默认为 * by * read 。

      > 如果用户访问一个对象时没有读取权限，会报错该对象不存在。
      
      > 在存在多个 olcAccess 规则时，最先匹配的那个会生效。如下，匿名用户会应用第二个 by 规则。
    ```olc
    olcAccess: {0}to *
                        by self write
                        by anonymous auth
                        by * read

    what 的取值示例：
    *           # 所有条目或属性
    dn=<regex>  # 与正则表达式匹配的条目或属性

    who 的取值示例：
    *           # 所有用户，包括匿名用户
    anonymous   # 匿名用户
    users       # 通过身份认证的用户
    self        # 目标条目自身的用户
    dn=<regex>  # 与正则表达式匹配的用户
    ```
    ```bash
    # 查询访问规则
    ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b olcDatabase={1}mdb,cn=config olcAccess

    ## 删除olcAccess{3}规则
    cat > del_olc.ldif <<EOF
    dn: olcDatabase={1}mdb,cn=config
    changetype: modify
    delete: olcAccess
    olcAccess: {3}
    EOF

    ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f del_olc.ldif

    # 删除所有访问规则
    cat > del_access.ldif <<EOF
    dn: olcDatabase={1}mdb,cn=config
    changetype: modify
    delete: olcAccess
    EOF

    ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f del_access.ldif

    # 添加访问规则
    ## 第一条规则：所有属性允许自己修改，被所有用户读取
    ## 第二条规则：所有属性允许自己修改，被所有用户读取，允许匿名用户认证
    cat > add_access.ldif <<EOF
    dn: olcDatabase={1}mdb,cn=config
    changetype: modify
    add: olcAccess
    olcAccess: to * by self write by * read
    olcAccess: to * by self write by anonymous auth by * read
    EOF

    ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f add_access.ldif
    ```
---
- 配置 OpenLDAP Pasword policy
  ```bash
  # 检查ppolicy的schema是否已经加载
  # openldap 2.5以后，ppolicy.schema被移除了
  > root@d0d4490a27c6:/# ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=schema,cn=config dn
  > dn: cn=schema,cn=config
  > dn: cn={0}core,cn=schema,cn=config
  > dn: cn={1}cosine,cn=schema,cn=config
  > dn: cn={2}nis,cn=schema,cn=config
  > dn: cn={3}inetorgperson,cn=schema,cn=config
  > dn: cn={4}ppolicy,cn=schema,cn=config
  > dn: cn={5}kopano,cn=schema,cn=config
  > dn: cn={6}openssh-lpk,cn=schema,cn=config
  > dn: cn={7}postfix-book,cn=schema,cn=config
  > dn: cn={8}samba,cn=schema,cn=config

  # 检查ppolicy的模块是否已经加载
  > root@d0d4490a27c6:/# ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=module{0},cn=config
  > dn: cn=module{0},cn=config
  > objectClass: olcModuleList
  > cn: module{0}
  > olcModulePath: /usr/lib/ldap
  > olcModuleLoad: {0}back_mdb
  > olcModuleLoad: {1}memberof
  > olcModuleLoad: {2}refint
  > olcModuleLoad: {3}ppolicy

  # 配置ppolicy的overlay。如果overlay已存在，就不需要再导入。在没有导入对应的模块，导入overlay会出现报错
  > root@d0d4490a27c6:/# ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b olcDatabase={1}mdb,cn=config dn
  > dn: olcDatabase={1}mdb,cn=config
  > dn: olcOverlay={0}memberof,olcDatabase={1}mdb,cn=config
  > dn: olcOverlay={1}refint,olcDatabase={1}mdb,cn=config
  > dn: olcOverlay={2}ppolicy,olcDatabase={1}mdb,cn=config

  # 部分配置说明：
  # UseLockout：超过最多失败次数后，锁定账号时的提示
  # HashCleartest：密码明文在保存的数据库中必须进行hash加密
  # olcPPolicyDefault：定义PPolicy规则保存的路径
  cat > ppolicy_overlay.ldif <<EOF
  dn: olcOverlay=ppolicy,olcDatabase={1}mdb,cn=config
  changetype: add
  objectClass: olcOverlayConfig
  objectClass: olcPPolicyConfig
  olcOverlay: ppolicy
  olcPPolicyDefault: cn=ppolicy,ou=policies,dc=example,dc=cn
  olcPPolicyHashCleartext: TRUE
  olcPPolicyUseLockout: TRUE
  EOF
   
  ldapadd -YEXTERNAL -H ldapi:/// -f ./ppolicy_overlay.ldif

  # 配置 default PPolicy 和规则。逻辑：密码三个月到期，过期后再使用五次后将自动锁定，必须找管理员解锁；能修改最近5次使用过的密码；连续5次输入错误密码，自动锁定账号5分钟
  cat > default_ppolicy.ldif <<EOF
  dn: ou=policies,dc=example,dc=cn
  objectClass: organizationalUnit
  objectClass: top
  ou: policies

  dn: cn=ppolicy,ou=policies,dc=example,dc=cn
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

  ldapadd -x -D'cn=admin,dc=example,dc=cn' -W -H ldapi:/// -f default_ppolicy.ldif
  ```
- 配置 OpenLDAP memberof。
  > 注意，必需要加载refint模块，然后导入memberof和refint的overlay规则
  ```bash
  # 检查memberof的模块是否已经加载
  > root@d0d4490a27c6:/# ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=module{0},cn=config
  > dn: cn=module{0},cn=config
  > objectClass: olcModuleList
  > cn: module{0}
  > olcModulePath: /usr/lib/ldap
  > olcModuleLoad: {0}back_mdb
  > olcModuleLoad: {1}memberof
  > olcModuleLoad: {2}refint
  > olcModuleLoad: {3}ppolicy
  > olcModuleLoad: {4}syncprov

  # 配置memberof的overlay。如果overlay已存在，就不需要再导入。在没有导入对应的模块，导入overlay会出现报错
  > root@d0d4490a27c6:/# ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b olcDatabase={1}mdb,cn=config dn
  > dn: olcDatabase={1}mdb,cn=config
  > dn: olcOverlay={0}memberof,olcDatabase={1}mdb,cn=config
  > dn: olcOverlay={1}refint,olcDatabase={1}mdb,cn=config
  > dn: olcOverlay={2}ppolicy,olcDatabase={1}mdb,cn=config

  # 配置memberof的overlay。
  cat > member_overlay.ldif <<EOF
  dn: olcOverlay=memberof,olcDatabase={1}mdb,cn=config
  objectClass: olcConfig
  objectClass: olcMemberOf
  objectClass: olcOverlayConfig
  objectClass: top
  olcOverlay: memberof
  olcMemberOfDangling: ignore
  olcMemberOfRefInt: TRUE
  olcMemberOfGroupOC: groupOfUniqueNames
  olcMemberOfMemberAD: uniqueMember
  olcMemberOfMemberOfAD: memberOf
  EOF

  ldapadd -YEXTERNAL -H ldapi:/// -f ./member_overlay.ldif
  ```
- 配置 OpenLDAP refint
  ```bash
  # 检查refint的模块是否已经加载
  > root@d0d4490a27c6:/# ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=module{0},cn=config
  > dn: cn=module{0},cn=config
  > objectClass: olcModuleList
  > cn: module{0}
  > olcModulePath: /usr/lib/ldap
  > olcModuleLoad: {0}back_mdb
  > olcModuleLoad: {1}memberof
  > olcModuleLoad: {2}refint
  > olcModuleLoad: {3}ppolicy
  > olcModuleLoad: {4}syncprov

  # 配置refint的overlay。如果overlay已存在，就不需要再导入。在没有导入对应的模块，导入overlay会出现报错
  > root@d0d4490a27c6:/# ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b olcDatabase={1}mdb,cn=config dn
  > dn: olcDatabase={1}mdb,cn=config
  > dn: olcOverlay={0}memberof,olcDatabase={1}mdb,cn=config
  > dn: olcOverlay={1}refint,olcDatabase={1}mdb,cn=config
  > dn: olcOverlay={2}ppolicy,olcDatabase={1}mdb,cn=config

  # 配置refint的overlay。
  cat > refint_overlay.ldif <<EOF
  dn: olcOverlay=refint,olcDatabase={1}mdb,cn=config
  objectClass: olcConfig
  objectClass: olcOverlayConfig
  objectClass: olcRefintConfig
  objectClass: top
  olcOverlay: {1}refint
  olcRefintAttribute: memberof member manager owner uniqueMember
  EOF

  ldapadd -Q -Y EXTERNAL -H ldapi:/// -f refint_overlay.ldif
  ```
---
- 配置 OpenLDAP syncprov。用于复制同步数据
  ```bash
  # 检查syncprov的模块是否已经加载
  > root@d0d4490a27c6:/# ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=module{0},cn=config
  > dn: cn=module{0},cn=config
  > objectClass: olcModuleList
  > cn: module{0}
  > olcModulePath: /usr/lib/ldap
  > olcModuleLoad: {0}back_mdb
  > olcModuleLoad: {1}memberof
  > olcModuleLoad: {2}refint
  > olcModuleLoad: {3}ppolicy
  > olcModuleLoad: {4}syncprov

  # 配置syncprov的overlay。如果overlay已存在，就不需要再导入。在没有导入对应的模块，导入overlay会出现报错
  > root@d0d4490a27c6:/# ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b olcDatabase={0}config,cn=config dn
  > dn: olcDatabase={0}config,cn=config
  > dn: olcOverlay={0}syncprov,olcDatabase={0}config,cn=config

  > root@d0d4490a27c6:/# ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b olcDatabase={1}mdb,cn=config dn
  > dn: olcDatabase={1}mdb,cn=config
  > dn: olcOverlay={0}memberof,olcDatabase={1}mdb,cn=config
  > dn: olcOverlay={1}refint,olcDatabase={1}mdb,cn=config
  > dn: olcOverlay={2}ppolicy,olcDatabase={1}mdb,cn=config
  > dn: olcOverlay={3}syncprov,olcDatabase={1}mdb,cn=config

  # 添加复制节点信息（未完成）；Add sync replication on backend
  cat > repl.ldif <<EOF
  dn: olcDatabase={1}mdb,cn=config
  changetype: modify
  add: olcSyncRepl
  olcSyncRepl: rid=103 provider=ldap://10.111.105.101 binddn="cn=admin,dc=example,dc=cn"   bindmethod=simple credentials="51trpdq_emWYsfbu" searchbase="dc=example,dc=cn"   type=refreshAndPersist interval=00:00:00:10 retry="60 +" timeout=1 starttls=critical
  -
  add: olcLimits
  olcLimits: dn.exact="cn=admin,dc=example,dc=cn" time.soft=unlimited time.hard=unlimited size.  soft=unlimited size.hard=unlimited
  EOF
  
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
  ```
- 添加用户测试
  ```bash
  cat > user.ldif <<EOF
  dn: ou=people,dc=example,dc=cn
  ou: people
  objectClass: organizationalUnit
  objectClass: top

  dn: uid=john,ou=people,dc=example,dc=cn
  cn: John Doe
  givenName: John
  sn: Doe
  uid: john
  uidNumber: 5000
  gidNumber: 10000
  homeDirectory: /home/john
  mail: john.doe@example.cn
  objectClass: top
  objectClass: posixAccount
  objectClass: shadowAccount
  objectClass: inetOrgPerson
  objectClass: organizationalPerson
  objectClass: person
  loginShell: /bin/bash
  userPassword: {SHA}M6XDJwA47cNw9gm5kXV1uTQuMoY=

  dn: ou=groups,dc=example,dc=cn
  ou: groups
  objectClass: organizationalUnit
  objectClass: top

  dn: cn=mygroup,ou=groups,dc=example,dc=cn
  objectClass: groupOfUniqueNames
  cn: mygroup
  description: All users
  uniqueMember: uid=john,ou=people,dc=example,dc=cn
  EOF

  # 导入信息
  ldapadd -x -D cn=admin,dc=example,dc=cn -W -f user.ldif

  # 查询用户信息
  ldapsearch -x -LLL -H ldap:/// -b uid=john,ou=people,dc=example,dc=cn dn memberof

  # 结果应该为
  dn: uid=john,ou=People,dc=example,dc=cn
  memberOf: cn=mygroup,ou=groups,dc=example,dc=cn
  ```
### 修改用户密码
  ```bash
  #更改自己的用户密码；（需要知道自己的旧密码）
  ldappasswd -H ldap://server_domain_or_IP -x -D "user_dn" -W -A -S

  #使用rootDN修改普通用户密码
  ldappasswd -H ldap://server_domain_or_IP -x -D "cn=admin,dc=example,dc=cn" -W -S "uid=bob,ou=people,dc=example,dc=cn"

  #修改rootDN的密码（Changing the Password in the Config DIT）
  1.Finding the Current RootDN Information（查找rootDN的信息）
  ldapsearch -H ldapi:// -LLL -Q -Y EXTERNAL -b "cn=config" "(olcRootDN=*)" dn olcRootDN olcRootPW | tee ~/newpasswd.ldif

  输出内容为:
  dn: olcDatabase={0}config,cn=config
  olcRootDN: cn=admin,cn=config
  olcRootPW: {SSHA}Pr2ItyqqGT9v1TmOytffCMx71e9ct8h5
  
  dn: olcDatabase={1}mdb,cn=config
  olcRootDN: cn=admin,dc=example,dc=cn
  olcRootPW: {SSHA}Bx/YNB41JvXAs3s7sOPXTa0AkQ7vIoxZ

  2.使用slappasswd生成新密码的加密字符串，设置密码为qwert
  slappasswd -s qwert
  > {SSHA}axnmUjk7WT0mWehZVE5IqeZ790n5WVGX

  3.编辑newpasswd.ldif
  cat > newpasswd.ldif <<EOF
  dn: olcDatabase={0}config,cn=config
  changetype: modify
  replace: olcRootPW
  olcRootPW: {SSHA}axnmUjk7WT0mWehZVE5IqeZ790n5WVGX
  
  dn: olcDatabase={1}mdb,cn=config
  changetype: modify
  replace: olcRootPW
  olcRootPW: {SSHA}axnmUjk7WT0mWehZVE5IqeZ790n5WVGX
  EOF

  4. 导入配置
  ldapmodify -H ldapi:// -Y EXTERNAL -f ~/newpasswd.ldif

  # Changing the Password in the Normal DIT
  cat > newpasswd.ldif <<EOF
  dn: cn=admin,dc=example,dc=cn
  changetype: modify
  replace: userPassword
  userPassword: {SSHA}Bx/YNB41JvXAs3s7sOPXTa0AkQ7vIoxZ
  EOF
  
  ldapmodify -H ldap:// -x -D "cn=admin,dc=example,dc=cn" -W -f ~/newpasswd.ldif
  ```

---
# 参考信息
- [How To Change Account Passwords on an OpenLDAP Server](https://www.digitalocean.com/community/tutorials/how-to-change-account-passwords-on-an-openldap-server)
- [OpenLDAP](https://leohsiao.com/Web/%E5%90%8E%E7%AB%AF/%E8%BA%AB%E4%BB%BD%E8%AE%A4%E8%AF%81/LDAP/OpenLDAP.html)
- [Openldap 配置用户权限](https://www.jianshu.com/p/a47a835d7bf6)