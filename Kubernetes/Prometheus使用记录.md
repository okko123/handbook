## Prometheus使用记录
### prometheus-server部署，使用docker方式部署prometheus，在外部指定参数后，prometheus启动只会加载外部的参数，并将默认的启动参数去掉
```bash
docker run -d -p 9090:9090 \
--name prometheus-server \
-v /data/prometheus_data_9090:/prometheus \
prom/prometheus:v2.19.2 \
--config.file=/prometheus/prometheus.yml \
--storage.tsdb.path=/prometheus \
--storage.tsdb.retention.time 336h \
--web.console.libraries=/usr/share/prometheus/console_libraries \
--web.console.templates=/usr/share/prometheus/consoles \
--web.enable-lifecycle
```

### Exporter的部署
1. elasticsearch_exporter，使用docker方式部署
   ```bash
   docker run -d --rm --name=dev-es -p 9114:9114 justwatch/   elasticsearch_exporter:1.1.0 --es.uri="http://es-ip:port" --es.   shards --es.indices
   docker run -d --rm --name=QA3-es -p 9115:9114 justwatch/   elasticsearch_exporter:1.1.0 --es.uri="http://es-ip:port" --es.   shards --es.indices
   ```
2. node_exporter，使用systemd的方式运行
   ```bash
   wget https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz
   tar xf node_exporter-1.0.1.linux-amd64.tar.gz
   cp node_exporter-1.0.1.linux-amd64/node_exporter /usr/local/bin/node_exporter
   
   cat > /etc/systemd/system/node_exporter.service <<EEOOFF
   [Unit]
   Description=node_exporter
   Documentation=https://prometheus.io/
   After=network.target
   
   [Service]
   Type=simple
   User=nobody
   ExecStart=/usr/local/bin/node_exporter 
   Restart=on-failure
   
   [Install]
   WantedBy=multi-user.target
   EEOOFF

   systemctl daemon-reload
   systemctl start node_exporter
   systemctl enable node_exporter
   ```
3. mysqld_exporter，使用systemd的方式运行
   - 登录数据库，创建用户，并授权
   ```sql
   CREATE USER 'exporter'@'localhost' IDENTIFIED BY 'password' WITH MAX_USER_CONNECTIONS 3;
   GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'localhost';
   ```
   - 部署exporter
   ```bash
   wget https://github.com/prometheus/mysqld_exporter/releases/download/v0.12.1/mysqld_exporter-0.12.1.linux-amd64.tar.gz
   tar xf mysqld_exporter-0.12.1.linux-amd64
   cp mysqld_exporter-0.12.1.linux-amd64/mysqld_exporter /usr/local/bin/mysqld_exporter

   cat > etc/systemd/system/mysqld_exporter.service << EEOOFF
   [Unit]
   Description=mysqld_exporter
   Documentation=https://prometheus.io/
   After=network.target
   
   [Service]
   Type=simple
   User=nobody
   Environment=DATA_SOURCE_NAME=exporter:password@(ip/hostname:3306)/
   ExecStart=/usr/local/bin/mysqld_exporter
   Restart=on-failure
   
   [Install]
   WantedBy=multi-user.target
   EEOOFF

   systemctl daemon-reload
   systemctl start mysqld_exporter
   systemctl enable mysqld_exporter
   ```

### 在Kubernetes中部署Prometheus
- coreos提供的[部署文档](https://github.com/coreos/kube-prometheus)，必须注意：release版本有适配指定版本的Kubernetes
- 以1.18为例：
  ```bash
  git clone https://github.com/coreos/kube-prometheus.git
  #必须等待所有pods创建完毕，才能进行下一步操作
  kubectl create -f manifests/setup
  kubectl create -f manifests
  ```

### 修改prometheus的数据保存时间
- 修改k8s部署的Prometheus的数据保存时间，修改配置。
  ```bash
  # 在spec下添加，retention: 30d，配置保存数据时间为30天
  kubectl edit prometheus -n monitoring k8s
  ```
https://github.com/prometheus-operator/prometheus-operator/blob/0e6ed120261f101e6f0dc9581de025f136508ada/Documentation/prometheus.md
- 修改Prometheus的启动参数
  - 在启动参数中添加--storage.tsdb.retention.time=STORAGE.TSDB.RETENTION.TIME，指定保留数据的时间长度。默认保存15天，支持的单位U: y, w, d, h, m, s, ms.