## Prometheus-operator 监控报错
> 在Prometheus的告警页面中出现：KubeControllerManagerDown、KubeSchedulerDown；根据ServiceMonitor -> Service -> endpoints(pod) 服务发现机制，查看到KubeControllerManager、KubeScheduler没有对应的svc，所以我们需要创建对应的svc。需要注意，1.18下，kube-controller-manager的labels为component=kube-scheduler，kube-scheduler的labels为component=kube-scheduler
- 检查kube-controller-manager、kube-scheduler的配置文件
  ```bash
  kubectl get servicemonitor kube-controller-manager -n monitoring -o yaml
  # 输出内容：注意检查selector下的matchLabels，service的labes需要与其匹配上，port的名字需要与service的port名对应上
  apiVersion: monitoring.coreos.com/v1
  kind: ServiceMonitor
  metadata:
    annotations:
    labels:
      k8s-app: kube-controller-manager
    name: kube-controller-manager
    namespace: monitoring
  
    省略部分内容

      port: http-metrics
    jobLabel: k8s-app
    namespaceSelector:
      matchNames:
      - kube-system
    selector:
      matchLabels:
        k8s-app: kube-controller-manager
  ```
- 添加kube-proxy的配置文件
  ```bash
  cat > kube-proxy.yaml <<EOF
  apiVersion: monitoring.coreos.com/v1
  kind: ServiceMonitor
  metadata:
    labels:
      app.kubernetes.io/name: kube-proxy
      app.kubernetes.io/part-of: kube-prometheus
    name: kube-proxy
    namespace: monitoring
  spec:
    endpoints:
    - bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
      interval: 30s
      port: https-metrics
      scheme: http
      tlsConfig:
        insecureSkipVerify: true
    jobLabel: app.kubernetes.io/name
    namespaceSelector:
      matchNames:
      - kube-system
    selector:
      matchLabels:
        app.kubernetes.io/name: kube-proxy
  EOF

  kubectl apply -f kube-proxy.yaml
  ```
- 由于kube-controller-manager的http监听端口为10252；kube-scheduler的http监听端口为10251，由于1.18以后，kube-controller-manager、kube-scheduler关闭http端口的监听，使用https端口监听：kube-controller-manager端口10257 kube-scheduler端口10259。因此需要添加https的监听端口
  ```bash
  cat > fix.yaml <<EOF
  kind: Service
  apiVersion: v1
  metadata:
     name: kube-controller-manager
     labels:
       k8s-app: kube-controller-manager
       app.kubernetes.io/name: kube-controller-manager
     namespace: kube-system
  spec:
     selector:
       component: kube-controller-manager
     clusterIP: None
     ports:
       - name: http-metrics
         port: 10252
         targetPort: 10252
         protocol: TCP
       - name: https-metrics
         port: 10257
         targetPort: 10257
         protocol: TCP
  ---
  kind: Service
  apiVersion: v1
  metadata:
     name: kube-scheduler
     labels:
       k8s-app: kube-scheduler
       app.kubernetes.io/name: kube-scheduler
     namespace: kube-system
  spec:
     selector:
       component: kube-scheduler
     clusterIP: None
     ports:
       - name: http-metrics
         port: 10251
         targetPort: 10251
         protocol: TCP
       - name: https-metrics
         port: 10259
         targetPort: 10259
         protocol: TCP
  ---
  kind: Service
  apiVersion: v1
  metadata:
     name: kube-proxy
     labels:
       k8s-app: kube-proxy
       app.kubernetes.io/name: kube-proxy
     namespace: kube-system
  spec:
     selector:
       k8s-app: kube-proxy
     clusterIP: None
     ports:
       - name: http-metrics
         port: 10256
         targetPort: 10256
         protocol: TCP
       - name: https-metrics
         port: 10249
         targetPort: 10249
         protocol: TCP
  EOF
  kubectl apply -f fix.yaml
  ```
- 由于kube-controller-manager和kube-scheduler默认监听的IP为：127.0.0.1，需要修改kube-controller-manager和kube-scheduler配置，让其绑定到0.0.0.0。配置文件所在目录/etc/kubernetes/manifests。
  1. 修改kube-controller-manager.yaml中--bind-address=0.0.0.0
  2. 修改kube-scheduler.yaml中--bind-address=0.0.0.0
  3. 重启kubelet；systemctl restart kubelet
  4. 测试curl -I -k https://IP:10257/healthz，返回200即为正常
- kube-proxy默认监听127.0.0.1地址，需要修改configmap
  1. kubectl  edit configmap -n kube-system kube-proxy。metricsBindAddress修改为0.0.0.0
  2. 重启kube-proxy。kubectl rollout restart daemonset kube-proxy -n kube-system
---
### 修改alertmanager的配置
- 获取alertmanager的配置文件
  ```bash
  kubectl get secrets -n monitoring alertmanager-main -o yaml

  # alertmanager.yaml的字符串进行base64解密
  echo "Imdsb2JhbCI6CiAgInJlc29sdmVfdGltZW91dCI6ICI1bSIKImluaGliaXRfcnVsZXMiOgotICJlcXVhbCI6CiAgLSAibmFtZXNwYWNlIgogIC0gImFsZXJ0bmFtZSIKICAic291cmNlX21hdGNoIjoKICAgICJzZXZlcml0eSI6ICJjcml0aWNhbCIKICAidGFyZ2V0X21hdGNoX3JlIjoKICAgICJzZXZlcml0eSI6ICJ3YXJuaW5nfGluZm8iCi0gImVxdWFsIjoKICAtICJuYW1lc3BhY2UiCiAgLSAiYWxlcnRuYW1lIgogICJzb3VyY2VfbWF0Y2giOgogICAgInNldmVyaXR5IjogIndhcm5pbmciCiAgInRhcmdldF9tYXRjaF9yZSI6CiAgICAic2V2ZXJpdHkiOiAiaW5mbyIKInJlY2VpdmVycyI6Ci0gIm5hbWUiOiAiRGVmYXVsdCIKLSAibmFtZSI6ICJXYXRjaGRvZyIKLSAibmFtZSI6ICJDcml0aWNhbCIKInJvdXRlIjoKICAiZ3JvdXBfYnkiOgogIC0gIm5hbWVzcGFjZSIKICAiZ3JvdXBfaW50ZXJ2YWwiOiAiNW0iCiAgImdyb3VwX3dhaXQiOiAiMzBzIgogICJyZWNlaXZlciI6ICJEZWZhdWx0IgogICJyZXBlYXRfaW50ZXJ2YWwiOiAiMTJoIgogICJyb3V0ZXMiOgogIC0gIm1hdGNoIjoKICAgICAgImFsZXJ0bmFtZSI6ICJXYXRjaGRvZyIKICAgICJyZWNlaXZlciI6ICJXYXRjaGRvZyIKICAtICJtYXRjaCI6CiAgICAgICJzZXZlcml0eSI6ICJjcml0aWNhbCIKICAgICJyZWNlaXZlciI6ICJDcml0aWNhbCI="|base64 -d
  ```
- 修改完成后，再使用base64进行编码。然后更新kubectl edit secrets -n monitoring alertmanager-main
  ```bash
  cat > tmp.yaml <<"EOF"
  "global":
    "resolve_timeout": "5m"
  "inhibit_rules":
  - "equal":
    - "namespace"
    - "alertname"
    "source_match":
      "severity": "critical"
    "target_match_re":
      "severity": "warning|info"
  - "equal":
    - "namespace"
    - "alertname"
    "source_match":
      "severity": "warning"
    "target_match_re":
      "severity": "info"
  "receivers":
  - "name": "Default"
  - "name": "Watchdog"
  - "name": "Critical"
  "route":
    "group_by":
    - "namespace"
    "group_interval": "5m"
    "group_wait": "30s"
    "receiver": "Default"
    "repeat_interval": "12h"
    "routes":
    - "match":
        "alertname": "Watchdog"
      "receiver": "Watchdog"
    - "match":
        "severity": "critical"
      "receiver": "Critical"
  EOF
  cat tmp.yaml | base64 -w 0
  ```
## 参考连接
- [容器云平台No.7~kubernetes监控系统prometheus-operator](https://zhuanlan.zhihu.com/p/258344576)