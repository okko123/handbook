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

#查看所有缩影
GET '/_cat/indices?v'
```
## 集群
```json
#集群设置
GET /_cluster/settings

#节点信息
GET /_cat/nodes
```