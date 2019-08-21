## AKS使用记录
---
- 创建AKS，Kubemetes版本为1.12.8
- 使用az aks get-credentials，获取AKS的用户凭证
  ```bash
  az aks get-credentials --resource-group rg --name name
  ```
- 安装helm；Helm 是一种开放源打包工具，有助于安装和管理 Kubernetes 应用程序的生命周期。在github上下载预编译的二进制包
  ```bash
  wget https://get.helm.sh/helm-v2.14.2-linux-amd64.tar.gz
  tar xf helm-v2.14.2-linux-amd64.tar.gz
  ```
- 创建namespace:beta,ingress-basic
  ```bash
  kubectl create namespace beta
  kubectl create namespace ingress-basic
  ```
- 创建nginx入口控制器
  ```bash
  创建服务帐户，在已启用 RBAC 的 AKS 群集中部署 Helm 之前，需要 Tiller 服务的服务帐户  和角色绑定。
  at > helm-rbac.yaml <<EOF
  piVersion: v1
  ind: ServiceAccount
  etadata:
   name: tiller
   namespace: kube-system
  --
  piVersion: rbac.authorization.k8s.io/v1
  ind: ClusterRoleBinding
  etadata:
   name: tiller
  oleRef:
   apiGroup: rbac.authorization.k8s.io
   kind: ClusterRole
   name: cluster-admin
  ubjects:
   - kind: ServiceAccount
     name: tiller
     namespace: kube-system
  OF
  ubectl apply -f helm-rbac.yaml
  
  使用helm部署nginx ingress 控制器
  elm init --service-account tiller --node-selectors "beta.kubernetes.io/  s"="linux"
  elm repo update
  elm install stable/nginx-ingress \
  -namespace ingress-basic \
  -set controller.replicaCount=2 \
  -set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
  -set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux
  
  kubectl get service -l app=nginx-ingress --namespace ingress-basic
  
  ```

## 参考连接
 - [在 Azure Kubernetes 服务 (AKS) 中使用 Helm 安装应用程序](https://docs.microsoft.com/zh-cn/azure/aks/kubernetes-helm)
 - [在 Azure Kubernetes 服务 (AKS) 中创建入口控制器](https://docs.microsoft.com/zh-cn/azure/aks/ingress-basic)