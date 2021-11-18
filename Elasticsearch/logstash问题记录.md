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
---
## 查阅资料
- CPU使用率高的最终原因是传来的日志格式不能匹配，所以grok就会找默认的n多正则，一直到超时(貌似默认30秒)，这个时间内CPU就会特别繁忙。
- 使用dissect filter替换grok
- 由于不能跳过，只能在logstash的grok中调整grok_timeout的时间
## 添加systemd的启动脚本
- 修改config/startup.options文件，修改java、elasticsearch home的配置
- 执行bin/system-install [startup.options dir] systemd；生成systemd的启动脚本
- 设置logstash自启动；systemctl enable logstash
## logstash 安装插件
- 执行bin/plugin install logstash-output-webhdfs。但在国内由于不可抗拒的原因，一般会出现：ERROR: Something went wrong when installing logstash-output-webhdfs, message: Net::OpenTimeout。通过修改gem源来绕过
  ```bash
  # rpm安装的logstash的home目录为/usr/share/logstash/
  vim /usr/share/logstash/Gemfile
  将source "https://rubygems.org"替换为
  source "https://repo.huaweicloud.com/repository/rubygems/"
  保存退出，重新安装即可
  ```
## logstash多个配置文件的使用
- 因为 logstash 运行起来的时候，会将所有的配置文件合并执行。因此，每个 input 的数据都必须有一个唯一的标识，在 filter 和 output 时，通过这个唯一标识来实现过滤或者存储到不同的索引。
- 通过多个pipeline来实现多配置文件。一个 pipeline 含有一个逻辑的数据流，它从 input 接收数据，并把它们传入到队列里，经过 worker 的处理，最后输出到 output。这个 output 可以是 Elasticsearch 或其它。
- 举个例子：
  - 配置文件a：a.conf
    ```yml
    input {
        file {
            path => "/data/logs/nginx-a.log"
          	start_position => "beginning"
            sincedb_path => "/dev/null"
            type => "nginx"
        }
    }

    output {
       	elasticsearch {
            index => "nginx-a" 
        }
    }
    ```
  - 配置文件b：b.conf
    ```yml
    input {
        file {
            path => "/data/logs/nginx-b.log"
          	start_position => "beginning"
            sincedb_path => "/dev/null"
            type => "nginx"
        }
    }

    output {
       	elasticsearch {
            index => "nginx-b"
        }
    }
    ```
  - 修改pipeline.yml文件。使用rpm安装logstsah，pipeline.yml位置在/etc/logstash/pipeline.yml
    ```yml
    - pipeline.id: nginx-a
      pipeline.workers: 1
      path.config: "/etc/logstash/conf.d/a.conf"

    - pipeline.id: nginx-b
      pipeline.workers: 1
      path.config: "/etc/logstash/conf.d/b.conf"
    ```
  - 重启logstash：systemctl restart logstash。不同的配置文件，收集的日志将导入到不同的ES索引中
---
## 参考连接
- [es dissect filter的官网信息](https://www.elastic.co/guide/en/logstash/current/plugins-filters-dissect.html)
- [grok_timeout配置方法](https://www.elastic.co/guide/en/logstash/current/plugins-filters-grok.html#plugins-filters-grok-timeout_millis)
- [参考连接](https://discuss.elastic.co/t/why-am-i-getting-groktimeout-for-a-my-simple-log/65847)
- [logstash配置查询文档](https://www.elastic.co/guide/en/logstash/current/index.html)
- [Logstash：多个配置文件（conf）](https://cloud.tencent.com/developer/article/1674717)