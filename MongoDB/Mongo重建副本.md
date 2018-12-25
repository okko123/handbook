Mongo重建副本
===
## 当前副本集结构
|服务器|角色|
|----|----|
|Server-A|mongod-shared|
|Server-A|mongod-arbiter|
|Server-B|mongod-shared|
|Server-B|mongod-arbiter|
|Server-C|mongod-shared|
|Server-C|mongod-arbiter|
- 每个服务上启动1个数据实例与1个仲裁实例，共6个投票成员。当复制集内存活的成员数量不足大多数的时，整个复制集将无法选举出Primary，复制集将无法提供写服务，处于只读状态。
- 对于大多数的定义：假设复制集内投票成员数量为N，则大多数为 N/2 + 1。对于当前例子中。N=6，容忍失败数为6-（6/2+1）=2
- 当Server-C宕机后，当前集群损失2个投票节点，此时再损失任何一个投票节点，会导致复制集进入只读状态
- 由于AWS的存储优化实例的实例存储空间，在关机后会抹除。当AWS的实例宕机后，且执行重启命令失败后，只能关机再启动，在这种情况下需要重建mongo的数据

## 假设Server-C宕机后，恢复步骤：
- 重启Server-C，重建目录，启动mongod-arbiter，使得集群的投票成员数量由4，提升到5
```bash
/usr/local/mongodb/bin/mongod -f /usr/local/mongodb/conf/mongo-arbiter.conf
```
- 登陆正常的副本节点上，关闭mongod-shared实例，打包本地保存数据，然后发送到Server-C上。（必须保持存活的投票成员有4个）。启动mongod-shared实例
```bash
/etc/init.d/mongodb-shard stop
tar -cf shard.tar /data/mongodb-shard
/etc/init.d/mongodb-shard start
rsync -vlDrP shard.tar Server-C
```
- 登陆Server-C，解压数据并移动数据到mongod-shared的数据目录下，启动mongod实例。mongod会自动与其他节点通信，并恢复
```bash
tar xf shard.tar
mv mongodb-shard /data/mongodb-shard
/etc/init.d/mongodb-shard start
```
- 登陆副本集的任意节点，使用rs.status()检查每个节点的状态

## 资料
- Secondary初次同步数据时，会先进行init sync，从Primary（或其他数据更新的Secondary）同步全量数据（这里的数据为解压后的数据），然后不断通过tailable cursor从Primary的local.oplog.rs集合里查询最新的oplog并应用到自身。
- init sync过程包含如下步骤:
  - T1时间，从Primary同步所有数据库的数据（local除外），通过listDatabases + listCollections + cloneCollection敏命令组合完成，假设T2时间完成所有操作。
  - 从Primary应用[T1-T2]时间段内的所有oplog，可能部分操作已经包含在步骤1，但由于oplog的幂等性，可重复应用。
  - 根据Primary各集合的index设置，在Secondary上为相应集合创建index。（每个集合_id的index已在步骤1中完成）。
  - oplog集合的大小应根据DB规模及应用写入需求合理配置，配置得太大，会造成存储空间的浪费；配置得太小，可能造成Secondary的init sync一直无法成功。比如在步骤1里由于DB数据太多、并且oplog配置太小，导致oplog不足以存储[T1, T2]时间内的所有oplog，这就Secondary无法从Primary上同步完整的数据集。
- [参考文章-1](http://www.mongoing.com/archives/2155)
