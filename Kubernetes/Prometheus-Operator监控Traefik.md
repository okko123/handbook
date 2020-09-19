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
     annotations:
       meta.helm.sh/release-name: traefik
       meta.helm.sh/release-namespace: traefik
     labels:
       app.kubernetes.io/instance: traefik
       app.kubernetes.io/managed-by: Helm
       app.kubernetes.io/name: traefik
       helm.sh/chart: traefik-8.13.1
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
   ```
