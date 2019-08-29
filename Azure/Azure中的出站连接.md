## Azure中的出站连接方法
---
* 具有公共IP地址的VM
* 与VM关联的公共负载均衡器。（SNAT、PAT）
* 独立VM：无负载均衡器，无公共IP地址。（使用Azure提供的SNAT，但出口IP不固定）
## 参考连接
* https://docs.microsoft.com/zh-cn/azure/load-balancer/load-balancer-outbound-connections