
## 记录filebeat配置
### 使用的filebeat版本为6.8.10

```yml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /data/logs/run-1.log
  fields_under_root: false
  fields:
    topic_log: file_logging

- type: log
  enabled: true
  paths:
    - /data/logs/run.log
  multiline.negate: true
  multiline.pattern: '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
  multiline.match: after
  fields_under_root: false
  fields:
    topic_log: file_logging

filebeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: false

fields:
  APP_NAME: ${APP_NAME}

output.kafka:
  hosts: ["172.16.0.1:9092"]
  topic: "%{[fields.topic_log]}"
  required_acks: 1

processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~
```