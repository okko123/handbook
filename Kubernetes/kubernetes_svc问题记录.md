### k8s svc配置
- 问题：部署ingress-nginx后，只能在ingress-nginx pod所在的节点上，访问ingress-nginx的svc。在其他节点访问ingress-nginx svc的node port提示链接拒绝
---
- 排除问题：
- 保留客户端源 IP
> 默认情况下，目标容器中看到的源 IP 将不是客户端的原始源 IP。 要启用保留客户端 IP，可以在服务的 .spec 中配置以下字段：

> .spec.externalTrafficPolicy - 表示此 Service 是否希望将外部流量路由到节点本地或集群范围的端点。 有两个可用选项：Cluster（默认）和 Local。 Cluster 隐藏了客户端源 IP，可能导致第二跳到另一个节点，但具有良好的整体负载分布。 Local 保留客户端源 IP 并避免 LoadBalancer 和 NodePort 类型服务的第二跳， 但存在潜在的不均衡流量传播风险。

> .spec.healthCheckNodePort - 指定服务的 healthcheck nodePort（数字端口号）。 如果你未指定 healthCheckNodePort，服务控制器从集群的 NodePort 范围内分配一个端口。 你可以通过设置 API 服务器的命令行选项 --service-node-port-range 来配置上述范围。 在服务 type 设置为 LoadBalancer 并且 externalTrafficPolicy 设置为 Local 时， Service 将会使用用户指定的 healthCheckNodePort 值（如果你指定了它）。

> 可以通过在服务的清单文件中将 externalTrafficPolicy 设置为 Local 来激活此功能。比如：
   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: example-service
   spec:
     selector:
       app: example
     ports:
       - port: 8765
         targetPort: 9376
     externalTrafficPolicy: Local
     type: LoadBalancer
   ```
---
### 参考链接
- [创建外部负载均衡器](https://kubernetes.io/zh-cn/docs/tasks/access-application-cluster/create-external-load-balancer/)