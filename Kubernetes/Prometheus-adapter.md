## Prometheus-adapter
- 每条规则大致分为四个部分：
  - Discovery，它指定适配器应如何查找此规则的所有 Prometheus 指标。
  - Association，它指定适配器应如何确定与特定指标关联的 Kubernetes 资源。
  - Name，它指定适配器应如何在自定义指标 API 中公开指标。
  - Querying，它指定如何将对一个或多个 Kubernetes 对象的特定指标的请求转换为对 Prometheus 的查询。
- 配置文件格式: 
```yaml
rules:
  # seriesQuery 指定 Prometheus 系列查询（传递给 Prometheus 中的 /api/v1/series 端点）
- seriesQuery: 'http_requests_total{kubernetes_namespace!="",kubernetes_pod_name!=""}'
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