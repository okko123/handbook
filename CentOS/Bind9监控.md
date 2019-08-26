## Bind9-使用Prometheus监控bind9的DNS服务
* 环境设定，实验的操作系统CentOS Linux release 7.6.1810
---
* 安装bind_exporter
```bash
https://github.com/digitalocean/bind_exporter
yum install -y go
go get github.com/digitalocean/bind_exporter

```