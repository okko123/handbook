### Prometheus-Operator监控Kong网关
1. 打开kong的prometheus插件。但插件打开后，访问http://kong-admin-ip:8001/metrics、访问http://kong-proxy-ip:8100/metrics，返回监控数据
2. 确认已经配置kong-admin、kong-proxy的svc
   ```bash
   cat > metrics.yaml <<EOF
   apiVersion: v1
   kind: Service
   metadata:
     labels:
       app.kubernetes.io/instance: kong-admin
       enable-metrics: "true"
     name: kong-admin-metrics
     namespace: kong
   spec:
     ports:
     - name: status
       port: 8100
       targetPort: 8100
     selector:
       app.kubernetes.io/instance: kong-admin
   ---
   apiVersion: v1
   kind: Service
   metadata:
     labels:
       app.kubernetes.io/instance: kong-proxy
       enable-metrics: "true"
     name: kong-proxy-metrics
     namespace: kong
   spec:
     ports:
     - name: status
       port: 8100
       targetPort: 8100
     selector:
       app.kubernetes.io/instance: kong-proxy
   EOF

   kubectl apply -f metrics.yaml

   # 检查，正常返回数据
   curl http://svc_ip:8100/metrics
   ```
3. 配置servicemonitor
   ```bash
   cat > monitor.yaml <<EOF
   kind: ServiceMonitor
   metadata:
     labels:
       k8s-app: kong-admin
     name: kong-admin
     namespace: monitoring
   spec:
     endpoints:
     - interval: 30s
       port: kong-admin
       relabelings:
       - replacement: k8s01
         targetLabel: env
     jobLabel: k8s-app
     namespaceSelector:
       matchNames:
       - kong
     selector:
       matchLabels:
         app.kubernetes.io/instance: kong-admin
         enable-metrics: "true"
   ---
   apiVersion: monitoring.coreos.com/v1
   kind: ServiceMonitor
   metadata:
     labels:
       k8s-app: kong-proxy
     name: kong-proxy
     namespace: monitoring
   spec:
     endpoints:
     - interval: 30s
       port: status
       relabelings:
       - replacement: k8s01
         targetLabel: env
     jobLabel: k8s-app
     namespaceSelector:
       matchNames:
       - kong
     selector:
       matchLabels:
         app.kubernetes.io/instance: kong-proxy
         enable-metrics: "true"
   EOF
   
   kubectl apply -f monitor.yaml
   ```