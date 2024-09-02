## Flink CDC 实时同步数据-MySQL2MySQL
- MySQL: 5.7.33
- Flink: 1.18
- 准备三个数据库：flink_source、flink_sink、flink_sink_second
- 将flink_source.source_test表实时同步到flink_sink和flink_sink_second的sink_test表。
---
1. 调整配置MySQL，设置二进制日志格式、ServerID
   ```bash
   cat > my.cnf <<EOF
   [client]
   port=3306
   socket=/tmp/mysql.sock

   [mysqld]
   port=3306
   socket=/tmp/mysql.sock
   basedir=/usr/local/mysql
   datadir=/usr/local/mysql/data
   key_buffer_size=16M
   max_allowed_packet=128M

   log_bin = ON
   server_id = 1
   binlog_format = ROW
   log_bin = /usr/local/mysql/data/mysql-bin
   log_bin_index = /usr/local/mysql/data/mysql-bin.index

   [mysqldump]
   quick
   EOF

   /usr/local/mysql/support-files/mysql.server restart
   ```
2. 登陆MySQL创建用户，数据库，初始化表
   ```bash
   create database flink_source;
   create database flink_sink;
   create database flink_sink_second;

   use flink_source
   CREATE TABLE source_test (
     user_id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
     user_name VARCHAR(255) NOT NULL
   );

   ALTER TABLE source_test AUTO_INCREMENT = 101;

   INSERT INTO source_test
   VALUES (default,"1234"),(default,"eds4f");

   use flink_sink;
   CREATE TABLE sink_test (
     user_id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
     user_name VARCHAR(255) NOT NULL
   );

   use flink_sink_second;
   CREATE TABLE sink_test (
     user_id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
     user_name VARCHAR(255) NOT NULL
   );
   ```
3. Flink安装
   ```bash
   tar xf flink-1.18.1-bin-scala_2.12.tgz

   # 下载连接器的依赖包，JDBC连接器、MySQL连接器、MySQL CDC连接器
   1. flink-connector-jdbc-3.1.2-1.18.jar
   2. flink-sql-connector-mysql-cdc-3.1.0.jar
   3. mysql-connector-java-8.0.30.jar

   # 将上述的jar包放置到FLINK_HOME/lib/目录下，启动flink
   flink-1.18.1/bin/start-cluster.sh
   ```
4. 进入flink sql创建任务
   ```bash
   cd flink-1.18.1/bin
   ./sql-client.sh

   # 设置checkpoints
   SET execution.checkpointing.interval = 3s;

   CREATE TABLE source_test (
     user_id INT,
     user_name STRING,
     PRIMARY KEY (user_id) NOT ENFORCED
   ) WITH (
      'connector' = 'mysql-cdc',
      'hostname' = '192.168.0.1',
      'port' = '3306',
      'username' = 'flink',
      'password' = '123456',
      'database-name' = 'mydb',
      'table-name' = 'source_test'
   );

   CREATE TABLE sink_test (
     user_id INT,
     user_name STRING,
     PRIMARY KEY (user_id) NOT ENFORCED
   ) WITH (
      'connector' = 'jdbc',
      'url' = 'jdbc:mysql://192.168.0.1:3306/flink_sink',
      'driver' = 'com.mysql.cj.jdbc.Driver',
      'username' = 'flink',
      'password' = '123456',
      'table-name' = 'sink_test'
   );

   CREATE TABLE sink_test_second (
     user_id INT,
     user_name STRING,
     PRIMARY KEY (user_id) NOT ENFORCED
   ) WITH (
      'connector' = 'jdbc',
      'url' = 'jdbc:mysql://192.168.0.1:3306/flink_sink_second',
      'username' = 'flink',
      'password' = '123456',
      'table-name' = 'sink_test'
   );

   # 创建任务
   insert into sink_test select * from source_test;
   insert into sink_test_second select * from source_test;
   ```
5. 同步至PG
   ```bash
   # PG中创建表
   CREATE TABLE sink_test (
     user_id serial NOT NULL PRIMARY KEY,
     user_name VARCHAR(255) NOT NULL
   );

   # Flink SQL中创建表
   CREATE TABLE sink_test_pg (
     user_id INT,
     user_name STRING,
     PRIMARY KEY (user_id) NOT ENFORCED
   ) WITH (
      'connector' = 'jdbc',
      'url' = 'jdbc:postgresql://192.168.0.1:5432/mydb?sslmode=disable',
      'username' = 'flink',
      'password' = '123456',
      'table-name' = 'sink_test'
   );

   # 新建任务，插入数据
   insert into sink_test_pg select * from source_test;
   ```
---
### 启动sql客户端的时候使用初始化脚本
```bash
cat > init.sql << EOF
SET execution.runtime-mode=streaming;

SET parallelism.default=1;

SET table.exec.state.ttl=1000;

SET execution.checkpointing.interval = 3s;

CREATE DATABASE mydb;

CREATE TABLE source_test (
  user_id INT,
  user_name STRING,
  PRIMARY KEY (user_id) NOT ENFORCED
) WITH (
   'connector' = 'mysql-cdc',
   'hostname' = '192.168.0.1',
   'port' = '3306',
   'username' = 'flink',
   'password' = '123456',
   'database-name' = 'mydb',
   'table-name' = 'source_test'
);
EOF

# 使用初始化脚本启动
## embedded:内嵌模式
## -i ../conf/sql-client-init.sql：指定初始化配置文件
./sql-client.sh embedded -i ../conf/init.sql
```
---
### Flink数据类型映射
|MySQL Type|PostgreSQL Type|Flink SQL Type|
|-|-|-|
|TINYINT||TINYINIT|
|SMALLINT,<br>TINYINT UNSIGNED|SMALLINT,<br>INT2,<br>SMALLSERIAL,<br>SERIAL2|SMALLINT|
|INT,<br>MEDIUMINT,<br>SMALLINT UNSIGNED|INTEGER,<br>SERIAL|INT|
|BIGINT,<br>INT UNSIGNED|BIGINT,<br>BIGSERIAL|BIGINT|
|BIGINT UNSIGNED||DECIMAL(20,0)|
|FLOAT|REAL,<br>FLOAT4|FLOAT|
|DOUBLE,<br>DOUBLE PRECISION|FLOAT8,<br>DOUBLE PRECISION|DOUBLE|
|NUMBERIC(p, s),<br>DECIMAL(p, s)|NUMBERIC(p, s),<br>DECIMAL(p, s)|DECIMAL(p, s)|
|BOOLEAN,<br>TINYINT(1)|BOOLEAN|BOOLEAN|
|DATE|DATE|DATE|
|TIME[§]|TIME[§][WITHOUT TIMEZONE]|TIME[§][WITHOUT TIMEZONE]|
|DATETIME[§]|TIMESTAMP[§][WITHOUT TIMZONE]|TIMESTAMP[§][WITHOUT TIMZONE]|
|CHAR(n),<br>VARCHAR(n),<br>TEXT|CHAR(n),<br>CHARACTER(n)<br>VARCHAR(n),<br>CHARACTER VARYING(n),<br>TEXT|STRING|
|BINARY,<br>VARBINARY,<br>BLOB|BYTEA|BYTES|
||ARRAY|ARRAY|
### 参考信息
- [基于Flink CDC实时同步数据（MySQL到MySQL）](https://devpress.csdn.net/big-data/6475f895762a09416a07f488.html#devmenu3)
- [Flink数据类型映射大全](https://blog.csdn.net/karezi/article/details/123885884)