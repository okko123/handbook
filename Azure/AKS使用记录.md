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
- 创建nginx公网入口控制器
  ```bash
  创建服务帐户，在已启用 RBAC 的 AKS 群集中部署 Helm 之前，需要 Tiller 服务的服务帐户  和角色绑定。
  cat > helm-rbac.yaml <<EOF
  apiVersion: v1
  kind: ServiceAccount
  metadata:
    name: tiller
    namespace: kube-system
  ---
  apiVersion: rbac.authorization.k8s.io/v1
  kind: ClusterRoleBinding
  metadata:
    name: tiller
  roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: cluster-admin
  subjects:
    - kind: ServiceAccount
      name: tiller
      namespace: kube-system
  EOF
  kubectl apply -f helm-rbac.yaml
  
  #使用helm部署nginx ingress 控制器
  helm init --service-account tiller --node-selectors "beta.kubernetes.io/  os"="linux"
  helm repo update
  helm install stable/nginx-ingress \
  --namespace ingress-basic \
  --set controller.replicaCount=2 \
  --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
  --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux
  
  kubectl get service -l app=nginx-ingress --namespace ingress-basic
  ```
- 创建内部LB。问题，LB创建后无法访问80端口
  ```bash
  #clone helm的模板
  git clone https://github.com/helm/charts.git
  cd charts/stable/nginx-ingress/
  #生成yaml文件
  helm template . --name gingerbread-man > internal-lb.yaml
  kubectl create -f internal-lb.yaml
  ```

## 参考连接
 - [在 Azure Kubernetes 服务 (AKS) 中使用 Helm 安装应用程序](https://docs.microsoft.com/zh-cn/azure/aks/kubernetes-helm)
 - [在 Azure Kubernetes 服务 (AKS) 中创建入口控制器](https://docs.microsoft.com/zh-cn/azure/aks/ingress-basic)
 - [在 AKS 服务总创建内部LB](https://docs.microsoft.com/zh-cn/azure/aks/internal-lb)
 - [多个nginx-ingress controller](https://kubernetes.github.io/ingress-nginx/user-guide/multiple-ingress/)
 - [如何在阿里云Kubernetes集群中部署多个Ingress Controller](https://yq.aliyun.com/articles/645856)