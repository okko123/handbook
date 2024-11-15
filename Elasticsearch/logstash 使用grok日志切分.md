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
### logstash优化策略
---
```bash
pipeline
- worker: 设置确定运行多少个线程来进行过滤和输出处理。 如果您发现事件正在备份，或者 CPU 未饱和，请考虑增加此参数的值，以更好地利用可用的处理能力。 甚至可以发现，将此数量增加到超过可用处理器的数量会得到良好的结果，因为这些线程在写入外部系统时可能会花费大量时间处于 I/O 等待状态。 该参数的合法值为正整数。
- batch.size: 单个工作线程在尝试执行其过滤器和输出之前将从输入收集的最大事件数。 较大的批处理大小通常更高效，但代价是增加内存开销。 您可能需要在 jvm.options 配置文件中增加 JVM 堆空间。 有关详细信息，请参阅 Logstash 配置文件。
- batch.delay: 创建管道事件批次时，在将大小不足的批次分派给管道工作人员之前，等待每个事件的时间（以毫秒为单位）。

jvm: logstash是将输入存储在内存之中，worker数量 * batch_size = n * heap (n代表正比例系数)
```
### grok 匹配日期时间
---
- (?<timestamp>%{YEAR}[./]%{MONTHNUM}[./]%{MONTHDAY} %{TIME})
### logstash grok自定义匹配
---
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