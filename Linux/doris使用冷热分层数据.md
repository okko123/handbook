### doris使用冷热分层数据
1. 确认fe已经配置以下配置：enable_storage_policy=true
2. 在doris中配置OSS信息
   ```yaml
   # 创建s3配置信息
   CREATE RESOURCE "remote_oss"
   PROPERTIES
   (
       "type" = "s3",
       "s3.endpoint" = "oss-cn-shenzhen-internal.aliyuncs.com",
       "s3.region" = "sz",
       "s3.bucket" = "bucket01",
       "s3.root.path" = "doris_test/",
       "s3.access_key" = "LTAI5tdddddddddddddsp",
       "s3.secret_key" = "Scfhiaddddddddddddddddd7ByZ",
       "s3.connection.maximum" = "50",
       "s3.connection.request.timeout" = "3000",
       "s3.connection.timeout" = "1000"
   );

   # 创建存储策略，控制冷却时间。样例为1天后的数据，转移到oss中
   CREATE STORAGE POLICY test_policy
   PROPERTIES(
       "storage_resource" = "remote_oss",
       "cooldown_ttl" = "1d"
   );

   # 修改表属性 or 创建新表
   ALTER TABLE request_log set ("storage_policy" = "test_policy");

   CREATE TABLE IF NOT EXISTS request_log
   (
       k1 BIGINT,
       k2 LARGEINT,
       v1 VARCHAR(2048)
   )
   UNIQUE KEY(k1)
   DISTRIBUTED BY HASH (k1) BUCKETS 3
   PROPERTIES(
       "storage_policy" = "test_policy"
   );
   ```

### 检查数据，冷数据占用对象大小
1. 方式一： 通过show proc '/backends'可以查看到每个be上传到对象的大小，RemoteUsedCapacity项，此方式略有延迟。
2. 方式二： 通过show tablets from tableName可以查看到表的每个tablet占用的对象大小，RemoteDataSize项。
   ```bash
   show data
   show tablets from tableName
   ```
### 冷数据 Compaction
---
> 在一些场景下会有大量修补数据的需求，在大量补数据的场景下往往需要删除历史数据，删除可以通过delete where实现，Doris 在 Compaction 时会对符合删除条件的数据做物理删除。基于这些场景，冷热分层也必须实现对冷数据进行 Compaction，因此在 Doris 2.0 版本中我们支持了对冷却到对象存储的冷数据进行 Compaction (ColdDataCompaction)的能力，用户可以通过冷数据 Compaction，将分散的冷数据重新组织并压缩成更紧凑的格式，从而减少存储空间的占用，提高存储效率。

> Doris 对于本地副本是各自进行 Compaction，在后续版本中会优化为单副本进行 Compaction。由于冷数据只有一份，因此天然的单副本做 Compaction 是最优秀方案，同时也会简化处理数据冲突的操作。BE 后台线程会定期从冷却的 Tablet 按照一定规则选出 N 个 Tablet 发起 ColdDataCompaction。与数据冷却流程类似，只有 CooldownReplica 能执行该 Tablet 的 ColdDataCompaction。Compaction下刷数据时每积累一定大小(默认5MB)的数据，就会上传一个 Part 到对象，而不会占用大量本地存储空间。Compaction 完成后，CooldownReplica 将冷却数据的元数据更新到对象存储，其他 Replica 只需从对象存储同步元数据，从而大量减少对象存储的 IO 和节点自身的 CPU 开销。
### 使用Routine Load 导入方式持续消费 Kafka Topic 中的数据
- columns字段必须与json path的顺序一致，否则会出现导入出错

- 处理数据，必要在column里出现，然后再处理。
```bash
1. 需要在column里配置source，才能使用split_part对source的内容进行切分
COLUMNS(callStack, dt=now(3),source,project=split_part(source,'/', 8))
2. 同时需要在jsonpaths里配置source，给source字段填充内容
"jsonpaths"="[\"$.source\"]"
```
### 其他
---
1. delete table 或者 truncate table后，需要等待一段时间，doris会自动回收oss的占用空间
2. 修改副本数
   ```sql
   ## 注意
   # 1. default 前缀的属性表示修改表的默认副本分布。这种修改不会修改表的当前实际副本分布，而只影   响分区表上新建分区的副本分布。
   # 2. 对于非分区表，修改不带 default 前缀的副本分布属性，会同时修改表的默认副本分布和实际副本分   布。即修改后，通过 show create table 和 show partitions from tbl 语句可以看到副本分布数据都   被修改了。
   # 3. 对于分区表，表的实际副本分布是分区级别的，即每个分区有自己的副本分布，可以通过 show    partitions from tbl 语句查看。如果想修改实际副本分布，请参阅 ALTER TABLE PARTITION。
   ALTER TABLE example_db.mysql_table SET ("replication_num" = "2");
   ALTER TABLE example_db.mysql_table SET ("default.replication_num" = "2");
   ALTER TABLE example_db.mysql_table SET ("dynamic_partition.replication_allocation" = "tag.location.default: 1");

   # 修改分区副本数
   ALTER TABLE example_db.my_table MODIFY PARTITION p1 SET("replication_num"="1");

   # 批量修改指定分区
   ALTER TABLE example_db.my_table MODIFY PARTITION (p1, p2, p4) SET   ("replication_num"="1");

   # 批量修改所有分区
   ALTER TABLE example_db.my_table MODIFY PARTITION (*) SET("storage_medium"="HDD");
   ```
3. 展示表的分区信息；包括表大小，副本数量
   ```bash
    SHOW [TEMPORARY] PARTITIONS FROM [db_name.]table_name [WHERE] [ORDER BY] [LIMIT];
    show partitions from db.table

    # 查看副本状态
    admin show replica status from db.table

    # 查看副本size分布状态
    admin show replica distribution from db.table

   ```
4. 调整fe的日志信息。doris的版本为2.0.3
   > 默认配置下，fe的sys_log设置为info级别，但在fe的syslog中，会写出大量的DEBUG日志。将配置文件中的sys_log_level调整为WARN后不生效，仍然写出大量的DEBUG日志。需要注释sys_log_verbose_modules配置，然后重启FE生效

   > 配置syslog的大小和文件数量
   ```bash
   log_roll_size_mb = 1024
   sys_log_dir = /data/doris_data/FE/syslog
   sys_log_roll_num = 10
   # 需要注释，否则会在syslog中写出大量的DEBUG日志
   sys_log_verbose_modules = org.apache.doris
   ```
5. 创建、查看、修改、删除数据迁移策略
   1. 创建数据迁移策略
      > 冷热分层创建策略，必须先创建resource，然后创建迁移策略时候关联创建的resource名

      > 当前不支持删除drop数据迁移策略，防止数据被迁移后。策略被删除了，系统无法找回数据

      ```bash
      # 指定数据冷却时间创建数据迁移策略
      CREATE STORAGE POLICY testPolicy
      PROPERTIES(
        "storage_resource" = "s3",
        "cooldown_datetime" = "2022-06-08 00:00:00"
      );

      # 指定热数据持续时间创建数据迁移策略
      CREATE STORAGE POLICY testPolicy
      PROPERTIES(
        "storage_resource" = "s3",
        "cooldown_ttl" = "1d"
      );

      相关参数如下：
      storage_resource：创建的storage resource名称
      cooldown_datetime：迁移数据的时间点
      cooldown_ttl：迁移数据距离当前时间的倒计时，单位s。与cooldown_datetime二选一即可
      ```
   2. 修改一个已有的冷热分层迁移策略。仅 root 或 admin 用户可以修改资源。
      ```bash
      # ALTER STORAGE POLICY  'policy_name' PROPERTIES ("key"="value", ...);
      alter storage policy 'test_policy' properties ("cooldown_ttl"=2d);
      ```
    3. 删除存储策略
       ```bash
       drop storage policy NAME;
       ```
    4. 展示数据迁移策略
       ```bash
       show storage policy;
       ```
    5. 关闭数据漂移、自平衡
       ```bash
       admin set frontend config("disable_balance" = "false");
       admin set frontend config("disable_colocate_balance" = "false");
       admin set frontend config("disable_tablet_scheduler" = "false");
      ```
---
6. 创建、查看、修改、删除资源
   1. 用于创建资源。仅 root 或 admin 用户可以创建资源。目前支持 Spark, ODBC, S3, JDBC, HDFS, HMS, ES 外部资源。 将来其他外部资源可能会加入到 Doris 中使用，如 Spark/GPU 用于查询，HDFS/S3 用于外部存储，MapReduce 用于 ETL 等。
      ```bash
      # CREATE [EXTERNAL] RESOURCE "resource_name" PROPERTIES ("key"="value", ...);
      CREATE RESOURCE "remote_s3"
      PROPERTIES
      (
         "type" = "s3",
         "s3.endpoint" = "bj.s3.com",
         "s3.region" = "bj",
         "s3.access_key" = "bbb",
         "s3.secret_key" = "aaaa",
         -- required by cooldown
         "s3.root.path" = "/path/to/root",
         "s3.bucket" = "test-bucket"
      );
      ```
   2. 用于修改一个已有的资源。仅 root 或 admin 用户可以修改资源。
      ```bash
      ALTER RESOURCE 'resource_name' PROPERTIES ("key"="value", ...);
      ```
   3. 用于删除一个已有的资源。仅 root 或 admin 用户可以删除资源。
      ```bash
      DROP RESOURCE 'resource_name';
      ```
   4. 用于展示用户有使用权限的资源。普通用户仅能展示有使用权限的资源，root 或 admin 用户会展示所有的资源。
      ```bash
      SHOW RESOURCES;
      ```
7. 清理垃圾数据；
   > delete\drop\truncate等操作只是在逻辑上删除了数据，并没有进行物理删除；

   > 数据文件合并完成后，没有物理删除的旧数据
   ```sql
   # 清理所有BE节点的垃圾数据
   admin clean trash
   
   # 清理指定BE节点的垃圾数据
   admin clean trash on ("backendhost1:backendbeatport1","backendhost2:backendbeatport2")
   ```
---
### 参考连接
- [冷热分层](https://doris.apache.org/zh-CN/docs/advanced/cold-hot-separation#%E5%86%B7%E6%95%B0%E6%8D%AE%E7%9A%84%E5%9E%83%E5%9C%BE%E5%9B%9E%E6%94%B6)
- [Apache Doris 冷热分层技术如何实现存储成本降低 70%？](https://blog.csdn.net/SelectDB_Fly/article/details/131109110)
- [ALTER-TABLE-PARTITION修改表分区属性](https://doris.apache.org/zh-CN/docs/sql-manual/sql-reference/Data-Definition-Statements/Alter/ALTER-TABLE-PARTITION)
- [ALTER-TABLE-PROPERTY修改表属性](https://doris.apache.org/zh-CN/docs/sql-manual/sql-reference/Data-Definition-Statements/Alter/ALTER-TABLE-PROPERTY)
---

SHOW PROC '/cluster_balance/cluster_load_stat/location_default/HDD';
SHOW PROC '/cluster_balance/cluster_load_stat/location_default/ssd';

SHOW PROC '/cluster_balance/working_slots';


SHOW PROC '/cluster_balance/running_tablets';


在be的配置中指定ssd介质后，建表的时候默认的storage_media指定HDD，导致数据只能在指定节点上存储，自平衡失效
如果集群只有一种介质比如都是 HDD 或者都是 SSD，最佳实践是不用在 be.conf 中显式指定介质属性。如果遇到上述报错Failed to find enough host with storage medium and tag，一般是因为 be.conf 中只配置了 SSD 的介质，而建表阶段中显式指定了properties {"storage_medium" = "hdd"}；同理如果 be.conf 只配置了 HDD 的介质，而而建表阶段中显式指定了properties {"storage_medium" = "ssd"}也会出现上述错误。解决方案可以修改建表的 properties 参数与配置匹配；或者将 be.conf 中 SSD/HDD 的显式配置去掉即可。
https://doris.apache.org/zh-CN/docs/2.0/faq/install-faq?_highlight=ssd#q7-%E5%85%B3%E4%BA%8E%E6%95%B0%E6%8D%AE%E7%9B%AE%E5%BD%95-ssd-%E5%92%8C-hdd-%E7%9A%84%E9%85%8D%E7%BD%AE%E5%BB%BA%E8%A1%A8%E6%9C%89%E6%97%B6%E5%80%99%E4%BC%9A%E9%81%87%E5%88%B0%E6%8A%A5%E9%94%99failed-to-find-enough-host-with-storage-medium-and-tag

增加FE节点
ALTER SYSTEM ADD FOLLOWER "follower_host:edit_log_port"

删除FE节点
ALTER SYSTEM DROP FOLLOWER "follower_host:edit_log_port"

增加BE节点
ALTER SYSTEM ADD BACKEND "host:heartbeat_port"[,"host:heartbeat_port"...];

删除BE节点
ALTER SYSTEM DECOMMISSION BACKEND "host:heartbeat_port"[,"host:heartbeat_port"...];




show trash

admin clean trash


02  节点故障处理
对于 FE 节点故障，如果无法快速定位故障原因，一般需要保留线程快照和内存快照后重启进程。可以通过如下命令保存FE的线程快照：
jstack 进程ID >> 快照文件名.jstack
通过以下命令保存 FE 的内存快照：
jmap -dump:live,format=b,file=快照文件名.heap 进程ID
在版本升级或一些意外场景下，FE 节点的 image 可能出现元数据异常，并且可能出现异常的元数据被同步到其它 FE 的情况，导致所有 FE 不可工作。一旦发现 image 出现故障，最快的恢复方案是使用 Recovery 模式停止 FE 选举，并使用备份的 image 替换故障的 image。当然，时刻备份 image 并不是容易的事情，鉴于该故障常见于集群升级，我们建议在集群升级的程序中，增加简单的本地 image 备份逻辑，保证每次升级拉起 FE 进程前会保留一份当前最新的 image 数据。
对于 BE 节点故障，如果是进程崩溃，会产生 core 文件，且 minos 会自动拉取进程；如果是任务卡住，则需要通过以下命令保留线程快照后重启进程：
pstack 进程ID >> 快照文件名.pstack