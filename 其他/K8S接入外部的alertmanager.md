### K8S接入外部的alertmanager
```bash
# 添加外部alertmanager配置
cat > alertmanager-config.yaml <<"EOF"
- scheme: http
  static_configs:
    - targets: ['192.168.0.1:9093']
EOF

kubectl create secret generic am-config --from-file=alertmanager-config.yaml

# 修改k8s集群内部的配置，添加以下内容
cat > prometheus-patch.yaml <<'EOF'
spec:
  additionalAlertManagerConfigs:
    key: alertmanager-config.yaml
    name: am-config
EOF

# 获取Prometheus对象
kubectl get prometheus -n monitoring
NAME   VERSION   REPLICAS   AGE
k8s    2.32.1    2          438d

kubectl patch prometheus k8s --patch "$(cat prometheus-patch.yaml)" --type=merge
```
---
### 参考信息
- [集成自建Prometheus告警](https://www.alibabacloud.com/help/zh/arms/alarm-operation-center/integrate-self-managed-prometheus-instances-with-arms)