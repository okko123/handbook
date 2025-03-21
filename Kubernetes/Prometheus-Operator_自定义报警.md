### 添加自定义监控
---
> 一个自定义监控的步骤也是非常简单的。
  1. 第一步建立一个 ServiceMonitor 对象，用于 Prometheus 添加监控项
  2. 第二步为 ServiceMonitor 对象关联 metrics 数据接口的一个 Service 对象
  3. 第三步确保 Service 对象可以正确获取到 metrics 数据
---
### 
> 在 Prometheus Dashboard 的 Config 页面下面查看关于 AlertManager 的配置：
  ```yaml
  alerting:
    alert_relabel_configs:
    - separator: ;
      regex: prometheus_replica
      replacement: $1
      action: labeldrop
    alertmanagers:
    - follow_redirects: true
      scheme: http
      path_prefix: /
      timeout: 10s
      api_version: v2
      relabel_configs:
      - source_labels: [__meta_kubernetes_service_name]
        separator: ;
        regex: alertmanager-main
        replacement: $1
        action: keep
      - source_labels: [__meta_kubernetes_endpoint_port_name]
        separator: ;
        regex: web
        replacement: $1
        action: keep
      kubernetes_sd_configs:
      - role: endpoints
        kubeconfig_file: ""
        follow_redirects: true
        namespaces:
          names:
          - monitoring
  ```
> 上面 alertmanagers 实例的配置我们可以看到是通过角色为 endpoints 的 kubernetes 的服务发现机制获取的，匹配的是服务名为 alertmanager-main，端口名未 web 的 Service 服务，我们查看下 alertmanager-main 这个 Service：
  ```yaml
  Name:              alertmanager-main
  Namespace:         monitoring
  Labels:            app.kubernetes.io/component=alert-router
                     app.kubernetes.io/instance=main
                     app.kubernetes.io/name=alertmanager
                     app.kubernetes.io/part-of=kube-prometheus
                     app.kubernetes.io/version=0.23.0
  Annotations:       <none>
  Selector:          app.kubernetes.io/component=alert-router,app.kubernetes.io/instance=main,app.kubernetes.io/name=alertmanager,app.kubernetes.io/part-of=kube-prometheus
  Type:              ClusterIP
  IP Family Policy:  SingleStack
  IP Families:       IPv4
  IP:                172.4.33.213
  IPs:               172.4.33.213
  Port:              web  9093/TCP
  TargetPort:        web/TCP
  Endpoints:         192.168.162.148:9093,192.168.169.250:9093,192.168.189.168:9093
  Port:              reloader-web  8080/TCP
  TargetPort:        reloader-web/TCP
  Endpoints:         192.168.162.148:8080,192.168.169.250:8080,192.168.189.168:8080
  Session Affinity:  ClientIP
  Events:            <none>
  ```
> 可以看到服务名正是 alertmanager-main，Port 定义的名称也是 web，符合上面的规则，所以 Prometheus 和 AlertManager 组件就正确关联上了。而对应的报警规则文件位于：/etc/prometheus/rules/prometheus-k8s-rulefiles-0/目录下面所有的 YAML 文件。
```yaml
$ kubectl exec -it prometheus-k8s-0 /bin/sh -n monitoring
kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl exec [POD] -- [COMMAND] instead.

/prometheus $ ls /etc/prometheus/rules/prometheus-k8s-rulefiles-0/
monitoring-alertmanager-main-rules-5e5d98da-5de0-4f6f-acb3-dd0df538c9cb.yaml          monitoring-node-exporter-rules-17b3100e-f3a0-4d11-8a28-fb6f8ec50670.yaml
monitoring-kube-prometheus-rules-1b2832b2-a5db-4189-9b6d-542cc418ba68.yaml            monitoring-prometheus-k8s-prometheus-rules-1ea0c171-6886-42dd-be7d-b9ec3cf7914e.yaml
monitoring-kube-state-metrics-rules-87a2e9d6-39ce-4459-b29c-9aa6b46c9111.yaml         monitoring-prometheus-operator-rules-49213423-d1f1-40c1-a5d9-ed1928014533.yaml
monitoring-kubernetes-monitoring-rules-9e133b4e-43fa-4890-b1fb-e1829ea7bc67.yaml
```
> 我们这里的 PrometheusRule 的 name 为 prometheus-k8s-rules，namespace 为 monitoring

> 我们可以猜想到我们创建一个 PrometheusRule 资源对象后，会自动在上面的 prometheus-k8s-rulefiles-0 目录下面生成一个对应的<namespace>-<name>.yaml文件，所以如果以后我们需要自定义一个报警选项的话，只需要定义一个 PrometheusRule 资源对象即可。

> 至于为什么 Prometheus 能够识别这个 PrometheusRule 资源对象呢？这就需要查看我们创建的 prometheus 这个资源对象了，里面有非常重要的一个属性 ruleSelector，用来匹配 rule 规则的过滤器，要求匹配具有 prometheus=k8s 和 role=alert-rules 标签的 PrometheusRule 资源对象

---
- 参考信息
1. [Prometheus Operator 自定义报警](https://www.qikqiak.com/post/prometheus-operator-custom-alert/)
2. [Prometheus Operator 监控 etcd 集群](https://www.qikqiak.com/post/prometheus-operator-monitor-etcd/)