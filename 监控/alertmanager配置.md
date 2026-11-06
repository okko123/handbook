## alertmanager配置
- alertmanager的配置文件

  ```yaml
  # cat alertmanager.yml

  global:
    resolve_timeout: 5m
    smtp_smarthost: smtp.exmail.qq.com:465
    smtp_from: admin@example
    smtp_auth_username: admin@example
    smtp_auth_password: example
    smtp_require_tls: false
  templates:
    - '/usr/local/alertmanager/template/*.tmpl'

  route:
    # 1. 根路由：设置一个安全的默认分组，避免告警合并乱炖
    group_by: [namespace, alertname]
    group_wait: 30s
    group_interval: 5m
    repeat_interval: 1h
    receiver: Default

    routes:
      # 2. 核心路由：先处理最特殊的场景（关键组件的 Critical 告警）
      # 将其放在最上面，且不加 continue，匹配到直接送走，不再往下漏
      - matchers:
          - severity="critical"
          - component=~"zookeeper|kafka"
        group_by: [namespace, instance, alertname]
        receiver: Critical

      # 3. 通用的 Critical 告警
      - matchers:
          - severity="critical"
        group_by: [namespace, instance, alertname]
        group_wait: 30s
        group_interval: 5m
        receiver: Default

      # 4. 通用的 Warning 告警
      - matchers:
          - severity="warning"
        group_by: [namespace, alertname]
        group_wait: 10s
        group_interval: 10m
        receiver: Default

  inhibit_rules:
    - equal:
      - namespace
      - alertname
      - instance
      source_match:
        severity: critical
      target_match_re:
        severity: warning|info

    - equal:
      - namespace
      - alertname
      source_match:
        severity: warning
      target_match_re:
        severity: info

  receivers:
    - name: Default
      email_configs:
      - to: example@example.cn

    - name: Critical
      email_configs:
      - to: example@example.cn
  ```