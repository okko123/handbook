## flink 使用笔记
---
1. 安装，flink-1.18版本
```bash
# 下载二进制包
wget https://dlcdn.apache.org/flink/flink-1.18.1/flink-1.18.1-bin-scala_2.12.tgz

cat > flink-conf.yaml <<EOF
env.java.opts.all: --add-exports=java.base/sun.net.util=ALL-UNNAMED --add-exports=java.rmi/sun.rmi.registry=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED --add-exports=java.security.jgss/sun.security.krb5=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.net=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED --add-opens=java.base/sun.nio.ch=ALL-UNNAMED --add-opens=java.base/java.lang.reflect=ALL-UNNAMED --add-opens=java.base/java.text=ALL-UNNAMED --add-opens=java.base/java.time=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.util.concurrent=ALL-UNNAMED --add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED --add-opens=java.base/java.util.concurrent.locks=ALL-UNNAMED
jobmanager.rpc.address: localhost
jobmanager.rpc.port: 6123
jobmanager.bind-host: localhost
jobmanager.memory.process.size: 2600m
taskmanager.bind-host: localhost
taskmanager.host: localhost
taskmanager.memory.process.size: 2728m
taskmanager.memory.flink.size: 2280m

taskmanager.memory.network.min: 1mb
taskmanager.memory.network.max: 256mb

taskmanager.numberOfTaskSlots: 40
parallelism.default: 2
jobmanager.execution.failover-strategy: region
rest.port: 8081
rest.address: 192.168.0.238
rest.bind-address: 192.168.0.238
EOF

# 安装对应的库；需要安装kafka、doris库
cat > list.txt <<EOF
https://repo1.maven.org/maven2/org/apache/kafka/kafka-clients/3.8.0/kafka-clients-3.8.0.jar
https://repo1.maven.org/maven2/org/apache/flink/flink-sql-connector-kafka/3.2.0-1.18/flink-sql-connector-kafka-3.2.0-1.18.jar
https://repo.maven.apache.org/maven2/org/apache/doris/flink-doris-connector-1.18/1.6.2/flink-doris-connector-1.18-1.6.2.jar
https://repo1.maven.org/maven2/org/apache/flink/flink-connector-jdbc/3.2.0-1.18/flink-connector-jdbc-3.2.0-1.18.jar
EOF

wget -i list.txt

mv *.jar flink-1.18/lib

# 启动flink
bin/start-cluster.sh
```
2. 通过Flink SQL 创建Kafka表
```bash
./bin/sql-client.sh embedded

# 创建表
CREATE TABLE gc_log (
    `source` STRING,
    `message` STRING
) WITH (
    'connector' = 'kafka', 
    'topic' = 'gc_log', 
    'properties.bootstrap.servers' = '192.168.0165:9092, 192.168.0166:9092, 192.168.0167:9092', 
    'properties.group.id' = 'flinkGroup',
    'format' = 'json',
    'scan.startup.mode' = 'latest-offset',
    'properties.auto.offset.reset' = 'none'
);

# 执行查询验证
select * from gc_log;

create table doris_gc_log (
    `dt` TIMESTAMP,
    `project` STRING,
    `message` STRING
)
WITH (
    'connector' = 'doris',
    'fenodes' = '192.168.0.240:8030',
    'table.identifier' = 'log_db.kgc_log',
    'username' = 'root',
    'password' = '123456',
    'sink.label-prefix' = 'doris_label_01'
);

# 提交，插入数据，从Kafka表中读取数据插入到Doris中
insert into doris_gc_log
select 
CURRENT_TIMESTAMP as dt, 
SPLIT_INDEX(source, '/', 7) as project, 
REGEXP_REPLACE(`message`,  '\r|\n|\t', '') as message
from gc_log;
```
---
### Flink TaskManager 内存模型详解
- Total Process Memory (进程总内存) 包含了 Flink 应用程序使用的全部内存资源
  - Total Flink Memory (Flink应用使用的内存)
  - 运行 Flink JVM 使用的内存
    - JVM Metaspace
    - JVM Overhead-
- Total Flink Memory 内部分成了：堆内内存 + 堆外内存：
  - 堆内内存包括两部分
    - FreameWork Heap Memory (框架堆内存)
    - Task Heap Memory (任务堆内存)
- 堆外内存包含四部分
  - Managed Memory (托管内存)
  - Framework Off-Heap Memory (框架堆外内存)
  - Task Off-Heap Memory (任务堆外内存)
  - Network Memory (网络内存)

> 下面就按照上图中编号顺序分别介绍一下这些内存的作用以及如何配置![](img/flink-1.png)
---
### 堆内内存
1. Framework Heap
   > 含义描述: Flink 框架本身占用的内存,这部分的内存一般情况下是不需要修改的,在特殊的情况下可能需要调整.
     ```bash
     参数设置
     taskmanager.memory.framework.heap.size：堆内部分(Framework Heap)，默认值 128M；
     taskmanager.memory.framework.off-heap.size：堆外部分(Framework Off-Heap)，以直接内存形式分配，默认     值 128M。
     ```
2. Task Heap
   > 含义描述: 用于 Flink 应用的算子及用户代码占用的内存。
     ```bash
     参数设置
     taskmanager.memory.task.heap.size：堆内部分(Task Heap)，无默认值，一般不建议设置，会自动用 Flink 总内存减去框架、托管、网络三部分的内存推算得出。
     taskmanager.memory.task.off-heap.size：堆外部分(Task Off-Heap)，以直接内存形式分配，默认值为 0，即不使用。如果代码中需要调用 Native Method 并分配堆外内存，可以指定该参数。一般不使用，所以大多数时候可以保持     0。
     ```
### 堆外内存
1. Managed Memory
   > 含义描述: 纯堆外内存，由 MemoryManager 管理，用于中间结果缓存、排序、哈希表等，以及 RocksDB 状态后端。可见，RocksDB消耗的内存可以由用户显式控制了，不再像旧版本一样难以预测和调节。
     ```bash
     参数设置
     taskmanager.memory.managed.fraction：托管内存占 Flink 总内存 taskmanager.memory.flink.size 的比例，默认值 0.4；
     taskmanager.memory.managed.size：托管内存的大小，无默认值，一般也不指定，而是依照上述比例来推定，更加灵活。
     ```
2. Framework Off-Heap
   > 含义：用于 Flink 框架的堆外内存（直接内存或本地内存）（进阶配置）
```bash
taskmanager.memory.framework.off-heap.size
```
3. Task Off-Heap
   > 含义：用于 Flink 应用的算计及用户代码的堆外内存（直接内存或本地内存）
```bash
taskmanager.memory.task.off-heap.size
```
4. Network
   > 含义描述: Network Memory 使用的是 Directory memory，在 Task 与 Task之间进行数据交换时（shuffle），需要将数据缓存下来，缓存能够使用的内存大小就是这个 Network Memory。它由是三个参数决定：
     ```bash
     参数设置
     taskmanager.memory.network.min：网络缓存的最小值，默认 64MB；
     taskmanager.memory.network.max：网络缓存的最大值，默认 1GB；
     taskmanager.memory.network.fraction：网络缓存占 Flink 总内存 taskmanager.memory.flink.size 的比例，默认值 0.1。若根据此比例算出的内存量比最小值小或比最大值大，就会限制到最小值或者最大值。
     ```
---
1. JVM Metaspace
   > 含义描述: 从 JDK 8 开始，JVM 把永久代拿掉了。类的一些元数据放在叫做 Metaspace 的 Native Memory 中。在 Flink 中的 JVM Metaspace Memory 也一样，它配置的是 Task Manager JVM 的元空间内存大小。
```bash
参数设置
taskmanager.memory.jvm-metaspace.size：默认值 256MB。
```
2. JVM Overhead
   > 含义描述: 保留给 JVM 其他的内存开销。例如：Thread Stack、code cache、GC 回收空间等等。和 Network Memory的配置方法类似。它也由三个配置决定
```bash
参数设置
taskmanager.memory.jvm-overhead.min：JVM 额外开销的最小值，默认 192MB；
taskmanager.memory.jvm-overhead.max：JVM 额外开销的最大值，默认 1GB；
taskmanager.memory.jvm-overhead.fraction：JVM 额外开销占 TM 进程总内存
taskmanager.memory.process.size（注意不是 Flink 总内存）的比例，默认值 0.1。若根据此比例算出的内存量比最小值小或比最大值大，就会限制到最小值或者最大值。
```
---


flink stop -m 127.0.0.1:8081 -s save_point_dir job_id 
flink cancel -m 127.0.0.1:8081 -s save_point_dir job_id



两者的区别
- cancel() 调用
立即调用作业算子的 cancel() 方法，以尽快取消它们。如果算子在接到 cancel() 调用后没有停止，Flink 将开始定期中断算子线程的执行，直到所有算子停止为止。
- stop() 调用，是更优雅的停止正在运行流作业的方式。stop() 仅适用于 source 实现了StoppableFunction 接口的作业。当用户请求停止作业时，作业的所有 source 都将接收 stop() 方法调用。直到所有 source 正常关闭时，作业才会正常结束。这种方式，使作业正常处理完所有作业。