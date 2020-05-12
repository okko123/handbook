## kubeadm 实现细节
### Master节点上，常量和众所周知的值和路径
为了降低复杂性并简化 kubeadm 实施的部署解决方案的开发，kubeadm 使用一组有限的常量值，用于众所周知的路径和文件名。
Kubernetes 目录 /etc/kubernetes 在应用中是一个常量，因为它明显是大多数情况下的给定路径，也是最直观的位置; 其他常量路径和文件名是：
* /etc/kubernetes/manifests 作为 kubelet 寻找静态 Pod 的路径。静态 Pod 清单的名称是：
  * etcd.yaml
  * kube-apiserver.yaml
  * kube-controller-manager.yaml
  * kube-scheduler.yaml
* /etc/kubernetes/ 作为存储具有控制平面组件标识的 kubeconfig 文件的路径。kubeconfig 文件的名称是：
  * kubelet.conf （bootstrap-kubelet.conf - 在 TLS 引导期间）
  * controller-manager.conf
  * scheduler.conf
  * admin.conf 用于集群管理员和 kubeadm 本身
* /etc/kubernetes/pki/ 证书和密钥文件的名称：
  * ca.crt，ca.key 为 Kubernetes 证书颁发机构
  * apiserver.crt，apiserver.key 用于 API server 证书
  * apiserver-kubelet-client.crt，apiserver-kubelet-client.key 用于由 API server 安全地连接到 kubelet 的客户端证书
  * sa.pub，sa.key 用于签署 ServiceAccount 时控制器管理器使用的密钥
  * front-proxy-ca.crt，front-proxy-ca.key 用于前台代理证书颁发机构
  * front-proxy-client.crt，front-proxy-client.key 用于前端代理客户端


  kubeadm init phase preflight
