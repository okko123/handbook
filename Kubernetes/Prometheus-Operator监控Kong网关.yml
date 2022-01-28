## Prometheus-Operator监控Kong网关

cat > kong-monitoring.yaml <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  annotations:
    meta.helm.sh/release-name: kong-admin
    meta.helm.sh/release-namespace: kong
  labels:
    app.kubernetes.io/instance: kong-admin
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: kong
    app.kubernetes.io/version: "2.7"
    helm.sh/chart: kong-2.6.4
  name: kong-admin-kong
  namespace: kong
spec:
  endpoints:
  - scheme: http
    targetPort: status
  jobLabel: kong-admin
  namespaceSelector:
    matchNames:
    - kong
  selector:
    matchLabels:
      app.kubernetes.io/instance: kong-admin
      app.kubernetes.io/managed-by: Helm
      app.kubernetes.io/name: kong
      app.kubernetes.io/version: "2.7"
      helm.sh/chart: kong-2.6.4
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  annotations:
    meta.helm.sh/release-name: kong-proxy
    meta.helm.sh/release-namespace: kong
  labels:
    app.kubernetes.io/instance: kong-proxy
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: kong
    app.kubernetes.io/version: "2.7"
    helm.sh/chart: kong-2.6.4
  name: kong-proxy-kong
  namespace: kong
spec:
  endpoints:
  - scheme: http
    targetPort: status
  jobLabel: kong-proxy
  namespaceSelector:
    matchNames:
    - kong
  selector:
    matchLabels:
      app.kubernetes.io/instance: kong-proxy
      app.kubernetes.io/managed-by: Helm
      app.kubernetes.io/name: kong
      app.kubernetes.io/version: "2.7"
      helm.sh/chart: kong-2.6.4
EOF