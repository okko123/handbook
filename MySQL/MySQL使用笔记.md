## 使用笔记
mysqldump，关闭GTID，导出数据库
mysqldump db_name -uroot -p --set-gtid-purged=off > /var/sql_name.sql