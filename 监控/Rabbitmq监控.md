## 使用Prometheus监控rabbitmq服务
* 检查rabbitmq插件的目录
  ```bash
  rabbitmqctl eval 'application:get_env(rabbit, plugins_dir).'
  ```
* 下载rabbitmq插件
  ```bash
  for i in accept-0.3.3.ez prometheus-3.5.1.ez prometheus_cowboy-0.1.4.ez prometheus_httpd-2.1.8.ez prometheus_rabbitmq_exporter-3.7.2.4.ez
  do
      curl -LO "$1"
  done
---
## 参考资料
* [官方文档](https://www.rabbitmq.com/prometheus.html)