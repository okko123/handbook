1. 集群中数据类型是怎么样的？
2. 集群中有多少数据？
3. 集群中有多少节点数、分片数？
4. 当前集群索引和检索的速率如何？
5. 当前在执行哪种类型的查询或者其他操作？

排查思路
1. CPU高的时候，建议看一下ES节点的日志，看看是不是有大量的GC。
2. 查看hot_threads。GET _nodes/hot_threads
3. 优化配置
   ```yaml
   # Force all memory to be locked, forcing the JVM to never swap
   # 它的作用就是允许 JVM 锁住内存，禁止操作系统交换出去
   bootstrap.mlockall: true
   ## 请查阅相关手册后，再修改线程池的大小
   Threadpool Settings
   Search pool
   threadpool.search.type: fixed
   threadpool.search.size: 20
   threadpool.search.queue_size: 200
   
   Bulk pool
   threadpool.bulk.type: fixed
   threadpool.bulk.size: 60
   threadpool.bulk.queue_size: 3000
   
   Index pool
   threadpool.index.type: fixed
   threadpool.index.size: 20
   threadpool.index.queue_size: 1000
   Indices settings
   indices.memory.index_buffer_size: 30%
   indices.memory.min_shard_index_buffer_size: 12mb
   indices.memory.min_index_buffer_size: 96mb
   
   Cache Sizes
   indices.fielddata.cache.size: 30%
   #indices.fielddata.cache.expire: 6h #will be depreciated & Dev recomend not to use it
   indices.cache.filter.size: 30%
   #indices.cache.filter.expire: 6h #will be depreciated & Dev recomend not to use it
   
   Indexing Settings for Writes
   index.refresh_interval: 30s
   #index.translog.flush_threshold_ops: 50000
   #index.translog.flush_threshold_size: 1024mb
   index.translog.flush_threshold_period: 5m
   index.merge.scheduler.max_thread_count: 1
   ```

## 要排查 Elasticsearch 集群 CPU 使用率较高的问题，请考虑以下方法：
### 使用 Nodes hot threads API。（有关更多信息，请参阅 Elasticsearch 网站上的 Nodes hot threads API。）
---
- 如果 Elasticsearch 集群中的 CPU 持续处于峰值，请使用 nodes hot threads API。nodes hot threads API 充当任务管理器，向您显示 Elasticsearch 集群上运行的所有资源密集型线程的细分情况。以下是 nodes hot threads API 的示例输出：
  ```bash
  GET _nodes/hot_threads
  
  100.0% (131ms out of 500ms) cpu usage by thread 
  'elasticsearch[xxx][search][T#62]' 10/10 snapshots sharing following 10 
  elements sun.misc.Unsafe.park(Native Method) 
  java.util.concurrent.locks.LockSupport.park(LockSupport.java:175) 
  java.util.concurrent.LinkedTransferQueue.awaitMatch(LinkedTransferQueue.java:737)
   
  java.util.concurrent.LinkedTransferQueue.xfer(LinkedTransferQueue.java:647)
   
  java.util.concurrent.LinkedTransferQueue.take(LinkedTransferQueue.java:1269)
   
  org.elasticsearch.common.util.concurrent.SizeBlockingQueue.take(SizeBlockingQueue.java:162)
   
  java.util.concurrent.ThreadPoolExecutor.getTask(ThreadPoolExecutor.java:1067)
   
  java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1127)
   
  java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:617)
  java.lang.Thread.run(Thread.java:745)
  ```
- 注意： nodes hot threads 输出列示了每个节点的信息。输出的长度取决于 Elasticsearch 集群中运行的节点数。
- 此外，可以使用 cat nodes API 查看资源利用率的当前细分情况。您可以使用以下命令缩小 CPU 利用率最高的节点子集：
  - 输出中的最后一列显示了节点名称。有关更多信息，请参阅 Elasticsearch 网站上的 [cat nodes API](https://www.elastic.co/guide/en/elasticsearch/reference/current/cat-nodes.html)。

  ```bash
  GET _cat/nodes?v&s=cpu:desc
  ```
- 然后，将相关节点名称传递给 hot threads API：
  - 有关更多信息，请参阅 Elasticsearch 网站上的 [hot threads API](https://www.elastic.co/guide/en/logstash/current/hot-threads-api.html)。
  ```bash
  GET _nodes/<node-name>/hot_threads
  ```
- nodes hot threads 输出如下所示：
  - 线程名称表示哪些 Amazon ES 进程正在占用较高的 CPU。
  ```bash
  <percentage> of cpu usage by thread 'elasticsearch[<nodeName>][<thread-name>]
  ```

### 查看 write 操作或 bulk API 线程池。（有关更多信息，请参阅 Elasticsearch 网站上的 Bulk API。）
---
Amazon ES 中的 429 错误可能表明您的 Elasticsearch 集群正在处理的批量索引请求过多。当您的集群中的 CPU 持续处于峰值时，Amazon ES 将拒绝批量索引请求。

write 线程池处理索引请求，其中包括 Bulk API 操作。要确认您的 Elasticsearch 集群是否正在处理过多的批量索引请求，请查看 Amazon CloudWatch 中的 IndexingRate 指标。

如果您的 Elasticsearch 集群正在处理的批量索引请求过多，可以考虑以下方法：
- 减少 Elasticsearch 集群批量请求的数量。
- 减小每个批量请求的大小，以便节点可以更有效地处理它们。
- 如果使用 Logstash 将数据推送到 Elasticsearch 集群中，则缩小批量大小或减少工作线程的数量。
- 如果 Elasticsearch 集群的提取速度降低，请（水平或垂直）扩展集群。要扩展集群，请增加节点数量和实例类型，以便 Amazon ES 能够正确处理传入的请求。
### 查看 search 线程池。（有关更多信息，请参阅 Elasticsearch 网站上的线程池。）
---
占用较高 CPU 的 search 线程池表明搜索查询正在使您的 Elasticsearch 集群不堪重负。单个长时间运行的查询可能会使您的集群不堪重负。Elasticsearch 集群正在执行的查询数量增加也会影响 search 线程池。

要查看是否是单个查询正在增加您的 CPU 使用率，请使用 task management API。例如：
```bash
GET _tasks?actions=*search&detailed
```
task management API 将获取 Elasticsearch 集群上运行的所有活动搜索查询。有关更多信息，请参阅 Elasticsearch 网站上的 Task management API。

以下是示例输出：
```bash
{
  "nodes": {
    "U4M_p_x2Rg6YqLujeInPOw": {
      "name": "U4M_p_x",
      "roles": [
        "data",
        "ingest"
      ],
      "tasks": {
        "U4M_p_x2Rg6YqLujeInPOw:53506997": {
          "node": "U4M_p_x2Rg6YqLujeInPOw",
          "id": 53506997,
          "type": "transport",
          "action": "indices:data/read/search",
          "description": """indices[*], types[], search_type[QUERY_THEN_FETCH], source[{"size":10000,"query":{"match_all":{"boost":1.0}}}]""",
          "start_time_in_millis": 1541423217801,
          "running_time_in_nanos": 1549433628,
          "cancellable": true,
          "headers": {}
        }
      }
    }
  }
}
```
查看 description 字段，确定正在运行的特定查询。running_time_in_nanos 字段指出查询运行的时长。要降低 CPU 使用率，请取消正在占用较高 CPU 的搜索查询。task management API 还支持 _cancel 调用。

注意：请务必记录输出的任务 ID，以便用于取消特定任务。在此示例中，任务 ID 为“U4M_p_x2Rg6YqLujeInPOw:53506997”。

以下是 task management POST 调用的示例：
```bash
POST _tasks/U4M_p_x2Rg6YqLujeInPOw:53506997/_cancel
```
Task Management POST 调用会将任务标记为“已取消”，从而释放所有相关 AWS 资源。如果 Elasticsearch 集群上运行了多个查询，请使用 POST 调用一次取消一个查询。取消每个查询，直至 Elasticsearch 集群恢复正常状态。最佳做法是在查询正文中设置适当的超时值，以防止较高的 CPU 峰值。（有关更多信息，请参阅 Elasticsearch 网站上的请求正文搜索参数。） 要验证活动查询的数量是否减少，请查看 Amazon CloudWatch 中的 SearchRate 指标。

注意：同时取消 Elasticsearch 集群中的所有活动搜索查询可能会导致客户端应用程序端出错。
### 查看 Apache Lucene merge 线程池。（有关更多信息，请参阅 Elasticsearch 网站上的 Merge。）
---
Amazon ES 使用 Apache Lucene 对 Elasticsearch 集群上的文档进行索引和搜索。Apache Lucene 运行 merge 操作，以减少每个分区所需的有效区段数，并移除所有已删除的文档。只要在分区中创建新区段就会运行此过程。如果您观察到 Apache Lucene merge 线程操作影响了 CPU 使用率，请增加 Elasticsearch 集群索引的 refresh_interval 设置值。refresh_interval 设置的增加会减慢集群的区段创建速度。注意：将索引迁移到 UltraWarm 存储的 Elasticsearch 集群可以提高 CPU 利用率。UltraWarm 迁移通常涉及 orce merge API 操作，该操作可能会占用大量 CPU。要查看是否有任何 UltraWarm 迁移，请使用以下命令：
GET _ultrawarm/migration/_status?v
## 参考信息
- [如何排查 Amazon Elasticsearch Service 集群上 CPU 使用率较高的问题？](https://aws.amazon.com/cn/premiumsupport/knowledge-center/es-high-cpu-troubleshoot/)