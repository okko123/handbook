## 构建Config Servers

## 构建副本集群

## 添加分片

mongodb key file 文件生成
https://docs.mongodb.com/v3.4/tutorial/enforce-keyfile-access-control-in-existing-replica-set/
openssl rand -base64 741 > mongodb-keyfile
chmod 600 mongodb-keyfile
chown mongod.mongod mongodb-keyfile


mongos缓存配置
https://bbs.huaweicloud.com/blogs/51b45c8ef21a11e8bd5a7ca23e93a891


MongoDB副本集配置系列七：MongoDB oplog详解
1：oplog简介

oplog是local库下的一个固定集合，Secondary就是通过查看Primary 的oplog这个集合来进行复制的。每个节点都有oplog，记录这从主节点复制过来的信息，这样每个成员都可以作为同步源给其他节点。

 

2：副本集数据同步的过程

副本集中数据同步的详细过程：Primary节点写入数据，Secondary通过读取Primary的oplog得到复制信息，开始复制数据并且将复制信息写入到自己的oplog。如果某个操作失败（只有当同步源的数据损坏或者数据与主节点不一致时才可能发生），则备份节点停止从当前数据源复制数据。如果某个备份节点由于某些原因挂掉了，当重新启动后，就会自动从oplog的最后一个操作开始同步，同步完成后，将信息写入自己的oplog，由于复制操作是先复制数据，复制完成后再写入oplog，有可能相同的操作会同步两份，不过MongoDB在设计之初就考虑到这个问题，将oplog的同一个操作执行多次，与执行一次的效果是一样的。

3：oplog的增长速度

oplog是固定大小，他只能保存特定数量的操作日志，通常oplog使用空间的增长速度跟系统处理写请求的速度相当，如果主节点上每分钟处理1KB的写入数据，那么oplog每分钟大约也写入1KB数据。如果单次操作影响到了多个文档（比如删除了多个文档或者更新了多个文档）则oplog可能就会有多条操作日志。db.testcoll.remove() 删除了1000000个文档，那么oplog中就会有1000000条操作日志。如果存在大批量的操作，oplog有可能很快就会被写满了。

 

4：oplog注意事项：

local.oplog.rs特殊的集合。用来记录Primary节点的操作。

为了提高复制的效率，复制集中的所有节点之间会相互的心跳检测（ping）。每个节点都可以从其他节点上获取oplog。

oplog中的一条操作。不管执行多少次效果是一样的

5：oplog的大小

第一次启动复制集中的节点时，MongoDB会建立Oplog,会有一个默认的大小，这个大小取决于机器的操作系统

rs.printReplicationInfo()

db.getReplicationInfo()

可以用来查看oplog的状态、大小、存储的时间范围