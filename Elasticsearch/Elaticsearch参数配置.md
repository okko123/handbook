* 测试使用的Elasticsearch版本为7.3
## 系统层面优化
* 配置系统的ulimit值、内核参数
  ```bash
  cat >> /etc/security/limits.conf <<EOF
  elasticsearch  soft  nofile  65535
  elasticsearch  hard  nofile  65535
  root           soft  nproc   65535
  root           hard  nproc   65535
  EOF

  sysctl -w vm.max_map_count=262144
  ```
* 关闭swapping。Elasticsearch的参数： bootstrap.mlockall: true。
* Elasticsearch独占机器的情况下，分配一半的物理内存。例如：物理服务器为64G内存，ES的内存应分配32G
* 设置 ES 集群内存的时候，还有一点就是确保堆内存最小值（Xms）与最大值（Xmx）的大小是相同的，防止程序在运行时改变堆内存大小，这是一个很耗系统资源的过程。

* 使用API接口检查所有机器是的mlockall配置、ulimit配置：
  ```bash
  GET /_nodes?filter_path=**.mlockall
  GET /_nodes/stats/process?filter_path=**.max_file_descriptors
  ```

## Elasticsearch的参数调优
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
* 配置索引的参数
  * index.refresh_interval：这个参数的意思是数据写入后几秒可以被搜索到，默认是 1s。每次索引的 refresh 会产生一个新的 lucene 段, 这会导致频繁的合并行为，如果业务需求对实时性要求没那么高，可以将此参数调大，实际调优告诉我，该参数确实很给力，cpu 使用率直线下降。
  * index.translog.flush_threshold_size：translog日志刷新日志的缓存大小，默认值512M
  * index.translog.sync_interval：translog日志刷新到磁盘的时间间隔，默认值为5秒
  * index.translog.durability：在每个索引，删除，更新或批量请求之后是否同步并提交事务日志。只允许配置值[request|async]
    ```json
    PUT /my_index/_settings
    {
       "settings": {
          "index": {
              "number_of_shards": "3",
              "number_of_replicas": "0",
              "refresh_interval": "30s",
              "translog": {
                  "flush_threshold_size": "1GB",
                  "sync_interval": "60s",
                  "durability": "async"
              }
          }
      }
    }
    ```
* 分片恢复的参数。注意，当并发数量配置过大，导致耗尽网络带宽，导致节点通信失败后，集群在不断重新选举。
  * indices.recovery.max_bytes_per_sec：限制每个节点的出入流量的总和（默认值40mb）。仅适用于节点，当集群中有多个几点同时执行恢复，则集群的总恢复流量可能会超出此限制。
  * indices.recovery.max_concurrent_file_chunks：每次恢复并行发送的文件块请求数（默认值2）。
  ```json
  PUT /_cluster/settings
  {
      "persistent":{
          "indices.recovery.max_bytes_per_sec": "50mb",
          "indices.recovery.max_concurrent_file_chunks": "3"
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