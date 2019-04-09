# 构建Config Servers

# 构建副本集群

# 添加分片

mongodb key file 文件生成
https://docs.mongodb.com/v3.4/tutorial/enforce-keyfile-access-control-in-existing-replica-set/
openssl rand -base64 741 > mongodb-keyfile
chmod 600 mongodb-keyfile
chown mongod.mongod mongodb-keyfile
