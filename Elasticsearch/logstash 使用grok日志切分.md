## logstash 使用grok日志切分
### grok 匹配日期时间
(?<timestamp>%{YEAR}[./]%{MONTHNUM}[./]%{MONTHDAY} %{TIME})
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