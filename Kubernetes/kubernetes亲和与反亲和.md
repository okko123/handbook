## kubernetes亲和与反亲和
- 要配置"反亲和策略"，确保被驱逐的pod被调度到不同的Node节点上
```yaml
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchExpressions:
        - key: app
          operator: In
          values:
          - web
      topologyKey: kubernetes.io/hostname
```