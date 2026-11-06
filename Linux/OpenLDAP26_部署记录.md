### OpenLDAP 2.6 部署记录
- 系统: Ubuntu 24.04.2 LTS
- OpenLDAP: 2.6.13
- 注意事项
  1. OpenLDAP 2.4 升级到 2.6，ldapi:// 的调用命令格式（如 ldapsearch -Y EXTERNAL -H ldapi:///）完全没有变；但 2.6 对 cn=config 的 Schema 校验、数据库模块（必须为 MDB）以及默认 ACL 权限要求更加严苛。这也就是为什么在 2.4 里能正常初始化并用 ldapi:/// 查出的配置，放到 2.6 里如果 LDIF 文件的 dn 命名规范不完全严谨（如未加 {0}、{-1} 等隐式编号前缀或缺失 config 库声明），就会报 No such object (32) 的根本原因
  2. OpenLDAP 2.6：完全删除了 BDB 和 HDB 模块的代码。back_mdb（LMDB 内存映射数据库）成为唯一的标准后端。
     - 通过 ldapi:// 进行管理时：所有动态加载配置必须使用 olcModuleload: back_mdb.la（或内建 back_mdb）。
     - 配置节点统一命名为 olcDatabase={1}mdb,cn=config，如果使用旧的 bdb 模块配置通过 ldapi:// 写入，2.6 会直接抛出非法属性或找不到模块的错误。
### 使用源码编译安装
1. 从OpenLDAP官网下载源码包
   ```bash
   wget https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-2.6.13.tgz
   ```
2. 编译安装，开启动态插件
   - 本次编译安装方式仅启用了如下参数。
     - --enable-modules：支持动态加载模块，运行时依赖于 libltdl7 包，编译时依赖于 liblttdl-dev。
     - --enable-ppolicy=mod：用于在 LDAP 层强制实施统一的密码安全策略。
     - --enable-memberof=mod：自动维护用户条目中的 memberOf 属性，实现“双向关联”。
     - --enable-syncprov=mod：支持 OpenLDAP 的 Syncrepl（复制/主从同步）机制。
     - --enable-refint=mod：它的主要作用是保证数据库中的引用一致性。
     - --with-cyrus-sas：启用 Cyrus SASL（Simple Authentication and Security Layer，简单身份验证和安全套接字层） 库的支持。。编译时依赖libsasl2-dev
     - --with-systemd：让 slapd 服务在运行时能够与 Linux 的 systemd 初始化系统进行原生通信（调用 sd_notify API）。编译时依赖于libsystemd
     - --with-threads
     - --with-tls
   ```bash
   # 安装系统的基础依赖包
   apt install make gcc libsasl2-dev libltdl-dev -y

   tar xf openldap-2.6.13.tgz
   cd openldap-2.6.13
   ./configure \
   --prefix=/usr/local/openldap-26 \
   --enable-modules \
   --enable-ppolicy=mod \
   --enable-memberof=mod \
   --enable-syncprov=mod \
   --enable-refint=mod \
   --with-cyrus-sasl \
   --with-systemd \
   --with-threads \
   --with-tls

   make
   make test
   make install

   # 运行以下命令查看 slapd 静态集成了哪些内置模块：
   slapd -VVV
   @(#) $OpenLDAP: slapd 2.6.13 (Aug  3 2026 17:01:44) $
           root@nuc:/home/abc/openldap-2.6.13/servers/slapd

   Included static backends:
       config
       ldif
       monitor
       mdb
       relay
   ```
3. 初始化配置。样例文件[slapd.ldif](conf/slapd-26.ldif)
   ```bash
   # 使用编辑器编辑提供的slapd.ldif示例（通常安装在/usr/local/etc/openldap/slapd.ldif），使其包含如下形式的 MDB 数据库定义：
   ## 本例安装的路径为: /usr/local/openldap-26，因此slapd.ldif文件的位置是/usr/local/openldap-26/etc/openldap/slapd.ldif
   ## 本例使用的域名为example.cn 

   mkdir -p /tmp/ldap_init /usr/local/openldap-26/etc/slapd.d /usr/local/openldap-26/var/openldap-data
   pushd /tmp/ldap_init

   cp /usr/local/openldap-26/etc/openldap/slapd.ldif .

   # 按需修改dc的域名、管理账号，管理员密码
   sed -i 's|my-domain|example|g' slapd.ldif
   sed -i 's|com|cn|g' slapd.ldif
   sed -i 's|Manager|admin|g' slapd.ldif
   sed -i 's|secret|123456|g' slapd.ldif

   # 使用root用户，运行以下命令导入配置数据库
   /usr/local/openldap-26/sbin/slapadd -n 0 -F /usr/local/openldap-26/etc/slapd.d -l /tmp/ldap_init/slapd.ldif

   # 使用root用户，监听380端口和unixsocket，运行以下命令来启动独立 LDAP 守护程序slapd (8)：
   /usr/local/openldap-26/libexec/slapd -h "ldap:/// ldapi:///" -F /usr/local/openldap-26/etc/slapd.d
   ```
4. 检查
   ```bash
   # 要检查服务器是否正在运行且配置正确，可以使用ldapsearch (1) 对其进行搜索。
   /usr/local/openldap-26/bin/ldapsearch -x -LLL -b '' -s base '(objectclass=*)' namingContexts

   # 请注意，命令参数周围使用了单引号，以防止 shell 解析特殊字符。此命令应返回：
   dn:
   namingContexts: dc=example,dc=cn
   ```
5. 添加模块：
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

   # 成功导入后，返回的结果为：
   SASL/EXTERNAL authentication started
   SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
   SASL SSF: 0
   adding new entry "olcOverlay={0}memberof,olcDatabase={1}mdb,cn=config"

   # 检查
   ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=module{0},cn=config
   ```
6. 添加memberOf配置：
   - 针对 groupOfUniqueNames 类型的组进行了自定义适配。在 OpenLDAP 数据库中启用并定制 memberof Overlay（覆盖层），使其能够根据组变更自动维护用户条目中的 memberOf 反向引用属性。
   - 配置效果：导入此 LDIF 后，当你向一个 groupOfUniqueNames 组的 uniqueMember 属性添加用户 DN 时，OpenLDAP 会自动在该用户的条目里生成对应的 memberOf 属性；从组里移除该用户时，用户条目中的 memberOf 也会自动被删掉。
   - 追溯性提示：开启 memberof Overlay 只对后续新增或修改的组数据生效。对于导入前就已经存在的组和用户数据，不会自动补全 memberOf 属性，需要重新触发一次组更新或手动刷新。
   ```bash
   cat > memberof.ldif <<EOF
   dn: olcOverlay={0}memberof,olcDatabase={1}mdb,cn=config
   changetype: add
   objectClass: olcOverlayConfig
   objectClass: olcMemberOf
   olcOverlay: {0}memberof
   olcMemberOfDangling: ignore
   olcMemberOfRefInt: TRUE
   olcMemberOfGroupOC: groupOfUniqueNames
   olcMemberOfMemberAD: uniqueMember
   olcMemberOfMemberOfAD: memberOf
   EOF

   ldapadd -Y EXTERNAL -H ldapi:/// -f memberof.ldif

   # 检查
   ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b olcOverlay={0}memberof,olcDatabase={1}mdb,cn=config
   ```
7. refint配置
   - 在 OpenLDAP 数据库中开启并配置 refint（Referential Integrity / 引用完整性）Overlay，用于自动清理和同步“悬空指针/失效引用”。
   - 当数据库中的某条目（如用户）被删除或改名/移动（ModRDN）时，refint 模块会自动检查并更新其他条目中指向该 DN（Distinguished Name）的属性值。
   - 配合 memberof 使用：refint 与 memberof 常常搭配使用。memberof 负责维持组与用户的自动关联，而 refint 保证用户或组在被彻底删除/改名时，引用的关系不会变成无效的废数据。
   - 性能影响：每次删除或改名被监控属性所指向的 DN 时，OpenLDAP 都会全库扫描包含该 DN 的条目并执行更新。在数据量极大的环境中（如数十万用户/组），批量删除或改名操作可能会引起短时间的 CPU/IO 负载上升。
   ```bash
   cat > refint.ldif <<EOF
   dn: olcOverlay={1}refint,olcDatabase={1}mdb,cn=config
   changetype: add
   objectClass: olcOverlayConfig
   objectClass: olcRefintConfig
   olcOverlay: {1}refint
   olcRefintAttribute: owner
   olcRefintAttribute: manager
   olcRefintAttribute: uniqueMember
   olcRefintAttribute: member
   olcRefintAttribute: memberOf
   EOF

   ldapadd -Y EXTERNAL -H ldapi:/// -f refint.ldif

   # 成功导入后，返回结果
   SASL/EXTERNAL authentication started
   SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
   SASL SSF: 0
   adding new entry "olcOverlay={1}refint,olcDatabase={1}mdb,cn=config"

   # 检查
   ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b olcOverlay={1}refint,olcDatabase={1}mdb,cn=config
   ```
8. 添加索引
   ```bash
   cat > index.ldif <<EOF
   dn: olcDatabase={1}mdb,cn=config
   changetype:  modify
   replace: olcDbIndex
   olcDbIndex: uid eq
   olcDbIndex: mail eq
   olcDbIndex: memberOf eq
   olcDbIndex: entryCSN eq
   olcDbIndex: entryUUID eq
   olcDbIndex: objectClass eq
   EOF

   ldapadd -Y EXTERNAL -H ldapi:/// -f index.ldif

   # 成功导入后，返回结果
   SASL/EXTERNAL authentication started
   SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
   SASL SSF: 0
   modifying entry "olcDatabase={1}mdb,cn=config"


   # 检查
   ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b olcDatabase={1}mdb,cn=config
   ```
9. 初始化目录，创建用户
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

   # 创建用户，并带密码。密码用slappasswd -s 123456 生成
   dn: cn=person1, dc=example, dc=cn
   cn: person1
   sn: persion1
   uid: persion1
   uidNumber: 1000
   gidNumber: 1000
   homeDirectory: /home/persion1
   mail: person1@example.cn
   userPassword: {SSHA}4dOQKS4RtV8wpt9VvWkSM4DuGBCA9u2i
   objectclass: person
   objectclass: inetOrgPerson
   objectclass: organizationalPerson
   objectclass: posixAccount
   objectclass: shadowAccount
   EOF

   ldapadd -D "cn=admin, dc=example, dc=cn" -W  -f user.ldif
   ```
10. 创建复制节点的配置
    1. 源节点的配置：
       - olcLimits：解除同步管理员账号的查询限制。
         - 原因：大规模 LDAP 节点初始化全量同步或全库检查时，会拉取成千上万条记录并持续维持长连接。
         - 作用：将 cn=admin 的查询超时时间（time）和一次性返回的最大条目数限制（size）全部设为 unlimited（无限制），防止同步过程中因为触发 OpenLDAP 的默认限制（如 sizelimit=500）而导致同步中断或报错。
       ```bash
       cat > source.ldif <<EOF
       # 1. 加载 syncprov 模块。如果模块已经加载，则不用执行
       dn: cn=module{0},cn=config
       changetype: modify
       add: olcModuleLoad
       olcModuleLoad: syncprov

       # 2. 在配置库 {0}config 上挂载 syncprov
       dn: olcOverlay=syncprov,olcDatabase={0}config,cn=config
       changetype: add
       objectClass: olcOverlayConfig
       objectClass: olcSyncProvConfig
       olcOverlay: syncprov

       # 3. 在业务库 {1}mdb 上挂载 syncprov
       dn: olcOverlay=syncprov,olcDatabase={1}mdb,cn=config
       changetype: add
       objectClass: olcOverlayConfig
       objectClass: olcSyncProvConfig
       olcOverlay: syncprov
       - 
       add: olcMirrorMode
       olcMirrorMode: FALSE
       -
       # 注意，需要根据实际修改DN
       add: olcLimits
       olcLimits: dn.exact="cn=admin,dc=example,dc=cn" time.soft=unlimited time.hard=unlimited size.soft=unlimited size.hard=unlimited
       EOF

       ldapadd -Y EXTERNAL -H ldapi:/// -f source.ldif

       # 检查
       ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b olcDatabase={1}mdb,cn=config
       ```
    2. 复制节点配置：
       ```bash
       cat > repl.ldif <<EOF
       dn: olcDatabase={1}mdb,cn=config
       changetype: modify
       add: olcSyncRepl
       olcSyncRepl: rid=001
         provider=ldap://master.example.com:389
         type=refreshAndPersist
         retry="60 10 300 +"
         searchbase="dc=example,dc=com"
         scope=sub
         bindmethod=simple
         binddn="cn=admin,dc=example,dc=com"
         credentials="MasterAdminPassword"
       -
       # 2. 配置写重定向（当客户端误向从节点发起写入时，提示客户端去主节点写）
       add: olcUpdateref
       olcUpdateref: ldap://master.example.com:389
       -
       add: olcMirrorMode
       olcMirrorMode: FALSE
       EOF

       ldapadd -Y EXTERNAL -H ldapi:/// -f source.ldif

       # 检查
       ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b olcDatabase={1}mdb,cn=config
       ```