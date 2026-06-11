## logstash 使用grok日志切分
---
### logstash配置文件样例
```bash
input {
    kafka {
        bootstrap_servers => "192.168.1.1:9092"
        topics => ["nginx_access"]
        consumer_threads => 4
        codec => json {
            charset => "UTF-8"
        }
        client_id => "debug"
        type => "logging"
    }
}

filter {
    grok {
        match => {
            "message" => '%{NUMBER:request_time}\|%{IP:ip}\|%{USERNAME:username}\|%{DATA:hostname}\|\[%{HTTPDATE:timestamp}\]\|%{WORD:method} %{URIPATHPA
RAM:request} HTTP/%{NUMBER:httpversion}\|%{NUMBER:response}\|(?:%{NUMBER:bytes}|-)\|(?:"(?:%{URI:referrer}|-)"|%{QS:referrer})\|%{QS:http_user_agent}\|%{
DATA:xforwardedfor}\|%{URIHOST:upstream_addr}\|(%{QS:shop_id})\|%{DATA:request_body}'
        }
        remove_field => ["message", "agent", "offset", "log", "ecs", "port", "input"]
    }
}

output {
    stdout {
        codec => rubydebug
    }
}
```
---
### logstash处理es慢日志，写入doris
- 从kafka中读取数据处理，将处理完的数据写入Doris中
- 测试的logstash版本：8.17.4
  ```bash
  ### logstash接入es的slow日志
  input {
      kafka {
          bootstrap_servers => "192.168.1.165:9092, 192.168.1.166:9092, 192.168.1.167:9092"
          topics => ["es-slowlog"]
          group_id => "logstash8"
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
          #if "_grokparsefailure" in [tags] {
          #    drop { }
          #}

          # 3. 完美时间置换：将日志中的发生时间 log_time 赋值给全局的 @timestamp
          # 这样在 Kibana 里面看图表时，时间轴就是真实的日志发生时间，而不是 Logstash 消费的时间
          date {
              match => [ "log_time", "ISO8601" ]
              timezone => "Asia/Shanghai"
          }

          mutate {
              # 匹配小数点 `.` 及其后面的所有字符，替换为空（即直接删掉）
              gsub => [ "log_time", "\,\d+.*", "" ]
          }

          mutate {
              gsub => [ "log_time", "T", " " ]
          }

          # 4. 转换完成后，移除无用的原始巨长字段，释放物理内存
          mutate {
              remove_field => [ "message", "agent", "offset", "ecs", "tags", "@version", "input",   "log", "host", "@timestamp", "type", "took_human", "original"]
          }
      }
  }

  output {
  #    stdout {codec => rubydebug}
      doris {
          http_hosts => ["http://192.168.1.239:8030", "http://192.168.1.240:8030"]
          user => "root"
          password => "123456"
          db => "log_db"
          table => "es_analysis_search_slowlog"
  
          headers => {
            "format" => "json"
            "read_json_by_line" => "true"
            "load_to_single_tablet" => "false"
          }

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
          log_request => true
      }
  }
  ```
---
### logstash优化策略
```bash
pipeline
- worker: 设置确定运行多少个线程来进行过滤和输出处理。 如果您发现事件正在备份，或者 CPU 未饱和，请考虑增加此参数的值，以更好地利用可用的处理能力。 甚至可以发现，将此数量增加到超过可用处理器的数量会得到良好的结果，因为这些线程在写入外部系统时可能会花费大量时间处于 I/O 等待状态。 该参数的合法值为正整数。
- batch.size: 单个工作线程在尝试执行其过滤器和输出之前将从输入收集的最大事件数。 较大的批处理大小通常更高效，但代价是增加内存开销。 您可能需要在 jvm.options 配置文件中增加 JVM 堆空间。 有关详细信息，请参阅 Logstash 配置文件。
- batch.delay: 创建管道事件批次时，在将大小不足的批次分派给管道工作人员之前，等待每个事件的时间（以毫秒为单位）。

jvm: logstash是将输入存储在内存之中，worker数量 * batch_size = n * heap (n代表正比例系数)
```
---
### grok 匹配日期时间
- (?<timestamp>%{YEAR}[./]%{MONTHNUM}[./]%{MONTHDAY} %{TIME})
---
### logstash grok自定义匹配
- grok 表达式的打印复制格式的完整语法是下面这样的：
  ```bash
  %{SYNTAX:SEMANTIC}
  Syntax: 默认的grok模式
  Semantic: 是关键词。

  %{PATTERN_NAME:capture_name:data_type}
  小贴士：data_type 目前只支持两个值：int 和 float。

  # 例子：匹配错误级别，字符串："2024-05-28 17:50:07,844 INFO  [XNIO-1 task-9]"
  %{LOGLEVEL: level}

  # 匹配结果
  {
  "level": "INFO"
  }
  ```
- oniguruma 语法
  ```bash
  (?<field_name>the pattern here) ==> (?<字段名>正则)
  field_name：是关键词。
  pattern ：这里的模式是你放入正则表达式模式的地方。

  # 匹配{开头的内容，存放到user_agent的关键字中
  grok正则表达式：(?<user_agent>[^{]*)

  # 截取，report和msg之间的值，不包含report和msg本身
  grok正则表达式：(?<temMsg>(?<=report).*?(?=msg))
  
  # 截取，report和msg之间的值，包含report但不包含msg本身
  grok正则表达式：(?<temMsg>(report).*?(?=msg))

  # 截取，report和msg之间的值，不包含report但包含msg本身
  grok正则表达式：(?<temMsg>(?<=report).*?(msg))

  # 截取以report开头，以msg或者以request结尾的所有包含头尾信息
  grok正则表达式：(?<temMsg>(report).*?(msg|request))

  # 截取以report开头，以msg或者以request结尾的所有不包含头尾信息
  grok正则表达式：(?<temMsg>(report).*?(?=(msg|request)))

  # 使用(?:use\s+%{USER:usedatabase};\s*)?匹配
  # (?:use\s+%{USER:usedatabase};\s*\n)? 这个匹配可能有，也可能无；如果有就是以use开头，若干空字符，以USER模式进行正则匹配，结果放在usedatabase中，然后紧接着; ，后面是0个或者多个空字符，然后就是换行。注意：如果有是整体有，如果无是整体无
  use   abcd12345;25dsf
  结果：usedatabase: abcd12345

  # (?<query>(?<action>\w+)b.*) 整体匹配，存到query中，以一个或多个字符开头组成的单词，结果存到action中
  use   applebcd12345;25dsf
  结果  "action": "apple",
        "query": "applebcd12345;25dsf"
  ``` 
---
### 参考连接
- [grok-pattern](https://github.com/logstash-plugins/logstash-patterns-core/blob/main/patterns/ecs-v1/grok-patterns)
- [Logstash——核心解析插件Grok](https://www.cnblogs.com/caoweixiong/p/12579498.html)