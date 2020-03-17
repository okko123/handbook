## MongoDB修改Oplog大小
### 使用的mongo版本未3.4

* 以节点模式重启节点，
  ```bash
  #关闭节点
  /etc/init.d/mongodb stop
  #或者登录mongo实例后执行
  db.shutdownServer()

  #以standalone的方式用另外的端口（确保端口空闲）启动
  mongod --port 1988 --dbpath /data/mongodb/demo-data/
  ```
* 备份当前的oplog[可选]
  ```bash
  mongodump --db local --collection 'oplog.rs' --port 1988
  ```
* 登录mongo实例，以新大小重建oplog
  ```bash
  use local
  db = db.getSiblingDB('local')
  db.temp.drop()
  #
  db.temp.save( db.oplog.rs.find( { }, { ts: 1, h: 1 } ).sort( {$natural : -1} ).limit(1).next() )
  db.temp.find()
  #删除已存在的Oplog
  db = db.getSiblingDB('local')
  db.oplog.rs.drop()
  #建立新的Oplog
  db.runCommand( { create: "oplog.rs", capped: true, size: (2 * 1024 * 1024 * 1024) } )
  #将就Oplog的最后的条目插入新的Oplog中
  db.oplog.rs.save( db.temp.findOne() )
  db.oplog.rs.find()
  ```
* 重启节点
  ```bash
  /etc/init.d/mongo start
  ```
* 登录mongo实例，查看Oplog的大小
  ```bash
  db.printReplicationInfo()
  ```