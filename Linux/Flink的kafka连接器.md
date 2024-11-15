## Flink Kafka SQL Connector
> 元数据列是 SQL 标准的扩展，允许访问数据源本身具有的一些元数据。元数据列由METADATA 关键字标识。例如，我们可以使用元数据列从 Kafka 记录中读取和写入时间戳，用于基于时间的操作（这个时间戳不是数据中的某个时间戳字段，而是数据写入 Kafka 时，Kafka 引擎给这条数据打上的时间戳标记）。connector 和 format 文档列出了每个组件可用的元数据字段。

> 可用元数据；以下连接器元数据可以作为表定义中的元数据列进行访问。

|Key|Data Type|Description|R/W|
|-|-|-|-|
|topic|STRING NOT NULL|Topic name of the Kafka record.|R/W|
|partition|INT NOT NULL|Partition ID of the Kafka record.|R|
|headers|MAP NOT NULL|Headers of the Kafka record as a map of raw bytes.|R/W|
|leader-epoch|INT NULL|Leader epoch of the Kafka record if available.|R|
|offset|BIGINT NOT NULL|Offset of the Kafka record in the partition.|R|
|timestamp|TIMESTAMP_LTZ(3) NOT NULL|Timestamp of the Kafka record.|R/W|
|timestamp-type|STRING NOT NULL|Timestamp type of the Kafka record. Either "NoTimestampType", "CreateTime" (also set when writing metadata), or "LogAppendTime".|R|

```sql
CREATE TABLE t1(
`event_time` TIMESTAMP(3) METADATA FROM 'timestamp',
--列名和元数据名一致可以省略 FROM 'xxxx', VIRTUAL 表示只读
 `partition` BIGINT METADATA VIRTUAL,
 `offset` BIGINT METADATA VIRTUAL,
id int,
ts bigint ,
vc int )
WITH (
 'connector' = 'kafka',
 'properties.bootstrap.servers' = '192.168.58.130:9092',
 'properties.group.id' = 'coreqi',
-- 'earliest-offset', 'latest-offset', 'group-offsets', 'timestamp'
and 'specific-offsets'
 'scan.startup.mode' = 'earliest-offset',
-- fixed 为 flink 实现的分区器，一个并行度只写往 kafka 一个分区
'sink.partitioner' = 'fixed',
 'topic' = 'ws1',
 'format' = 'json'
)

```
---
### 参考信息
1. [FlinkSQL 总结](https://www.cnblogs.com/fanqisoft/p/18008618)