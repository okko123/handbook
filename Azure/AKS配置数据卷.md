## 配置数据卷
* 每个 AKS 群集包含两个预先创建的存储类，两者均配置为使用 Azure 磁盘
  - default 存储类可预配标准 Azure 磁盘。
    - 标准存储受 HDD 支持，可以在确保性能的同时提供经济高效的存储。 标准磁盘适用于经济高效的开发和测试工作负荷。
  - managed-premium 存储类可预配高级 Azure 磁盘。
    - 高级磁盘由基于 SSD 的高性能、低延迟磁盘提供支持。 完美适用于运行生产工作负荷的 VM。 如果群集中的 AKS 节点使用高级存储，请选择 managed-premium 类。
* PVC，创建一个大小为5G,存储类型为managed-premium的磁盘。
  ```bash
  apiVersion: v1
  kind: PersistentVolumeClaim
  metadata:
    name: azure-managed-disk
  spec:
    accessModes:
    - ReadWriteOnce
    storageClassName: managed-premium
    resources:
      requests:
        storage: 5Gi
  ```
* PV，需要创建托管磁盘，然后再挂载到容器中
* 需要在多个Pod之间共享永久性卷，需要使用[Azure 文件存储](https://docs.microsoft.com/zh-cn/azure/aks/azure-files-volume)
## 参考信息
---
* https://docs.microsoft.com/zh-cn/azure/aks/azure-disks-dynamic-pv
* https://docs.microsoft.com/zh-cn/azure/aks/concepts-storage
* https://docs.microsoft.com/zh-cn/azure/aks/azure-files-dynamic-pv
* https://docs.microsoft.com/zh-cn/azure/aks/azure-files-volume
