
# efs-provisioner使用记录
## 安装efs-provisioner
* kubernetes版本: 1.17.0
* efs-provisioner版本: 
  ```bash
  wget https://github.com/kubernetes-incubator/external-storage/archive/efs-provisioner-v2.4.0.tar.gz
  tar xf efs-provisioner-v2.4.0.tar.gz
  cd external-storage-efs-provisioner-v2.4.0/aws/efs/deploy
  ```

* 通过kubectl导入rbac配置文件，在rbac.yaml追加内容
  ```bash
  cat >> rbac.yaml <<EOF
  ---
  apiVersion: v1
  kind: ServiceAccount
  metadata:
    name: efs-provisioner
  EOF

  kubectl apply -f rbac.yaml
  ```
* 使用kubectl导入manifest.yaml前。需要修改以下内容
  * 修改configmap中，file.system.id、aws.region、dns.name
  * 修改Deployment中，volumes下，nfs的server
  * 修改Deployment，kuvernetes version 1.16后取消apiVersion: extensions/v1beta1，使用 apiVersion: apps/v1替换
  * 在spec添加以下内容
    ```yaml
    spec:
      selector:
        matchLabels:
          app: efs-provisioner
      template:
        spec:
          serviceAccount: efs-provisioner
    ```
  * 最后，使用kubectl导入manifest.yaml
    ```bash
    kubectl apply -f manifest.yaml
    ```
### 参考信息
* [deployment的例子](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#creating-a-deployment)
* [确实selector的处理方法](https://stackoverflow.com/questions/59480373/validationerror-missing-required-field-selector-in-io-k8s-api-v1-deployements)
* [账号权限的处理](https://github.com/kubernetes-incubator/external-storage/issues/953)

## 部署metrics-server
git clone https://github.com/kubernetes-sigs/metrics-server.git
cd metrics-server/deploy/

## 需要修改kubernetes文件夹中的metrics-server-deployment.yaml。在容器metrics-server的args添加--kubelet-insecure-tls、--kubelet-preferred-address-types
kubectl apply -f /kubernetes
kubectl top nodes
kubectl top pod
kubectl get --raw "/apis/metrics.k8s.io/v1beta1/pods"
kubectl get --raw "/apis/metrics.k8s.io/v1beta1/nodes"
###参考信息
[从 Metric Server 到 Kubelet 服务证书](https://blog.fleeto.us/post/from-metric-server/)
[Kubernetes1.16集群中部署指标服务遇见的坑](https://www.sklinux.com/posts/k8s/%E9%9B%86%E7%BE%A4%E6%A0%B8%E5%BF%83%E6%8C%87%E6%A0%87%E6%9C%8D%E5%8A%A1/)