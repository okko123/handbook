## 使用 Prometheus-Operator 监控 traefik

1. 修改traefik的deployment，启用Metrics
   ```bash
   kubectl edit deployment traefik -n traefik
   在spec.template.spec.containers.args添加--metrics.prometheus
   ```
2. 创建service，暴露traefik的metrics接口
   ```bash
   cat > traefik-metrics.yaml <<EOF
   apiVersion: v1
   kind: Service
   metadata:
     labels:
       k8s-app: traefik-ingress
     name: traefik-metrics
     namespace: traefik
   spec:
     ports:
     - name: traefik
       port: 9000
       protocol: TCP
       targetPort: traefik
     selector:
       app.kubernetes.io/instance: traefik
       app.kubernetes.io/name: traefik
   EOF
   ```
3. 修改clusterrole
   ```bash
   # 直接编辑kubectl edit clusterrole prometheus-k8s，或者使用一下的yaml进行覆盖
   cat > prometheus-k8s.yaml <<EOF
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRole
   metadata:
     name: prometheus-k8s
   rules:
   - apiGroups:
     - ""
     resources:
     - nodes/metrics
     - endpoints
     - pods
     - services
     verbs:
     - get
     - list
     - watch
   - nonResourceURLs:
     - /metrics
     verbs:
     - get
   EOF

   kubectl apply -f prometheus-k8s.yaml
   ```
4. 添加servicemonitor
   ```bash
   cat > traefik-monitor.yaml<<EOF
   apiVersion: monitoring.coreos.com/v1
   kind: ServiceMonitor
   metadata:
     name: traefik-ingress
     namespace: monitoring
     labels:
       k8s-app: traefik-ingress
   spec:
     jobLabel: k8s-app
     endpoints:
     - port: traefik
       interval: 30s
     selector:
       matchLabels:
         k8s-app: traefik-ingress
     namespaceSelector:
       matchNames:
       - traefik
   EOF