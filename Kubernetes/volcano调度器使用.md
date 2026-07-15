## volcano 的调度器使用
- 要求k8s集群，安装kube-prometheus
- 安装volcano-descheduler
  ```bash
  kubectl create ns volcano-system
  kubectl apply -f https://raw.githubusercontent.com/volcano-sh/descheduler/refs/heads/main/installer/volcano-descheduler-development.yaml
  ```
- volcano的configmap修改配置
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
- 修改Prometheus的抓取间隔，否则descheduler的日志中会报错irate查询cpu指标，没有数据
  ```bash
  kubectl edit servicemonitor -n monitoring kubelet

  # 将cpu资源的抓取间隔由30s修改为15s
  - bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
    honorLabels: true
    honorTimestamps: false
    interval: 15s
    metricRelabelings:
    - action: drop
      regex: container_(network_tcp_usage_total|network_udp_usage_total|tasks_state|cpu_load_average_10s)


  ```
---
### 遇到的问题
- 执行间隔
  > cronTab定时任务: 指定参数--descheduling-interval-cron-expression='0 0 * * *'，表示每天凌晨运行一次重调度。

  > 固定间隔: 指定参数--descheduling-interval=10m，表示每10分钟运行一次重调度。

  > 请注意，--descheduling-interval的优先级高于--descheduling-interval-cron-expression，当两个参数都设置时，descheduler 的行为以--descheduling-interva设置的为准。
- 配置层级问题，相同的配置可以在不同层级上配置。nodeSelector如果不在最顶层配置，则会在loadward中进行扫描
---
### 参考连接
- [负载感知重调度](https://volcano.sh/zh-Hans/docs/KeyFeatures/LoadAwareDescheduling)
- [Descheduler for Kubernetes](https://github.com/kubernetes-sigs/descheduler/tree/master)