* 测试使用的Elasticsearch版本为7.3
* Elasticsearch里很多设置都是动态的，可以通过API修改。集群更新API有两种工作模式：
  - 临时transient：这些变更在集群重启之前一直会生效。一旦整个集群重启，这些配置就被清除。
  - 永久persistent：这些变更会永久存在直到被显式修改。即使全集群重启它们也会存活下来并覆盖掉静态配置文件里的选项。
  - 临时或永久配置需要在 JSON 体里分别指定：
  ```json
  PUT /_cluster/settings
  {
      "persistent" : {
          "discovery.zen.minimum_master_nodes" : 2 
      },
      "transient" : {
          "indices.store.throttle.max_bytes_per_sec" : "50mb" 
      }
  }

* 分片重新分配
  - all - (default) Allows shard allocation for all kinds of shards.
  - primaries - Allows shard allocation only for primary shards.
  - new_primaries - Allows shard allocation only for primary shards for new indices.
  - none - No shard allocations of any kind are allowed for any indices.
```json
PUT /_cluster/settings
{
    "persistent":{
        "cluster.routing.allocation.enable" : "all"
    }
}
```
* 分片重新平衡
  - all - (default) Allows shard balancing for all kinds of shards.
  - primaries - Allows shard balancing only for primary shards.
  - replicas - Allows shard balancing only for replica shards.
  - none - No shard balancing of any kind are allowed for any indices.
```json
PUT /_cluster/settings
{
    "persistent":{
        "cluster.routing.rebalance.enable" : "all"
    }
}
```
## 磁盘信息的配置，磁盘的三个默认警戒水位线
  - cluster.routing.allocation.disk.watermark.low
    - 低警戒水位线——默认为磁盘容量的85%。Elasticsearch不会将分片分配给使用磁盘超过85%的节点。它也可以设置为绝对字节值（如500mb），以防止Elasticsearch在小于指定的可用空间量时分配分片。此设置不会影响新创建的索引的主分片，或者特别是之前任何从未分配过的分片。
  - cluster.routing.allocation.disk.watermark.high
    - 高警戒水位线——默认为磁盘容量的90%。Elasticsearch将尝试从磁盘使用率超过90%的节点重新分配分片。它也可以设置为绝对字节值，以便在节点小于指定的可用空间量时将其从节点重新分配。此设置会影响所有分片的分配，无论先前是否分配。
  - cluster.routing.allocation.disk.watermark.flood_stage
    - 洪水警戒水位线——默认为磁盘容量的95%。Elasticsearch对每个索引强制执行只读索引块（index.blocks.read_only_allow_delete）。这是防止节点耗尽磁盘空间的最后手段。一旦有足够的可用磁盘空间允许索引操作继续，就必须手动释放索引块。
  - cluster.info.update.interval
    - Elasticsearch应该多久检查一次群集中每个节点的磁盘使用情况。 默认为30秒。
  ```json
  PUT /_cluster/settings
  {
    "persistent": {
      "cluster.routing.allocation.disk.watermark.low": "100gb",
      "cluster.routing.allocation.disk.watermark.high": "50gb",
      "cluster.routing.allocation.disk.watermark.flood_stage": "10gb",
      "cluster.info.update.interval": "1m"
    }
  }
  ```
---
## 参考信息
- https://www.elastic.co/guide/en/elasticsearch/reference/current/shards-allocation.html#_shard_allocation_settings
- https://www.elastic.co/guide/en/elasticsearch/reference/7.3/disk-allocator.html
- https://www.elastic.co/guide/en/elasticsearch/reference/current/cluster-update-settings.html
- https://blog.csdn.net/laoyang360/article/details/83218266