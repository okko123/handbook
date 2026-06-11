## k8s 1.32 的kubelet配置

- 修改 /var/lib/kubelet/config.yaml
  ```bash
  serverTLSBootstrap: true # 启用TLS认证
  imageGCHighThresholdPercent: 65   # 磁盘到 55% 就开始清理镜像
  imageGCLowThresholdPercent: 50    # 清理到 50% 为止停止
  imageMinimumGCAge: 5m             # 新拉取的镜像 5 分钟内不准删

  # ─── 2. 自定义容器 GC 阈值 ───
  maximumDeadContainersPerPod: 1    # 每个Pod最多留一个死容器看尸体
  maximumDeadContainers: 20        # 整台机器最多保留20个死容器

  shutdownGracePeriod: 10s
  ```
---
### 参考连接
- [通过配置文件设置 Kubelet 参数](https://kubernetes.io/docs/tasks/administer-cluster/kubelet-config-file/)