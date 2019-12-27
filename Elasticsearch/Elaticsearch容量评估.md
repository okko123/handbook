## Elasticsearch磁盘容量评估
### 影响阿里云Elasticsearch集群磁盘空间大小的因素：
* 副本数量。至少1个副本。
* 索引开销。通常比源数据大10%（_all等未计算）。
* 操作系统预留。默认操作系统会保留5%的文件系统供用户处理关键流程、系统恢复以及磁盘碎片等。
* ES内部开销。段合并、日志等内部操作，预留20%。
* 安全阈值。通常至少预留15%的安全阈值。
根据以上因素得到最小磁盘总大小 = 源数据大小 * 3.4。计算方式如下：
  ```bash
  磁盘总大小 = 源数据 * (1 + 副本数量) * (1 + 索引开销) / (1 - Linux预留空间) / (1 - ES开销) / (1 - 安全阈值)
  #简化版本
  源数据 * (1 + 副本数量) * 1.7 = 最小存储要求
  ```
### 影响AWS Elasticsearch集群磁盘空间大小的因素：
* 副本数量：每个副本都是一个索引的完整复制，需要同等量的磁盘空间。默认情况下，每个 Elasticsearch 索引都有一个副本。我们建议至少具有一个，以防数据丢失。副本还可以提高搜索性能，因此如果您有需要进行大量读取操作的工作负载，则可能需要更多副本。
* Elasticsearch 索引开销：索引的磁盘大小各有不同，但通常比源数据大 10%。为您的数据编制索引后，您可以使用 _cat/indices API 和 pri.store.size 值计算准确的开销。_cat/allocation API 还提供了一个有用的摘要。
* 操作系统预留空间：默认情况下，Linux 将保留 5% 的文件系统供 root 用户处理关键流程、进行系统恢复和防止磁盘碎片问题。
* Amazon ES 开销：Amazon ES 在每个实例中为分段合并、日志和其他内部操作保留 20% 的存储空间（最多可达 20GiB）。
  ```bash
  最小存储要求 = 源数据 * (1 + 副本数量) * (1 + 索引开销) / (1 - Linux 预留空间) / (1 - Amazon ES 开销)
  #简化版本
  源数据 * (1 + 副本数量) * 1.45 = 最小存储要求
  ```
### shard大小评估
* aws
  * 此外，您集群中大部分的索引配置五个主分片，可以推测这些索引皆使用默认的索引配置 [5]。但事实上 Elasticsearch 的一个分片可以承受 10 GB 至 50 GB 的数据量 [4]。您可以使用 index template [6] ，使相同前缀的索引使用相同的索引配置，避免集群中有太多的分片，使集群忙碌。针对已存在的索引，若是您想修改分片数量，您可以使用 Reindex API [7]。文档 [8][9] 中提供一些使用 Index Alias 的方式，减少 downtime。
* 阿里云
  * shard大小和数量是影响ES集群稳定性和性能的重要因素之一。ES集群中任何一个索引都需要有一个合理的shard规划（默认为5个）。
  * 建议在小规格节点下，单个shard大小不要超过30GB。对于更高规格的节点，单个shard大小不要超过50GB。
  * 对于日志分析或者超大索引场景，建议单个shard大小不要超过100GB。
  * shard的个数（包括副本）要尽可能匹配节点数、等于节点数或者是节点数的整数倍。
  * 通常建议单个节点上同一索引的shard个数不要超5个。
---
## 主机配置，Amazon EC2 (AWS)
#### Elasticsearch节点配置
|Instance configuration|Instance types|	AWS EC2 instance type|Memory Sizes|
|---|---|---|---|
|aws.data.highio.i3|Elasticsearch data nodes optimized for balanced RAM/vCPU/Disk ratios and performance|i3.8xlarge<sup>2</sup>|1,2,4,8|
|aws.data.highstorage.d2|Elasticsearch data nodes optimized for cost effective storage|d2.4xlarge<sup>3</sup>|
|aws.data.highcpu.m5|Elasticsearch data nodes optimized for high CPU performance 1:2 vCPU allocation compared to highio types|m5.12xlarge<sup>4</sup>|
|aws.data.highmem.r4|Elasticsearch data nodes optimized for lower cost with lower storage ratio|r4.8xlarge<sup>5</sup>|
|aws.master.r4|Elasticsearch master eligible nodes used as tiebreakers to establish a quorum in case of 2 availability zone deployments, or as dedicated master across 3 availability zones|r4.8xlarge|
|aws.ingest.m5|Ingest nodes|m5.12xlarge|
|aws.ml.m5|Data nodes|m5.12xlarge|
|aws.kibana.r4|Kibana|r4.8xlarge|
|aws.apm.r4|APM|r4.8xlarge|
|aws.ccs.r4|Cross-cluster search|r4.8xlarge|
#### 注意
1. 内存大小可确保有效地利用硬件，并且可能无法扩展为2（n2）的幂。对于58、60或64 GB以上的大小（取决于实例类型），我们创建多个实例或节点以确保有效的JVM堆大小。例如：如果用128 GB Elasticsearch群集配置部署，则会创建两个64 GB节点。要了解有关为什么我们提供这些JVM堆大小的更多信息，请参阅：[JVM堆大小调整和Swapping](https://www.elastic.co/guide/en/elasticsearch/guide/2.x/heap-sizing.html#heap-sizing)。
2. NVMe SSD storage (memory:storage ratio of 1:30)
3. HDD-based local storage (memory:storage ratio of 1:100)
4. EBS GP2 storage 1024 GB (memory:storage ratio of 1:8)
5. EBS GP2 storage 1024 GB (memory:storage ratio of 1:2)
---
## 参考信息
* https://help.aliyun.com/document_detail/72660.html?spm=a2c4g.11186623.6.551.4d0f6ba578AQZ0
* https://docs.aws.amazon.com/zh_cn/elasticsearch-service/latest/developerguide/sizing-domains.html
* https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-node.html#coordinating-only-node
* https://www.elastic.co/guide/en/cloud/current/ec-reference-hardware.html#aws.data.highstorage.d2