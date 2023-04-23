## Prometheus Operator 自定义报警
---
### 配置PrometheusRule，创建容器网卡流量告警，当容器流量5分钟持续超过20MB，就触发告警
```bash
cat > prometheus-rules.yaml <<EOF
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  labels:
    prometheus: k8s
    role: alert-rules
  name: network-rules
  namespace: monitoring
spec:
  groups:
  - name: prometheus-operator-network
    rules:
    - alert: PodReceiveBytes
      annotations:
        message: Error network Receive over 20MB/s {{$labels.controller}} in {{$labels.namespace}}
          namespace.
      expr: |
        (irate(container_network_receive_bytes_total{namespace=~"default", interface="eth0", pod!~"consul-agent-....."}[1m])) > 20000000
      for: 2m
      labels:
        severity: critical
    - alert: PodTransmitBytes
      annotations:
        message: Errors network Transmit over 20MB/s {{$labels.controller}} in {{$labels.namespace}}
          namespace.
      expr: |
        (irate(container_network_transmit_bytes_total{namespace=~"default", interface="eth0", pod!~"consul-agent-....."}[1m])) > 20000000
      for: 2m
      labels:
        severity: critical

kubectl apply -f prometheus-ruls.yaml
```
---
### 查看自定义规则
```bash
kubectl get prometheusrules -n monitoring
```