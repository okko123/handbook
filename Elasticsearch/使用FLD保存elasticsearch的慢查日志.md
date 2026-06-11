### 使用FLD 保存elasticsearch的慢查日志
- filebeat 8.17.4
- logstash 8.17.4
- doris 2.1.11

#### doris 建表
```sql
CREATE DATABASE IF NOT EXISTS log_db;
USE log_db;

CREATE TABLE IF NOT EXISTS es_search_slowlog (
    `log_time` datetime NULL COMMENT "日志发生时间", 
    `log_level` varchar(10) NULL COMMENT "日志级别", 
    `node_name` varchar(50) NULL COMMENT "节点名称", 
    `index_name` varchar(100) NULL COMMENT "索引名称", 
    `shard_id` int NULL COMMENT "分片ID", 
    `took_ms` int NULL COMMENT "耗时(毫秒)", 
    `search_type` varchar(30) NULL COMMENT "搜索类型", 
    `total_shards` int NULL COMMENT "总分片数", 
    `dsl_source` text NULL COMMENT "完整的查询DSL语句", 
    `hit` int NULL COMMENT "命中数量" 
)
ENGINE=OLAP
DUPLICATE KEY(log_time, log_level)
DISTRIBUTED BY HASH(index_name) BUCKETS 5
PROPERTIES (
    "replication_num" = "3"
);
```
#### filebeat配置
```bash
cat > /etc/filebeat/filebeat.yml <<EOF
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /data/elasticsearch/logs/analysis_index_search_slowlog.log

  multiline.type: pattern
  multiline.pattern: '^\['
  multiline.negate: true
  multiline.match: after

  tags: ["es-search-slowlog"]

output.kafka:
  hosts: ['192.168.10.135:9092', '192.168.10.136:9092', '192.168.10.137:9092']
  topic: 'analysis-es-slowlog'
  partition.round_robin:
    reachable_only: false
  required_acks: 1
  compression: gzip
  max_message_bytes: 1000000
EOF

systemctl restart filebeat
```
#### logstash配置
```bash
cat > logstash.conf <<EOF
input {
    kafka {
        bootstrap_servers => "192.168.10.135:9092, 192.168.10.136:9092, 192.168.10.137:9092"
        topics => ["analysis-es-slowlog"]
        group_id => "logstash8-new1"
        auto_offset_reset => "earliest"
        consumer_threads => 4
        codec => json {
            charset => "UTF-8"
        }
    }
}

filter {
    if "es-search-slowlog" in [tags][0] {
        # 1. 精准 Grok 匹配 ES 6.4.2 慢日志格式
        grok {
            match => {
                "message" => "^\[%{TIMESTAMP_ISO8601:log_time}\]\[%{WORD:log_level}\s*\]\[index\.search\.slowlog\.query\]\s*\[%{NOTSPACE:node_name}\]\s*\[%{NOTSPACE:index_name}\]\[%{INT:shard_id:int}\]\s*took\[%{NOTSPACE:took_human}\],\s*took_millis\[%{INT:took_ms:int}\],\s*total_hits\[%{INT:hit}\],\s*types\[%{NOTSPACE:type}\],\s* stats\[%{DATA:stats}\],\s*search_type\[%{WORD:search_type}\],\s*total_shards\[%{INT:total_shards:int}\],\s*source\[%{GREEDYDATA:dsl_source}\]"
            }
        }

        # 2. 丢弃解析失败的脏数据
        if "_grokparsefailure" in [tags] {
            drop { }
        }

        # 3. 清理末尾可能存在的 id[...] 残留，还原干净的 JSON 字符串
        mutate {
            gsub => [ "dsl_source", "\]\,\s*id\[.*$", "" ]
        }

        # 4. 完美时间置换：将日志中的发生时间 log_time 赋值给全局的 @timestamp
        # 这样在 Kibana 里面看图表时，时间轴就是真实的日志发生时间，而不是 Logstash 消费的时间
        date {
            match => [ "log_time", "ISO8601" ]
            target => "@timestamp"
            timezone => "Asia/Shanghai" # 锁定目标时区
        }

        ruby {
            code => "event.set('log_time', event.get('@timestamp').time.localtime('+08:00').strftime('%Y-%m-%d %H:%M:%S'))"
        }

        # 5. 转换完成后，移除无用的原始巨长字段，释放物理内存
        mutate {
            remove_field => [ "message", "agent", "offset", "ecs", "tags", "@version", "input", "log", "host", "@timestamp", "type", "took_human", "stats"]
        }
    }
}

output {
    doris {
        http_hosts => ["http://192.168.10.239:8030", "http://192.168.10.240:8030"]
        user => "root"
        password => "1234567"
        db => "log_db"
        table => "es_search_slowlog"

        headers => {
          "format" => "json"
          "read_json_by_line" => "true"
          "load_to_single_tablet" => "false"
        }

        # Doris表中的字段与logstash中的字段进行一一对应
        mapping => {
            "log_time" => "%{log_time}"
            "log_level" => "%{log_level}"
            "node_name" => "%{node_name}"
            "index_name" => "%{index_name}"
            "shard_id" => "%{shard_id}"
            "took_ms" => "%{took_ms}"
            "search_type" => "%{search_type}"
            "total_shards" => "%{total_shards}"
            "dsl_source" => "%{dsl_source}"
            "hit" => "%{hit}"
        }
        # log_request 为 true 时日志会输出每次 Stream Load 的请求参数和响应结果
        log_request => true
    }
}

bin/logstash -f config/logstash.conf