## volcano 的调度器使用
- 要求k8s集群，安装kube-prometheus

- 安装volcano-descheduler
  ```bash
  kubectl create ns volcano-system
  kubectl apply -f https://raw.githubusercontent.com/volcano-sh/descheduler/refs/heads/main/installer/volcano-descheduler-development.yaml
  ```
- 修改配置
  ```bash
  kubectl edit configmap -n volcano-system volcano-descheduler

  apiVersion: v1
  data:
    policy.yaml: |
      apiVersion: "descheduler/v1alpha2"
      kind: "DeschedulerPolicy"
      # 选择带有node-role.kubernetes.io/worker=true 标签的节点
      nodeSelector: node-role.kubernetes.io/worker=true
      nodeFit: true
      profiles:
      - name: default
        pluginConfig:
        - args:
            ignorePvcPods: true
            nodeFit: true
            priorityThreshold:
              value: 10000
            evictLocalStoragePods: true
          name: DefaultEvictor
        - args:
            # 排除的namespace
            evictableNamespaces:
              exclude:
              - kube-system
              - kuboard
              - traefik
              - neuvector
              - airflow
              - monitoring
            metrics:
              # 设置Prometheus的源地址
              address: "http://prometheus-k8s.monitoring.svc:9090"
              type: prometheus
            targetThresholds:
              cpu: 70
              memory: 70
            thresholds:
              cpu: 40
              memory: 40
          name: LoadAware
        plugins:
          balance:
            enabled:
            - LoadAware
  kind: ConfigMap
  metadata:
    name: volcano-descheduler
    namespace: volcano-system
  ```