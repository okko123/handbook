# Prometheus的exporter使用记录
- consul-exporter使用记录
  - github地址：https://github.com/prometheus/consul_exporter
  - grafana面板监控consul：https://helloworlde.github.io/2020/05/16/%E4%BD%BF%E7%94%A8%E8%87%AA%E5%AE%9A%E4%B9%89-Grafana-%E9%9D%A2%E6%9D%BF%E7%9B%91%E6%8E%A7-Consul/
- rocketmq-exporter使用记录
  - github地址：https://github.com/apache/rocketmq-exporter
  - 自己编译：
    - mvn clean install --settings settings-aliyun.xml -Dcheckstyle.skip
    - 运行：java -jar rocketmq-exporter-0.0.1-SNAPSHOT.jar --rocketmq.config.namesrvAddr="127.0.0.1:9876"

## 参考信息
- [基于 RocketMQ Prometheus Exporter 打造定制化 DevOps 平台](https://www.infoq.cn/article/NcSYj_2PQhBlqveuD1Kw?utm_source=related_read&utm_medium=article)