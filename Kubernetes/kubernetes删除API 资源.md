## 删除API 资源
- 检查API资源
  ```bash
  # 列出可用的 API 资源。
  kubectl api-resources

  # 查看集群支持的APIService
  kubectl get apiservices

  # 列出可用的 API 版本。
  kubectl api-versions
  ```
- 删除API资源
  ```bash
  kubectl delete apiservice v1beta1.metrics.k8s.io
  ```