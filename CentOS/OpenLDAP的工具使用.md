## 添加访问规则
cat > add_access.ldif <<EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcAccess
olcAccess: to * by self write by * read
EOF
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f add_access.ldif

## 删除访问规则（全部删除）
cat > del_access.ldif <<EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
delete: olcAccess
EOF
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f del_access.ldif

## 查询
ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=config dn

## 配置 OpenLDAP Pasword policy
1. 加载 ppolicy schema：
   ```bash
   ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/ppolicy.ldif。
   # 检查schema是否成功导入；成功添加后会出现dn: cn={4}ppolicy,cn=schema,cn=config的条目
   ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=schema,cn=config dn
   ```
2. 加载 ppolicy module
   ```bash
   cat > ppolicy_module.ldif <<EOF
   dn:cn=module{0},cn=config
   changetype: modify
   add: olcModuleLoad
   olcModuleLoad: ppolicy
   EOF
   ldapadd -Y EXTERNAL -H ldapi:/// -f ppolicy_module.ldif

   # 检查module是否被加载；成功添加会出现olcMoudleload: ppolicy条目
   ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=module{0},cn=config
   ```
3. 加载 ppolicy overlay
   ```bash
   # 部分配置说明：
   # UseLockout：超过最多失败次数后，锁定账号时的提示
   # HashCleartest：密码明文在保存的数据库中必须进行hash加密

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
4. 配置 default PPolicy 和规则。逻辑：密码三个月到期，过期后再使用五次后将自动锁定，必须找管理员解锁；不能修改最近5次使用过的密码；连续5次输入错误密码，自动锁定账号5分钟
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
## 配置memberof用户组
1. 加载 memberof module
   ```bash
   cat > memberof_module.ldif <<EOF
   dn:cn=module{0},cn=config
   changetype: modify
   add: olcModuleLoad
   olcModuleLoad: memberof
   EOF
   ldapadd -Y EXTERNAL -H ldapi:/// -f memberof_module.ldif

   # 检查module是否被加载；成功添加会出现olcMoudleload: ppolicy条目
   ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=module{0},cn=config
   ```
2. 加载 memberof overlay
   ```bash
   cat > member_overlay.ldif <<EOF
   dn: olcOverlay={0}memberof,olcDatabase={1}mdb,cn=config
   objectClass: olcConfig
   objectClass: olcMemberOf
   objectClass: olcOverlayConfig
   objectClass: top
   olcOverlay: memberof
   olcMemberOfDangling: ignore
   olcMemberOfRefInt: TRUE
   olcMemberOfGroupOC: groupOfNames
   olcMemberOfMemberAD: member
   olcMemberOfMemberOfAD: memberOf
   EOF

   ldapadd -YEXTERNAL -H ldapi:/// -f ./member_overlay.ldif
   ```
3. 加载 
   ```bash
   cat > 1.ldif <<EOF
   dn: cn=module{1},cn=config
   add: olcmoduleload
   olcmoduleload: refint
   EOF

   cat > 2.ldif <<EOF
   dn: olcOverlay={1}refint,olcDatabase={1}mdb,cn=config
   objectClass: olcConfig
   objectClass: olcOverlayConfig
   objectClass: olcRefintConfig
   objectClass: top
   olcOverlay: {1}refint
   olcRefintAttribute: memberof member manager owner
   EOF

   ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f 1.ldif
   ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /tmp/refint2.ldif
   ```
4. 添加用户测试
   ```bash
   cat > test.ldif <<EOF
   dn: uid=john,ou=people,dc=example,dc=com
   cn: John Doe
   givenName: John
   sn: Doe
   uid: john
   uidNumber: 5000
   gidNumber: 10000
   homeDirectory: /home/john
   mail: john.doe@example.com
   objectClass: top
   objectClass: posixAccount
   objectClass: shadowAccount
   objectClass: inetOrgPerson
   objectClass: organizationalPerson
   objectClass: person
   loginShell: /bin/bash
   userPassword: {SHA}M6XDJwA47cNw9gm5kXV1uTQuMoY=

   dn: cn=mygroup,ou=groups,dc=example,dc=com
   objectClass: groupofnames
   cn: mygroup
   description: All users
   member: uid=john,ou=people,dc=example,dc=com
   EOF
   
   # 导入信息
   ldapadd -x -D cn=admin,dc=example,dc=com -W -f test.ldif
   
   # 查询用户信息
   ldapsearch -x -LLL -H ldap:/// -b uid=john,ou=people,dc=example,dc=com dn memberof
   # 结果应该为
   dn: uid=john,ou=People,dc=example,dc=com
   memberOf: cn=mygroup,ou=groups,dc=example,dc=com
   ```
### 参考信息
- [配置 OpenLDAP Pasword policy (ppolicy)](https://blog.csdn.net/cuiaamay/article/details/52438777)
- [How to enable MemberOf using OpenLDAP](https://www.adimian.com/blog/2014/10/how-to-enable-memberof-using-openldap/)