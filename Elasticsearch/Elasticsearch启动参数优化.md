### Elasticsearch启动参数优化
- 禁用内存交换
  > ES官方一般会建议我们关闭内存交换。内存交换是操作系统的概念，简单来讲它提供一种机制，当内存空间不够用时，使用部分磁盘的空间交换到内存中暂用。因为磁盘的访问速度远远不及内存，所以开启这个会降低集群的性能。我们可以通过在elasticsearch.yml文件中增加如下的配置：
   ```bash
   cat >> /etc/elasticsearch/elasticsearch.yml<<EOF
   bootstrap.memory_lock: true
   EOF

   #使用systemd启动elasticsearch，需要修改elasticsearch启动配置，路径为：/usr/lib/systemd/system/elasticsearch.service，添加以下内容
   LimitMEMLOCK=infinity
   ```

   > 是否锁住内存，避免交换(swapped)带来的性能损失,默认值是: false。设置完成后，需要重启ES。然后我们可以通过以下命令实时查看请求的输出中的 mlockall 值来查看是否成功应用了此设置。
    ```bash
    GET _nodes?filter_path=**.mlockall
    ```
   > 如果看到 mlockall 为 false ，则表示 mlockall 请求已失败。您还将在日志中看到一行包含更多信息的行，内容为“无法锁定 JVM 内存”。
---
- 集群分配相关属性
  1. cluster.routing.allocation.cluster_concurrent_rebalance
     > 这个属性允许控制群集范围内允许的并发分片重新平衡数。默认为2。请注意，此设置仅控制由于群集中的不平衡而导致的并发分片重定位数。我们应该关注这个值，不同的集群配置和业务场景应该考虑这个值的大小。大部分情况下这个小一些会有好处，这个也好理解，并发执行的分片数多了肯定会影响性能。
  2. cluster.routing.allocation.disk.threshold_enabled
     > 这个属性，表示的是ES可以根据磁盘使用情况来决定是否继续分配shard。默认设置是开启的（true）。

     > 在开启的情况下，有两个重要的设置：
       1. cluster.routing.allocation.disk.watermark.low：控制磁盘最小使用率。默认85%.说明es在磁盘使用率达到85%的时候将会停止分配新的shard。也可以设置为一个绝对数值，比如500M。
       2. cluster.routing.allocation.disk.watermark.high：控制磁盘的最大使用率。默认90%.说明在磁盘使用率达到90%的时候es将会relocate shard去其他的节点。同样也可以设置为一个绝对值。
       3. 在某些场景下，有时候这个默认开启的值会比较保守，我们可以根据实际情况适当调整。 
  3. cluster.routing.allocation.node_concurrent_recoveries
     > 这个属性，控制多少个分片可以在单个节点上同时恢复。恢复分片是一个IO非常密集的操作，所以应当谨慎调整该值。默认值是2。我之前看到过一个生产上的案例，作者为了加快集群的分片恢复速度，把这个值改成一个三位数，结果集群就卡死了。
  4. cluster.routing.allocation.node_initial_primaries_recoveries
     > 这个属性初始化数据恢复时，并发恢复线程的个数。一个未被分配的primary shard会在node重启之后使用本地磁盘上的数据，这个过程因为是使用本地的数据，因此会比较快，默认值是4.
  5. indices.recovery.max_bytes_per_sec
     > 这个是在有节点掉了，重新恢复的时候，各个节点之间的传输恢复速度。默认是40mb。如果你的网络环境配置比较高，可以适当的提高这个值。上面的这几个参数都需要根据集群的硬件配置来决定合适的值，建议就是测试后再决定。线程池属性防止数据丢失
  6. threadpool.bulk.queue_size: 5000
     > 这个属性用来提高批量操作线程池任务队列的大小。这个属性对于防止因批量重试而可能引起的数据丢失是极其关键的。这个属性决定了当没有可用线程来执行一个批量请求时，可排队在该节点执行的分片请求的数量。该值应当根据批量请求的负载来设置。如果批量请求数量大于队列大小，就会得到一个下文展示的RemoteTransportException异常。这个值如果设置的太高，会占用JVM的堆内存。设置的太小在并发量大的场景又容易引起异常。如果不处理该异常，将会丢失数据。
## 参考信息
- [官方文档，配置系统参数](https://www.elastic.co/guide/en/elasticsearch/reference/current/setting-system-settings.html#systemd)
- [cluster-level-shard-allocation-routing-settings](https://www.elastic.co/docs/reference/elasticsearch/configuration-reference/cluster-level-shard-allocation-routing-settings)