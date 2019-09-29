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