### 调整kube-prometheus的镜像地址
1. 修改Prometheus的镜像地址
```bash
# 修改Prometheus配置，有密钥需要添加imagePullSecrets；修改image
kubectl edit -n monitoring prometheus k8s

imagePullSecrets:
- name: regcred

# 修改Prometheus-adapter配置
kubectl edit deployment -n monitoring prometheus-adapter

# 修改Prometheus-Operator配置，除了修改image地址外，还需要修改--prometheus-config-reloader的镜像地址
## 默认--prometheus-config-reloader=quay.io/prometheus-operator/prometheus-config-reloader:v0.53.1，需要替换为自定义的地址
## 例子--prometheus-config-reloader=nexus.example.com/prometheus-operator/prometheus-config-reloader:v0.53.1
kubectl edit deployment -n monitoring prometheus-operator
```
2. 修改alertmanager的镜像地址
```bash
kubectl edit -n monitoring alertmanager
```
3. 修改node_exporter的镜像地址
```bash
kubectl edit daemonset -n monitoring node-exporter 
```