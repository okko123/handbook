
#### 在 OpenLDAP 的 RTC (Runtime Configuration) 架构中，这两个条目是整个服务器的核心。简单来说，一个是**“管理后台的配置”，一个是“业务数据的载体”
1. olcDatabase={0}config,cn=config (配置库)
   > 这是 OpenLDAP 自身的配置数据库。
   * 作用： 它存储了服务器运行的所有参数，包括加载哪些模块、日志级别、管理员密码、以及其他数据库（如 mdb）的定义。
   * 存储位置： 物理上对应 /etc/ldap/slapd.d/cn=config.ldif 和相关的子目录。
   * 特点：它是“数据库的数据库”。
     * 修改这个条目，可以实现无需重启服务即时更改配置。
     * 它的管理员通常拥有最高的权限。
2. olcDatabase={1}mdb,cn=config (业务库)
   > 这是你存放实际业务数据（如用户账号、组织架构、密码等）的数据库实例。
   * 作用： 它是数据的具体“容器”。mdb 指的是 LMDB (Lightning Memory-Mapped Database)，这是目前 OpenLDAP 官方推荐的高性能后端存储引擎。
   * 存储位置： 物理上，它的配置信息在 /etc/ldap/slapd.d/cn=config/ 下，但它存的数据（用户的 DN 等）通常放在 /var/lib/ldap/。
   * 特点：
     * 它是被 {0}config 定义出来的。
     * 你日常通过 LDAP 客户端查询的用户、组信息都住在这里。
3. 两者的联系与层级关系
   > 你可以把 OpenLDAP 想象成一架复杂的机器：
   
   |组件|对应条目|形象比喻|负责内容|
   |---|---|---|---|
   |中央控制器|{0}config|操作系统/主板|控制机器如何运行、开启哪些功能、谁能管理这台机器。|
   |存储硬盘|{1}mdb|数据分区|专门用来存放你丢进去的文件（用户数据）。|
核心联系：
1. 从属关系： {0}config 包含了对 {1}mdb 的定义。如果你在 {0}config 中删除了关于 {1}mdb 的配置，那么你的所有用户数据虽然在硬盘上，但 LDAP 服务器将不再读取和承认它们。
2. 管理链条： 你通常需要先通过 {0}config 获得授权，才能去操作 {1}mdb 的结构（例如添加索引、修改最大容量限制等）。
3. 索引编号： 括号里的数字 {0} 和 {1} 代表了加载顺序。config 必须是第一个（0），因为只有它启动了，服务器才知道后面该加载哪些业务数据库。
---
#### 为了让 OpenLDAP 的“配置”和“数据”都能实现主从同步，你必须分别在两个数据库上开启同步功能。
1. 为什么要分两个地方配置？
   > 在 OpenLDAP 中，cn=config 本身也是一个数据库（编号通常为 {0}），而你的业务数据（如 dc=example,dc=com）位于另一个数据库（如 {1}mdb）。

    * 在 olcDatabase={0}config 下配置 syncprov：
      * 目的： 为了同步服务器配置。
      * 场景： 当你有多台 LDAP 服务器组成集群（MirrorMode 或多主架构）时，你希望在 A 机器上修改了一个索引或增加了一个 Schema，B 机器能自动同步这些配置变更。
      * 效果： 同步的是 /etc/ldap/slapd.d/ 里的内容。
    * 在 olcDatabase={1}mdb 下配置 syncprov：
      * 目的： 为了同步业务数据。
      * 场景： 这是最常见的需求。当你在 A 机器上增加了一个用户，你希望 B 机器（从服务器）也能查到这个用户数据。
      * 效果： 同步的是 /var/lib/ldap/ 里的数据。
2. 两者的配置内容有区别吗？
   > 虽然它们都叫 olcOverlay=syncprov，但它们定义的“作用域”不同：

|特性|在 {0}config下|在 {1}mdb 下|
|---|---|---|
|同步什么|所有的配置项、权限、Schema|所有的用户、组、组织单位|
|对应的 Consumer (从端)|从服务器的 olcDatabase={0}config|从服务器的 olcDatabase={1}mdb|
|典型指令|olcSpCheckpoint (针对配置库)|olcSpCheckpoint, olcSpSessionLog (针对大数据量)|
3. 它们之间的逻辑关系
   > 如果你只在 {1}mdb 下配置了同步，而没有在 {0}config 下配置：
     1. 你在主节点手动添加一个用户，从节点会同步这个用户。
     2. 你在主节点修改了一个 olcDbIndex（索引），从节点不会同步这个索引。这会导致两台服务器的性能表现或搜索结果不一致。
   > 所以，在生产环境的集群中，通常建议“双重配置”：
     1. 先同步配置 ({0}config)：保证所有节点的运行规则一致。
     2. 再同步数据 ({1}mdb)：保证所有节点的数据内容一致。
---
#### 通过修改 {0}config 来调整 {1}mdb 的性能参数，我们主要关注的是 LMDB (MDB) 引擎特有的几个核心属性。
> 在 OpenLDAP 中，olcDatabase={1}mdb 对应的配置决定了数据库的存储性能、容量限制和读写行为。

> 以下是几个最常用的调整操作：
1. 调整最大数据库容量 (olcDbMaxSize)
   > 这是最常见的调整需求。MDB 采用内存映射（Memory Map），必须预先设定一个最大的上限。如果你的数据量增长超过这个值，LDAP 会报错 LDAP_ADMINLIMIT_EXCEEDED。
   * 默认值：通常很小（比如 10MB 或 1GB，取决于发行版）。
   * 修改 LDIF 示例（将上限改为 2GB）：
     ```ldif
     dn: olcDatabase={1}mdb,cn=config
     changetype: modify
     replace: olcDbMaxSize
     olcDbMaxSize: 2147483648
     # (注：单位是字节 Byte)
     ```
2. 调整检查点 (olcDbCheckpoint)
   > olcDbCheckpoint 决定了将数据从内存刷入硬盘的频率。设置得太频繁会影响写入性能，设置得太稀疏则在断电时增加数据丢失风险。
   * 语法：olcDbCheckpoint: <字节数> <分钟数>
   * 修改 LDIF 示例（当写入达到 1MB 或经过 5 分钟时刷盘）：
     ```ldif
     dn: olcDatabase={1}mdb,cn=config
     changetype: modify
     replace: olcDbCheckpoint
     olcDbCheckpoint: 1048576 5
     ```
3. 设置索引 (olcDbIndex)
如果你发现查询（ldapsearch）变慢了，通常是因为缺少索引。索引是直接定义在数据库配置里的。
   > 修改 LDIF 示例（为 uid 添加索引）：
     ```ldif
     dn: olcDatabase={1}mdb,cn=config
     changetype: modify
     add: olcDbIndex
     olcDbIndex: uid eq,pres,sub
     (注：eq 等值, pres 存在, sub 子串查询)
     ```
4. 权限控制 (olcAccess)
   > 这也是在 {1}mdb 下定义的。它决定了谁能读写这个数据库的数据。
   * 修改 LDIF 示例（允许匿名读取，允许自己改密码）：
     ```ldif
     dn: olcDatabase={1}mdb,cn=config
     changetype: modify
     replace: olcAccess
     olcAccess: {0}to attrs=userPassword by self write by anonymous auth by * none
     olcAccess: {1}to * by * read
     ```
---
> 执行修改的步骤

> 将上述任何一个 LDIF 内容保存为文件（如 modify_mdb.ldif），然后运行：
  ```bash
  sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f modify_mdb.ldif
  ```
> 注意事项
  1. 无需重启：对 {1}mdb 的这些修改大多是即时生效的。
  2. 安全性：修改 olcDbMaxSize 时，请确保你的物理磁盘有足够的空间。
  3. 查看当前值：在修改前，建议先看看现在的参数：
     ```bash
     sudo ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b "olcDatabase={1}mdb,cn=config"
     ```