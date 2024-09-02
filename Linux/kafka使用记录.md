#kafka 使用记录
### kafka集群部署
1. 修改server.properties文件
   - 每个kafka实例设置不同的broker.id
   - listeners必须设置监听的IP地址，否则kafka会尝试使用主机名连接其他kafka实例
   - 启用topic删除：auto.create.topics.enable=true
   ```bash
   cat > server.properties <<EOF
   broker.id=2
   listeners=PLAINTEXT://172.16.84.208:9092
   num.network.threads=3
   num.io.threads=8
   socket.send.buffer.bytes=102400
   socket.receive.buffer.bytes=102400
   socket.request.max.bytes=104857600
   log.dirs=/tmp/kafka-logs
   num.partitions=1
   num.recovery.threads.per.data.dir=1
   offsets.topic.replication.factor=1
   transaction.state.log.replication.factor=1
   transaction.state.log.min.isr=1
   log.retention.hours=168
   log.segment.bytes=1073741824
   log.retention.check.interval.ms=300000
   zookeeper.connect=172.16.84.206:2181,172.16.84.207:2181,172.16.84.208:2181
   zookeeper.connection.timeout.ms=18000
   group.initial.rebalance.delay.ms=0
   auto.create.topics.enable=true
   EOF
   ```

### 查看消费数据
1. 查看所有组：
   ```bash
   ./kafka-consumer-groups.sh --bootstrap-server kafka-1.default.svc.cluster.local:9092 --list
   ```
2. 查看消费情况：
   ```bash
   ./kafka-consumer-groups.sh --bootstrap-server kafka-1.default.svc.cluster.local:9092 --group usercenter --describe
   - 参数解释：
   --describe  显示详细信息
   --bootstrap-server 指定kafka连接地址
   --group 指定组
   注意：--group指定的组必须存在才行！可以用上面的--list命令来查看
   ```
3. 删除消费组：
   ```bash
   ./kafka-consumer-groups.sh --bootstrap-server kafka-1.default.svc.cluster.local:9092 --group usercenter --delete 
   ```
4. 重置消费者组的偏移量，到最新的偏移量（需要先把消费者停掉）：
   ```bash
   ./kafka-consumer-groups.sh --bootstrap-server kafka-1.default.svc.cluster.local:9092 --group usercenter --topic topic1 --to-latest --reset-offsets --execute
   ```
5. 查看指定的消费者组里有哪些成员
   ```bash
   kafka-consumer-groups.sh --bootstrap-server kafka-1.default.svc.cluster.local:90922 --group CountryCounter --describe --members
   ```
6. 查看所有的消费者组里有哪些成员
   ```bash
   kafka-consumer-groups.sh --bootstrap-server kafka-1.default.svc.cluster.local:9092 --all-groups --describe --members
   ```
### 修改topic的保留时间，修改保留大小
```bash
./kafka-configs.sh --alter --zookeeper 192.168.X.X:2281 --entity-type topics --entity-name test1 --add-config retention.ms=864000000
./kafka-configs.sh --alter --zookeeper 192.168.X.X:2281 --entity-type topics --entity-name test1 --add-config retention.bytes=32212254720
```
### 修改topic的partitions
```bash
./kafka-topics.sh --zookeeper vlnx111122:2181 --alter --topic test --partitions 6
```
### 扩容、删除机器
只要配置zookeeper.connect为要加入的集群，再启动Kafka进程，就可以让新的机器加入到Kafka集群。但是新的机器只针对新的Topic才会起作用，在之前就已经存在的Topic的分区，不会自动的分配到新增加的物理机中。为了使新增加的机器可以分担系统压力，必须进行消息数据迁移。Kafka提供了kafka-reassign-partitions.sh进行数据迁移。

这个脚本提供3个命令：

--generate: 根据给予的Topic列表和Broker列表生成迁移计划。generate并不会真正进行消息迁移，而是将消息迁移计划计算出来，供execute命令使用。
--execute: 根据给予的消息迁移计划进行迁移。
--verify: 检查消息是否已经迁移完成。
示例
topic为test目前在broker id为1,2,3的机器上，现又添加了两台机器，broker id为4,5，现在想要将压力平均分散到这5台机器上。
- 手动生成一个json文件topic.json
  ```bash
  cat > topic.json <<EOF
  { 
    "topics": [
        {"topic": "test"}
    ],
    "version": 1
  }
  EOF
  ```
- 调用--generate生成迁移计划，将test扩充到所有机器上
  ```bash
  ./kafka-reassign-partitions.sh --zookeeper vlnx111122:2181 --topics-to-move-json-file topic.json  --broker-list  "1,2,3,4,5"  --generate
  ```
- 生成类似于下方的结果；Current partition replica assignment表示当前的消息存储状况。Proposed partition reassignment configuration表示迁移后的消息存储状况。
将迁移后的json存入一个文件reassignment.json，供--execute命令使用。
  ```bash
  Current partition replica assignment
  {"version":1,
   "partitions":[....]
  }
  Proposed partition reassignment configuration
  {"version":1,
   "partitions":[.....]
  }
  ```
- 执行--execute进行扩容。
  ```bash
  ./kafka-reassign-partitions.sh --zookeeper vlnx111122:2181 --reassignment-json-file reassignment.json --execute
  Current partition replica assignment
  ... 
  Save this to use as the --reassignment-json-file option during rollback
  ...
  ```
- 使用--verify查看进度
  ```bash
  ./kafka-reassign-partitions.sh --zookeeper vlnx111122:2181 --reassignment-json-file reassignment.json --verify
  ```



 ./kafka-configs.sh --bootstrap-server 10.111.212.241:9092 --alter --entity-type topics --entity-name k8s02_run --add-config retention.bytes=10737418240
---
### 常用参数说明
|参数|说明|
|-|-|
|segment.bytes=104857600|单个日志文件大小，默认1G|
|delete.retention.ms=86400000|对于压缩日志保留的最长时间，也是客户端消费消息的最长时间，与retention.ms的区别在于一个控制未压缩数据，一个控制压缩后的数据|
|retention.ms=86400000|如果使用“delete”的retention策略，这项配置就是指删除日志前日志保存的时间|
|cleanup.policy=delete|默认方式 delete 将会丢弃旧的部分 compact 将会进行日志压缩|
|compression.type=producer|压缩类型，此配置接受标准压缩编码 gzip, snappy, lz4 ，另外接受 uncompressed 相当于不压缩， producer 意味着压缩类型由producer指定|
---
## 参考连接
- [kafka重新分配partition](https://wzktravel.github.io/2015/12/31/kafka-reassign/)
- [kafka查看消费数据](https://cloud.tencent.com/developer/article/1589121)
- [kafka怎么设置topic数据保留时间](https://forum.huawei.com/enterprise/zh/thread/580942611450052608)
- [kafka 修改topic partitions](http://blog.51yip.com/hadoop/2131.html)