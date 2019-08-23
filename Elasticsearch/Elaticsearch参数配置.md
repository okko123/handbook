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
---
## 参考信息
- https://www.elastic.co/guide/en/elasticsearch/reference/current/shards-allocation.html#_shard_allocation_settings
- https://www.elastic.co/guide/en/elasticsearch/reference/current/cluster-update-settings.html