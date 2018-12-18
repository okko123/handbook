基于CentOS Linux release 7.4.1708 (Core) 的环境下，MongoDB ops Manager监控系统部署
===
## 安装MongoDB
```bash
#使用预编译二进制包安装
wget https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-3.6.9.tgz
tar xf mongodb-linux-x86_64-3.6.9.tgz
mv mongodb-linux-x86_64-3.6.9 /usr/local/mongodb-3.6.9
#配置MongoDB的配置文件
cat > /usr/local/mongodb-3.6.9/conf/mongodb.conf <<EOF
systemLog:
 destination: file
 path: "/data/logs/mongodb/mongodb-shard.log"
 logAppend: true
 logRotate: rename

net:
 port: 27017
 maxIncomingConnections: 65536
 ipv6: false

processManagement:
 fork: true
 pidFilePath: /var/run/mongodb/mongodb-shard.pid

storage:
 dbPath: "/data/mongodb-shard"
 indexBuildRetry: false
 directoryPerDB: true
 engine: "wiredTiger"
 wiredTiger:
  engineConfig:
   cacheSizeGB: "1"
   journalCompressor: "zlib"
   directoryForIndexes: true
  collectionConfig:
   blockCompressor: "zlib"
EOF
/usr/local/mongodb-3.6.9/bin/mongod -c /usr/local/mongodb-3.6.9/conf/mongodb.conf
#使用rpm包安装
wget
```
## 安装MongoDB ops Manager
```bash
wget https://downloads.mongodb.com/on-prem-mms/rpm/mongodb-mms-3.6.9.47301.20181030T1718Z-1.x86_64.rpm
rpm -ivh mongodb-mms-3.6.9.47301.20181030T1718Z-1.x86_64.rpm
```
## 修改ops的配置文件
```bash
vim /opt/mongodb/mms/conf/conf-mms.properties
mongo.mongoUri=mongodb://IP:PORT/?maxPoolSize=150
mongo.ssl=false
#启动ops
systemctl start mongodb-mms
#
```
