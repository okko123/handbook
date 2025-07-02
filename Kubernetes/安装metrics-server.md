# 安装metrics-server，使用的版本为0.3.7
## 安装前需要注意的问题
* 没有启用TLS
* 启用TLS
* 主机名必须能解析，默认情况下，使用主机名进行通信

## 安装过程
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.7.2/components.yaml

kubectl edit deployment -n kube-system metrics-server
# 在containers.args下添加一下参数
# --kubelet-insecure-tls

# 拉取镜像
docker pull dyrnq/metrics-server:v0.7.2
docker tag dyrnq/metrics-server:v0.7.2 registry.k8s.io/metrics-server/metrics-server:v0.7.2
```
## 验证方法
```bash
kubectl top nodes
kubectl top pod
kubectl get --raw "/apis/metrics.k8s.io/v1beta1/pods"
kubectl get --raw "/apis/metrics.k8s.io/v1beta1/nodes"
```

### 参考信息
[从 Metric Server 到 Kubelet 服务证书](https://blog.fleeto.us/post/from-metric-server/)
[Kubernetes1.16集群中部署指标服务遇见的坑](https://www.sklinux.com/posts/k8s/%E9%9B%86%E7%BE%A4%E6%A0%B8%E5%BF%83%E6%8C%87%E6%A0%87%E6%9C%8D%E5%8A%A1/)