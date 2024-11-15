## Elasticsearch部署记录
* 环境设定，实验的操作系统CentOS Linux release 7.6.1810
* 测试使用的Elasticsearch版本为7.3

|IP|角色|数据冷热|
|-|-|-|
|192.168.1.1|elasticsearch|hot|
|192.168.1.2|elasticsearch|hot|
|192.168.1.3|elasticsearch|cold|
|192.168.1.4|elasticsearch|cold|

* 部署记录
```bash
yum install java-11-openjdk https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.3.0-x86_64.rpm -y
mkdir -p /data/log/elasticsearch /data/elasticsearch
chown -R elasticsearch.elasticsearch /data/log/ /data/elasticsearch/

#配置热数据节点
cat > /etc/elasticsearch/elasticsearch.yml <<EOF
path.data: /data/elasticsearch
path.logs: /data/log/elasticsearch
network.host: 192.168.1.1
node.attr.box_type: hot
http.port: 9200
discovery.seed_hosts: ["192.168.1.1"]
cluster.initial_master_nodes: ["node-1"]
EOF

#配置冷数据节点
cat > /etc/elasticsearch/elasticsearch.yml <<EOF
path.data: /data/elasticsearch
path.logs: /data/log/elasticsearch
network.host: 192.168.1.3
node.attr.box_type: cold
http.port: 9200
discovery.seed_hosts: ["192.168.1.1"]
cluster.initial_master_nodes: ["node-1"]
EOF

systemctl daemon-reload
systemctl start elasticsearch.service
systemctl enable elasticsearch.service

```
* 配置mapping
  * 例如nginx日志中的时间格式为19/Aug/2019:10:27:13 +0800，默认以text存到ES中，因此需要修改mapping的属性，修改为date并且定义时间格式。
```bash
{
  "order": 0,
  "version": 1,
  "index_patterns": [
    "nginx-*"
  ],
  "settings": {
    "index": {
      "number_of_shards": "1",
      "routing": {
        "allocation": {
          "require": {
            "box_type": "hot"
          }
        }
      }
    }
  },
  "mappings": {
    "properties": {
      "time_local": {
        "": "dd/MMM/yyyy:HH:mm:ss Z",
        "type": "date"
      }
    }
  }
}


```
---
## es资料
* https://www.infvie.com/ops-notes/elkstack-beats
* https://www.elastic.co/guide/en/elasticsearch/reference/current/shard-allocation-filtering.html
* https://www.elastic.co/guide/en/elasticsearch/reference/current/delayed-allocation.html
* https://www.elastic.co/guide/en/elasticsearch/reference/5.5/cluster-update-settings.html
* https://www.elastic.co/guide/cn/elasticsearch/guide/cn/_changing_settings_dynamically.html

## mapping/datatime
* https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping-date-format.html
* https://www.elastic.co/guide/en/logstash/current/event-dependent-configuration.html
* [时间格式](https://docs.oracle.com/javase/8/docs/api/java/time/format/DateTimeFormatter.html)