## kubernetes问题记录
### kubect get cs出现scheduler、controller-manager出现connection refused的报错
- 由于上游kubernetes弃用组件状态，在1.18.8上scheduler、controller-manager监听的为10257、10259，并使用https协议。[信息来源](https://github.com/Azure/AKS/issues/173)

kubectl edit  configmap -n kube-system  kube-proxy