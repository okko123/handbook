## Elasticsearch常用的API
* 测试使用的Elasticsearch版本为7.3
## 节点
* 排除节点
```json
PUT /_cluster/settings
{
  "transient" : {
    "cluster.routing.allocation.exclude._ip" : "10.0.0.1"
  }
}
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
```