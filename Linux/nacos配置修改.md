## nacos配置修改
1. 修改访问日志的保存时间和保存路径
```bash
# 修改conf/application.properties
#*************** Access Log Related Configurations ***************#
### If turn on the access log:
server.tomcat.accesslog.enabled=true
### 访问日志的保存时长
server.tomcat.accesslog.MaxDays=3

### The access log pattern:
server.tomcat.accesslog.pattern=%h %l %u %t "%r" %s %b %D %{User-Agent}i %{Request-Source}i

### The directory of access log:
server.tomcat.basedir=file:/data/logs/nacos
```
---
### 参考信息
- [日志保留天数](https://nacos.io/blog/faq/nacos-user-question-history16264/#_top)