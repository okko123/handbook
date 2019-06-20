# AWS的RDS从库中断
### 当时出现问题时候，从库上的信息
```bash
show slave status\G;
#报错内容：
Last_SQL_Errno: 1032
Last_SQL_Error: Could not execute Delete_rows event on table mysql.user; Can't find record in 'user', Error_code: 1032; handler error HA_ERR_KEY_NOT_FOUND; the event's master log mysql-bin.000022, end_log_pos 16360394
```

### 但是在使用GTID进行主从复制的数据库中，如果复制过程发生错误，上述方法是不能用，我们尝试一下（由于使用aws的托管服务，因此需要使用CALL mysql.rds_skip_repl_error替换SET GLOBAL SQL_SLAVE_SKIP_COUNTER = 1）
```bash
mysql> CALL mysql.rds_skip_repl_error;
ERROR 1858 (HY000): sql_slave_skip_counter can not be set when the server is running with @@GLOBAL.GTID_MODE = ON. Instead, for each transaction that you want to skip, generate an empty transaction with the same GTID as the transaction
```

### 提示我们可以生成一个空事务来跳过错误的事务。我们先来看下主库和从库的状态：
- 主库
- 从库，检查从库的状态，Retrieved_Gtid_Set项：记录了relay日志从Master获取了binlog日志的位置，Executed_Gtid_Set项：记录本机执行的binlog日志位置,从机上该项中包括主机和从机的binlog日志位置。
```bash
(省略部分)
               Last_SQL_Errno: 1032
               Last_SQL_Error: Could not execute Delete_rows event on table mysql.user; Can't find record in 'user', Error_code: 1032; handler error HA_ERR_KEY_NOT_FOUND; the event's master log mysql-bin.000022, end_log_pos 16360394
           Retrieved_Gtid_Set: 9a038d11-59e9-11e9-bd87-d09466651db4:4525558-7054833
            Executed_Gtid_Set: 9a038d11-59e9-11e9-bd87-d09466651db4:4525558-7040102,
f17292f0-477b-3918-8bfd-3ec33999d36e:1-1244
```
 - 第7040103个事务出现问题，我们插入空事务，跳过该错误。
 ```bash
 mysql>  call mysql.rds_stop_replication ();
+---------------------------+
| Message                   |
+---------------------------+
| Slave is down or disabled |
+---------------------------+
1 row in set (1.01 sec)

Query OK, 0 rows affected (1.02 sec)

mysql> set gtid_next="9a038d11-59e9-11e9-bd87-d09466651db4:4525558-7040103";
ERROR 1227 (42000): Access denied; you need (at least one of) the SUPER privilege(s) for this operation
mysql> 
```
- 由于使用AWS托管的数据库服务，所以提供的admin账号也不是最高权限，因此不能使用插入空事务的方式进行跳过
- 因此我们换一个方式，到主库的binlog上查看出问题的SQL
```bash
mysqlbinlog  mysql-bin.000022 --start-position=26238767 -d mysql --base64-output=decode-rows -v
#输出的内容为
(省略部分)
# at 16360042
#190612 16:10:22 server id 101  end_log_pos 16360214 CRC32 0x0386f5c5 	Table_map: `mysql`.`user` mapped to number 915
# at 16360214
#190612 16:10:22 server id 101  end_log_pos 16360394 CRC32 0x48ec9542 	Delete_rows: table id 915 flags: STMT_END_F
### DELETE FROM `mysql`.`user`
### WHERE
###   @1='%'
###   @2='sysbench'
###   @3=2
```
- 结果显示在主库上，删除了一个sysbench@'%'的用户。知道问题后，在从库上创建一个sysbench@'%'的用户，然后重新启动从库同步。即可解决问题
```bash
mysql> grant select *.* to sysbench@'%';
mysql> call mysql.rds_stop_replication ();
mysql> call mysql.rds_start_replication ();
+-------------------------+
| Message                 |
+-------------------------+
| Slave running normally. |
+-------------------------+
1 row in set (1.02 sec)

mysql> show slave status\G;
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000022
          Read_Master_Log_Pos: 26246696
               Relay_Log_File: relaylog.003130
                Relay_Log_Pos: 360
        Relay_Master_Log_File: mysql-bin.000022
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
```
### 总结
- AWS的托管数据库服务提供的管理员的账号不拥有最高权限
- RDS不会同步主库中mysql的信息，因此当执行删除用户的操作时，因为从库上的用户不存在导致报错。