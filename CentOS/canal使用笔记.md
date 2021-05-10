## canal 使用笔记
安装版本: 1.1.4

架构图
监控2个MySQL实例，将数据同步到rocketmq中
```bash
mysql-1 mysql-2
   |      |
   canal
     |
  rocketmq
```


### 下载canal
wget https://github.com/alibaba/canal/releases/download/canal-1.1.4/canal.deployer-1.1.4.tar.gz
tar xf canal.deployer-1.1.4.tar.gz

- 修改canal主配置文件: canal.properties
  ```bash
  按照实际zk的ip，修改 canal.zkServers = 192.168.1.1:2181,192.168.1.2:2181,192.168.1.3:2181
  # 可选模式 tcp, kafka, RocketMQ
  指定运行模式，canal.serverMode = RocketMQ
  根据需求修改binlog过滤:
  canal.instance.filter.druid.ddl = true
  canal.instance.filter.query.dcl = true
  canal.instance.filter.query.dml = false
  canal.instance.filter.query.ddl = true
  canal.instance.filter.table.error = true
  canal.instance.filter.rows = false
  canal.instance.filter.transaction.entry = true
  配置mq信息: 
  ```
- 增加目标destinations: 10.111.105.41:9876
  在confi文件夹下，创建新文件夹: mkdir member
  复制样例进行修改: cp example/instance.properties member/instance.properties
  修改数据库信息，ip、用户名、密码
  修改mq配置: canal.mq.topic、canal.mq.partition、canal.instance.filter.regex、canal.mq.partitionHash
  注意，canal.mq.partition需要与rocketmq的topic的分片数量一致；关闭tsdb

  ### Canal和Zookeeper对应节点的关系
  ```bash
  /otter/canal:canal的根目录
  /otter/canal/cluster:整个canal server的集群列表
  /otter/canal/destinations:destination的根目录
  /otter/canal/destinations/example/running:服务端当前正在提供服务的running节点
  /otter/canal/destinations/example/cluster:针对某个destination的工作集群列表
  /otter/canal/destinations/example/1001/running:客户端当前正在读取的running节点
  /otter/canal/destinations/example/1001/cluster:针对某个destination的客户端列表
  /otter/canal/destinations/example/1001/cursor:客户端读取的position信息
  ```

### canal HA 模式
canal server实现流程
canal server 要启动某个 canal instance 时都先向 zookeeper 进行一次尝试启动判断 (实现：创建 EPHEMERAL 节点，谁创建成功就允许谁启动）；
创建 zookeeper 节点成功后，对应的 canal server 就启动对应的 canal instance，没有创建成功的 canal instance 就会处于 standby 状态；
一旦 zookeeper 发现 canal server A 创建的节点消失后，立即通知其他的 canal server 再次进行步骤1的操作，重新选出一个 canal server 启动instance；
canal client 每次进行connect时，会首先向 zookeeper 询问当前是谁启动了canal instance，然后和其建立链接，一旦链接不可用，会重新尝试connect。
注意
为了减少对mysql dump的请求，不同server上的instance要求同一时间只能有一个处于running，其他的处于standby状态。

canal client实现流程
canal client 的方式和 canal server 方式类似，也是利用 zookeeper 的抢占EPHEMERAL 节点的方式进行控制
为了保证有序性，一份 instance 同一时间只能由一个 canal client 进行get/ack/rollback操作，否则客户端接收无法保证有序。


watcher 解释 https://www.jianshu.com/p/4c071e963f18
zookeeper节点类型 https://blog.csdn.net/randompeople/article/details/70500076