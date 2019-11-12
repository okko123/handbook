## 主从数据同步
pt-table-sync --print h=192.168.10.234,D=mobile,t=pms_cron_log h=192.168.10.168 -uchecksum -pchecksum
指定主库的IP h=
指定数据库   D=
指定表       t=
指定用户     -u=
指定密码     -p=
--print 只显示更新的内容，不执行
--execute 执行

## 主从数据验证
pt-table-checksum --socket=/tmp/mysql.sock --user='checksum' --password='checksum' --host='192.168.1.2' --databases=database --tables=table --nocheck-replication-filters

## 在线修改表结构
pt-online-schema-change --user=user --ask-pass --host=192.168.1.1 --port 3306 --alter "ADD KEY  idx_inventory_more_list (company_id,store_id,veh_group_id,status,start_time,end_time,is_del)" D=rental_vehicle_db,t=veh_inventory_allocation_tbl --charset=utf8 --no-version-check --execute

在AWS的RDS上使用pt-online-schema-change，需要在RDS的参数组中修改log_bin_trust_function_creators，设置为1。否则会提示
Error creating triggers: 2019-10-24T16:42:44 DBD::mysql::db do failed: You do not have the SUPER privilege and binary logging is enabled (you *might* want to use the less safe log_bin_trust_function_creators variable) [for Statement "CREATE TRIGGER `pt_osc_bl_del`] at ./pt-online-schema-change line 10708, <STDIN> line 1.

https://techtavern.wordpress.com/2013/06/17/mysql-triggers-and-amazon-rds/