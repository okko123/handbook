## Elasticsearch常用的API
* 测试使用的Elasticsearch版本为7.3
## 节点
```json
#排除节点
PUT /_cluster/settings
{
  "transient" : {
    "cluster.routing.allocation.exclude._ip" : "10.0.0.1"
  }
}

#查看节点属性
GET /_cat/nodeattrs?v

#查看节点
GET /_cat/nodes?v
```

## 索引
```json
#开启索引，支持通配
POST /my_index_name/_open
POST /my_index_name*/_open

#关闭索引
POST /my_index_name/_close
POST /my_index_name*/_close

#删除索引
DELETE /my_index_name
DELETE /my_index_name*

#查看所有索引
GET '/_cat/indices?v'

#修改索引的副本数量
PUT /my_index/_settings
{
    "number_of_replicas": 1
}

#合并段(segments)
POST /my_index/_forcemerge?max_num_segments=1

#重建索引
curl -XPOST -H "Content-Type: application/json" http://127.0.0.1:9200/_reindex?wait_for_completion=false -d '
{
  "source": {
    "index": "teambition"
  },
  "dest": {
    "index": "teambition_20180328"
  },
  "script": {...}
}
'
POST /_reindex?wait_for_completion=false
{
  "source": {
    "index": "teambition"
  },
  "dest": {
    "index": "teambition_20180328"
  },
  "script": {...}
}

#查看任务信息
GET /_tasks/{taskID}可以看到重建进程，其中包含耗时，剩余doc数量等信息
```
## 模板
```json
# 创建/修改模板(ES修改模板实际上是用新的模板进行覆盖)
PUT /_template/sw_template
{
"order": 0,
    "version": 0,
    "index_patterns": "nginx_*",
    "order": 1,
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
## 集群
```json
#集群设置
GET /_cluster/settings

#节点信息
GET /_cat/nodes

#设置监控索引的保留天数。
PUT /_cluster/settings
{"persistent": {"xpack.monitoring.history.duration":"2d"}}

# 强制段合并
https://www.elastic.co/guide/en/elasticsearch/reference/6.8/indices-forcemerge.html
POST /index_name/_forcemerge?only_expunge_deletes=false&max_num_segments=1&flush=true
```


---
## 参考信息
[Elasticsearch Reindex性能提升10倍+实战](https://blog.csdn.net/laoyang360/article/details/81589459)
[配置Monitoring监控日志](https://www.alibabacloud.com/help/zh/doc-detail/68017.htm)