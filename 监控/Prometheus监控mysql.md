## Prometheus监控mysql
### 准备
- Prometheus: 2.37.5
- MySQL_exporter: 0.15.1
- MySQL: 5.7

1. mysql端配置
   ```bash
   # 创建用户并授权
   CREATE USER 'exporter'@'localhost' IDENTIFIED BY 'XXXXXXXX' WITH MAX_USER_CONNECTIONS 3;
   GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'localhost';
   ```
2. MySQL_Exporter配置
   ```bash
   # 创建exporter的配置文件，用于储存用户名和密码
   cat > my.cnf <<EOF
   [client]
   user=exporter
   password=123456

   # 启动exporter
   ./mysqld_exporter -config.my-cnf=".my.cnf" &
   ss -tln |grep 9104

   # 使用systemd管理
   cat > /etc/systemd/system/mysqld_exporter.service <<EOF
   [Unit]
   Description=mysqld_exporter
   After=network.target

   [Service]
   Type=simple
   ExecStart=/usr/local/mysqld_exporter/mysqld_exporter --config.my-cnf=/usr/local/mysqld_exporter/.my.cnf
   Restart=on-failure

   [Install]
   WantedBy=multi-user.target
   EOF

   systemctl daemon-reload
   systemctl start mysqld_exporter
   systemctl enable mysqld_exporter

   # exporter多实例监控配置
   
   curl http://localhost:9104/probe?target=mysql_IP_address:3306&auth_module=client
   
   1. 要使用多目标功能，请向端点 /probe?target=mysql_IP_address:3306 发送 http 请求，其中 target 设置为要从中抓取指标的 MySQL 实例的 DSN。

   2. 为避免将用户名和密码等敏感信息放在 URL 中，您可以在 config.my-cnf 文件中拥有多个配置，并通过向请求添加 &auth_module=<section> 来匹配它。
   ```
3. Prometheus配置
   ```bash
   vim prometheus.yml
     - job_name: 'mysql'
       metrics_path: /probe
       relabel_configs:
         - source_labels: [__address__]
           target_label: __param_target
         - source_labels: [__param_target]
           target_label: instance
         - target_label: __address__
           replacement: exporter_ip_address:9104
         - source_labels: [auth_module]
           target_label: __param_auth_module
         - action: labeldrop
           regex: auth_module
       file_sd_configs:
       - files:
         - sd_configs/mysql.json

   vim sd_configs/mysql.json
   [
       {
           "targets": [
               "192.168.0.42:3306",
               "192.168.0.43:3306",
               "192.168.0.45:3306",
               "192.168.0.46:3306",
               "192.168.0.47:3306"
           ],
           "labels": {
               "auth_modeule": "client",
               "component": "mysql",
               "job": "mysql"
           }
       }
   ]

   # 重启Prometheus
   systemctl restart prometheus

   # 或者通过命令热加载
   curl  -XPOST localhost:9090/-/reload
   ```
4. Grafana导入对应dashboard。https://github.com/prometheus/mysqld_exporter/tree/main/mysqld-mixin/dashboards
---
### 参考信息
1. [mysqld_exporter的GitHub主页](https://github.com/prometheus/mysqld_exporter)
2. [技术分享 | mysqld_exporter 收集多个 MySQL 监控避坑](https://opensource.actionsky.com/20221206-mysql/)