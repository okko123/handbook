# logstash的grok匹配超时
## 表现：logstash的处理效率出现断崖式下降，CPU使用率到达100%（4核的CPU，java的CPU使用率到达400%），大约每秒处理1-2条记录。将logstash运行在前台，并启动日志输出
```bash
logstash -f logstash-product.conf --pipeline.workers 4 --log.level info
[2019-07-18T18:32:42,232][WARN ][logstash.filters.grok    ] Timeout executing grok '' against field 'message' with value 'Value too large to output (320 bytes)! First 255 chars are:
```
# 使用logstash导出ES索引，导出到文件中
```yaml
input{
    elasticsearch {
        hosts => ["192.168.1.1:9200"]
        index => "index-2019.12.26"
        size => 1000
        scroll => "5m"
        docinfo => false
    }
}

output {
    file {
        path => "/root/backup.json"
        codec => "json_lines"
    }
}
```
# 使用logstash将json文件导入ES中
```yaml
input {
    file {
        path => ["/root/back.json"]
        codec => "json"
        start_position => "beginning"
    }
}

filter {
    mutate {
        remove_field => ["path","@version"]
    }
}

output{
    elasticsearch {
        hosts => ["192.168.1.1:9200"]
        index => "index-2019.12.26"
        document_type => "doc"
    }
}

```
## 查阅资料
- CPU使用率高的最终原因是传来的日志格式不能匹配，所以grok就会找默认的n多正则，一直到超时(貌似默认30秒)，这个时间内CPU就会特别繁忙。
- 使用dissect filter替换grok
- 由于不能跳过，只能在logstash的grok中调整grok_timeout的时间

## 参考连接
- [es dissect filter的官网信息](https://www.elastic.co/guide/en/logstash/current/plugins-filters-dissect.html)
- [grok_timeout配置方法](https://www.elastic.co/guide/en/logstash/current/plugins-filters-grok.html#plugins-filters-grok-timeout_millis)
- [参考连接](https://discuss.elastic.co/t/why-am-i-getting-groktimeout-for-a-my-simple-log/65847)
- [logstash配置查询文档](https://www.elastic.co/guide/en/logstash/current/index.html)