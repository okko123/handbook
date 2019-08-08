## 要求
### 数据要求
* 使用Innodb引擎
* 使用唯一主键
* 隔离级别READ COMMITTED
* 启用binary log，且log格式未row
* 启动GTID模式
* 主机名可以解析对应服务器的IP
### 搭建MGR
|实例名|A|B|C|
|-|-|-|-|
|IP|192.168.1.1|192.168.1.2|192.168.1.3|
|Port|3306|3306|3306|
|Server-ID|101|102|103|
|MySQL Version|5.7.26|5.7.26|5.7.26|

- 单主模式
  - 配置关于GTID及日志信息记录相关参数
  ```bash
  gtid_mode=on
  enforce-gtid-consistency=on
  binlog_gtid_simple_recovery=1
  log-slave-updates=1
  binlog_checksum=NONE
  master_info_repository=TABLE
  relay_log_info_repository=TABLE
  ```
  - MGR相关配置
  ```bash
  #动态配置：
  set global transaction_write_set_extraction = 'XXHASH64';
  set global group_replication_start_on_boot = OFF;
  set global group_replication_bootstrap_group = OFF ;
  set global group_replication_group_name= '9ac06b4e-13aa-11e7-a62e-5254004347f9';
  set global group_replication_local_address = '192.168.1.1:24201';
  set global group_replication_group_seeds = '192.168.1.1:24201,192.168.1.2:24201,192.168.1.3:24201';
  set global group_replication_ip_whitelist ='192.168.1.0/24';
  set global group_replication_single_primary_mode = True;
  set global group_replication_enforce_update_everywhere_checks = False;
   
  #cnf文件配置：
  transaction_write_set_extraction = XXHASH64
  loose-group_replication_group_name = '9ac06b4e-13aa-11e7-a62e-5254004347f9'
  loose-group_replication_ip_whitelist = '192.168.1.0/24'
  loose-group_replication_start_on_boot = OFF
  loose-group_replication_local_address = '192.168.1.1:24201'
  loose-group_replication_group_seeds = '192.168.1.1:24201,192.168.1.2:24201,192.168.1.3:24201'
  loose-group_replication_bootstrap_group = OFF
  loose-group_replication_single_primary_mode = true
  loose-group_replication_enforce_update_everywhere_checks = false
  ```
  - 每个实例执行以下操作
  ```bash
  GRANT REPLICATION SLAVE ON *.* TO 'repl'@'192.168.%' IDENTIFIED BY 'replforslave';
  INSTALL PLUGIN group_replication SONAME 'group_replication.so';
  #只需要在A实例上初始化配置
  SET GLOBAL group_replication_bootstrap_group=ON;
  CHANGE MASTER TO MASTER_USER='repl', MASTER_PASSWORD='replforslave' FOR CHANNEL 'group_replication_recovery';
  start group_replication;
  SET GLOBAL group_replication_bootstrap_group=OFF;
  #B、C实例上初始化配置
  CHANGE MASTER TO MASTER_USER='repl', MASTER_PASSWORD='replforslave' FOR CHANNEL 'group_replication_recovery';
  start group_replication;
  ```
  

### 遇到的问题
- 使用快照的方式进行数据恢复，导致恢复的实例使用了相同的uuid.修复的方法：
  - 删除数据目录下的auto.cnf文件，然后重启数据库实例，自动生成新的auto.cnf文件和内容
  - 使用uuidgen生成新的uuid，替换auto.cnf中的UUID，重启数据库实例。
```bash
#MySQL的日志中出现如下提示
2019-08-01T18:09:41.160230+08:00 0 [ERROR] Plugin group_replication reported: 'There is already a member with server_uuid 8a1b7270-9ef1-11e9-9f2b-000d3a28915e. The member will now exit the group.'
```

### 参考连接
- https://www.cnblogs.com/xinysu/p/6674832.html#autoid-4-1-0
- https://zhuanlan.zhihu.com/p/40627399
- https://dbaplus.cn/news-11-1913-1.html
- http://wubx.net/mgr%E7%9B%91%E6%8E%A7%E5%8F%8A%E4%BC%98%E5%8C%96%E7%82%B9/