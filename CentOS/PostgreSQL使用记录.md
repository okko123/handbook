## PostgreSQL使用记录

```bash
# 登录数据库，切换posgres用户
su - postgres
psql

# 创建用户dbuser（刚才创建的是Linux系统用户），并设置密码。
CREATE USER dbuser WITH PASSWORD 'password';

# 创建数据库，这里为exampledb，并指定所有者为dbuser
CREATE DATABASE exampledb OWNER dbuser;

# 将exampledb数据库的所有权限都赋予dbuser，否则dbuser只能登录控制台，没有任何数据库操作权限。
GRANT ALL PRIVILEGES ON DATABASE testdb TO test;
```
### 修改postgresql配置，配置完成后重启pg
- 监听的IP，默认监听127.0.0.1
  ```bash
  vim /var/lib/pgsql/12/data/postgresql.conf
  listen_addresses = '192.168.1.1'
  ```
- 允许网络连接登录，编辑/etc/postgresql/x.x/main/pg_hba.conf，添加
  ```bash
  vim /etc/postgresql/12/main/pg_hba.conf
  host    all             all             0.0.0.0/0               md5
  ```
### 控制台命令
\h：查看SQL命令的解释，比如\h select。
\?：查看psql命令列表。
\l：列出所有数据库。
\c [database_name]：连接其他数据库。
\d：列出当前数据库的所有表格。
\d [table_name]：列出某一张表格的结构。
\du：列出所有用户。
\e：打开文本编辑器。
\conninfo：列出当前数据库和连接的信息。