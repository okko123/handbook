## 使用 Prometheus-Operator 监控 ETCD
1. 将ETCD的证书存入 Kubernetes。
   ```bash
   kubectl create secret generic etcd-certs \
   --from-file=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
   --from-file=/etc/kubernetes/pki/etcd/healthcheck-client.key \
   --from-file=/etc/kubernetes/pki/etcd/ca.crt \
   -n monitoring

   # 检查刚刚创建的资源
   kubectl get secret etcd-certs -n monitoring 
   ```
2. 将证书挂入 Prometheus
   ```bash
   kubectl edit prometheus k8s -n monitoring

   apiVersion: monitoring.coreos.com/v1
   kind: Prometheus
   metadata:
     creationTimestamp: "2020-08-19T03:54:50Z"
     generation: 2
     labels:
       prometheus: k8s
     name: k8s
     namespace: monitoring
   spec:
     alerting:
       alertmanagers:
       - name: alertmanager-main
         namespace: monitoring
         port: web
     image: quay.io/prometheus/prometheus:v2.15.2
     nodeSelector:
       kubernetes.io/os: linux
     podMonitorNamespaceSelector: {}
     podMonitorSelector: {}
     replicas: 2
     resources:
       requests:
         memory: 400Mi
     ruleSelector:
       matchLabels:
         prometheus: k8s
         role: alert-rules
     secrets:    # 新增配置，将etcd证书挂入Prometheus中
     - etcd-certs
     securityContext:
       fsGroup: 2000
       runAsNonRoot: true
       runAsUser: 1000
     serviceAccountName: prometheus-k8s
     serviceMonitorNamespaceSelector: {}
     serviceMonitorSelector: {}
     version: v2.15.2

   ```
3. 更新完成后就可以在 Prometheus Pod 中看到上面挂入的 etcd 证书，我们可以进入 Pod 中查看：
   ```bash
   kubectl exec -it prometheus-k8s-0 /bin/sh -n monitoring
   /prometheus $ ls /etc/prometheus/secrets/etcd-certs/
   ca.crt                  healthcheck-client.crt  healthcheck-client.key
   ```
4. 创建 Etcd Service
   ```bash
   cat > etcd-service.yaml <<EOF
   kind: Service
   apiVersion: v1
   metadata:
      name: etcd
      labels:
        k8s-app: etcd
      namespace: kube-system
   spec:
      selector:
        component: etcd
      clusterIP: None
      ports:
        - protocol: TCP
          port: 2379
          targetPort: 2379
          name: https-metrics
   EOF

   kubectl apply -f etcd-service.yaml
   ```
5. 创建ServiceMonitor
   ```bash
   cat > etcd-monitor.yaml <<EOF
   apiVersion: monitoring.coreos.com/v1
   kind: ServiceMonitor
   metadata:
     name: etcd-k8s
     namespace: monitoring
     labels:
       k8s-app: etcd-k8s
   spec:
     jobLabel: k8s-app
     endpoints:
     - port: https-metrics
       interval: 30s
       scheme: https
       tlsConfig:
         caFile: /etc/prometheus/secrets/etcd-certs/ca.crt
         certFile: /etc/prometheus/secrets/etcd-certs/healthcheck-client.crt
         keyFile: /etc/prometheus/secrets/etcd-certs/healthcheck-client.key
         insecureSkipVerify: true
     selector:
       matchLabels:
         k8s-app: etcd
     namespaceSelector:
       matchNames:
       - kube-system
   EOF

   kubectl apply -f etcd-monitor.yaml
   ```
在grafana中，导入3070的仪表盘

## 参考信息
[使用 Prometheus Operator 监控 Kubernetes Etcd](http://www.mydlq.club/article/18/)