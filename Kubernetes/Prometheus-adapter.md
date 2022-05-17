## Prometheus-adapter
---
> kubernetes的监控指标分为两种：
  - Core metrics(核心指标)：从 Kubelet、cAdvisor 等获取度量数据，再由metrics-server提供给 Dashboard、HPA 控制器等使用。
  - Custom Metrics(自定义指标)：由Prometheus Adapter提供API custom.metrics.k8s.io，由此可支持任意Prometheus采集到的指标。
> 核心指标只包含node和pod的cpu、内存等，一般来说，核心指标作HPA已经足够，但如果想根据自定义指标:如请求qps/5xx错误数来实现HPA，就需要使用自定义指标了，目前Kubernetes中自定义指标一般由Prometheus来提供，再利用k8s-prometheus-adpater聚合到apiserver，实现和核心指标（metric-server)同样的效果。

> Prometheus可以采集其它各种指标，但是prometheus采集到的metrics并不能直接给k8s用，因为两者数据格式不兼容，因此还需要另外一个组件(kube-state-metrics)，将prometheus的metrics数据格式转换成k8s API接口能识别的格式，转换以后，因为是自定义API，所以还需要用Kubernetes aggregator在主API服务器中注册，以便直接通过/apis/来访问。

> 以下是官方metrics的项目介绍：
  - Resource Metrics API（核心api）
    - Heapster
    - Metrics Server
  - Custom Metrics API：
    - Prometheus Adapter
    - Microsoft Azure Adapter
    - Google Stackdriver
    - Datadog Cluster Agent

---
- 适配器通过一组“发现”规则确定要公开哪些指标以及如何公开它们。 每个规则都是独立执行的（因此请确保您的规则是互斥的），并指定适配器在 API 中公开指标所需采取的每个步骤。
- 每条规则大致分为四个部分：
  - Discovery，它指定适配器应如何查找此规则的所有 Prometheus 指标。
  - Association，它指定适配器应如何确定与特定指标关联的 Kubernetes 资源。
  - Name，它指定适配器应如何在自定义指标 API 中公开指标。
  - Querying，它指定如何将对一个或多个 Kubernetes 对象的特定指标的请求转换为对 Prometheus 的查询。
- 配置文件格式: 
```yaml
rules:
  # seriesQuery 指定 Prometheus 系列查询（传递给 Prometheus 中的 /api/v1/series 端点）。查询http_requests.*_total的指标
- seriesQuery: '{__name__=~"^http_requests.*_total$",container!="POD",namespace!="",pod!=""}'
  resources:
    overrides:
      kubernetes_namespace: {resource: "namespace"}
      kubernetes_pod_name: {resource: "pod"}
  name:
    matches: "^(.*)_total"
    as: "${1}_per_second"
  metricsQuery: 'sum(rate(<<.Series>>{<<.LabelMatchers>>}[2m])) by (<<.GroupBy>>)'
- {}
```
- [Prometheus Adapter for Kubernetes Metrics APIs](https://github.com/kubernetes-sigs/prometheus-adapter)
- [配置例子](https://github.com/kubernetes-sigs/prometheus-adapter/blob/master/docs/sample-config.yaml)
- [Configuration Walkthroughs](https://github.com/kubernetes-sigs/prometheus-adapter/blob/master/docs/config-walkthrough.md)
- [Metrics Discovery and Presentation Configuration](https://github.com/kubernetes-sigs/prometheus-adapter/blob/master/docs/config.md)
- [Kubernetes HPA：基于 Prometheus 自定义指标的可控弹性伸缩](https://mp.weixin.qq.com/s/Sps6vATVf11CgFtXtsrO2w)