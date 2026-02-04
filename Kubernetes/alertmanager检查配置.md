## alertmanager使用笔记
- alertmanager版本0.25
- 配置文件alertmanager.yaml结构
  ```yaml
  global:

  # 设置路由
  route:

  # 设置接收的用户
  receivers:

  # 配置抑制策略
  inhibit_rules:

  # 设置静音或激活的时间
  time_intervals:
  ```
- alertmanage.yaml例子
  ```yaml
  global:
    smtp_from: example1@qq.com
    smtp_smarthost: smtp.qq.com:465
    smtp_hello: localhost
    smtp_auth_username: example1@qq.com
    smtp_auth_password: example
    smtp_require_tls: false
    resolve_timeout: 5m

  route:
    receiver: 'default-receiver'
    group_wait: 30s
    group_interval: 5m
    repeat_interval: 4h
    group_by: [cluster, alertname]
    routes:
    - receiver: "ops-receiver"
      group_wait: 10s
      match:
        severity: "critical"
        service: "OpenLDAP"
      active_time_intervals:
      - offhours
      - holidays
  receivers:
  - name: default-receiver
    email_configs:
    - to: example1@qq.com
    - to: example2@qq.com
  
  - name: ops-receiver
    email_configs:
    - to: example1@qq.com

  inhibit_rules:

  time_intervals:
  - name: offhours
    time_intervals:
    - times:
      - start_time: 09:00
        end_time: 21:00
      weekdays: ['monday:friday']
      location: Asia/Shanghai

  - name: holidays
    time_intervals:
    - times:
      - start_time: 00:00
        end_time: 24:00
      weekdays: ['saturday','sunday']
      location: Asia/Shanghai
  ```
### alertmanager检查配置
```bash
./amtool check-config alertmanager.yml
```
### 使用systemd启动alertmanager
```bash
mkdir -p /data/alertmanager/

cat >/etc/systemd/system/alertmanager.service <<EOF
[Unit]
Description=Alertmanager
After=user.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/alertmanager-0.25.0/alertmanager --config.file=/usr/local/alertmanager-0.25.0/alertmanager.yml --storage.path=/data/alertmanager-data/

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start alertmanager
systemctl enable alertmanager
```
---
- [alertmanager的配置文档](https://prometheus.io/docs/alerting/latest/configuration/)
- [AlertManager实现webhook告警(使用Postman测试)](https://mdnice.com/writing/feada191df9d4d7885b170fda93853c0)