进行强制段合并：每个shard是基于多个segment组成创建的，segment的个数的减少可以大幅的提高查询的速度，定时的进行手动索引段合并，可以提高查询速度。支持单索引和多索引批量操作。
curl -XPOST 'http://ip:9200/index-name/_forcemerge?max_num_segments=1
说明:
max_num_segments：merge到多少个segments，1的意思是强行merge到1个segment；
only_expunge_deletes：只清理有deleted标记的segments，推荐值false；
flush：清理完执行一下flush，默认是true。

查看segments的状态
GET /_cat/segments/index-name?v

ES在写入(index)数据的时候，是先写入到缓存中。这时候数据还不能被搜索到。默认情况下ES每隔1秒会执行refresh操作，从内存buffer中将数据写入os cache(操作系统的内存)，产生一个segment file文件。同时建立倒排索引，这个时候文档是可以被搜索到的。

每次refresh都会生成一个新的segment，那么segment的数量很快就会爆炸。另外就是每次搜索请求都必须访问segment，理论上segment越多，搜索请求就会变的越慢。

ES有一个后台进程专门负责segment的合并，它会把小segments合并成更大的segments。这个merge操作大部分时候我们并不需要关心，ES自动处理什么时候merge。只要不影响查询性能，我们也不需要关系分片上有多少个segment。



1.通过/_cat/indices/ api查看所有index的段情况和当前正在进行merge的文档数。
GET /_cat/indices/?s=segmentsCount:desc&v&h=index,segmentsCount,segmentsMemory,memoryTotal,mergesCurrent,mergesCurrentDocs,storeSize,p,r
2.查看各个节点forceMerge的线程数
GET _cat/thread_pool/force_merge?v&s=name
3.查看forceMerge任务详情
GET _tasks?detailed=true&actions=*forcemerge