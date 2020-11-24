#kafka 使用记录

### 修改topic的partitions
./kafka-topics.sh --zookeeper vlnx111122:2181 --alter --topic test --partitions 6
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


  ## 参考连接
  - [kafka重新分配partition](https://wzktravel.github.io/2015/12/31/kafka-reassign/)