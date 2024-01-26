SQLite Reset Primary Key Field

UPDATE SQLITE_SEQUENCE SET SEQ=0 WHERE NAME='table_name';

pragma table_info(TABLE_NAME) 命令查看数据表结构
- 查看所有表: .table [tableName]
- 查看建表语句: .schema [tableName]
- 查看数据表结构: pragma table_info(TABLE_NAME) / 
