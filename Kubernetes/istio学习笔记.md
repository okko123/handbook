## istio学习笔记
- kubernetes集群中，安装istio
  ```bash
  curl -L https://istio.io/downloadIstio | sh -
  cd istio-1.14.1
  export PATH=$PWD/bin:$PATH
  istioctl install --set profile=demo -y
  ```
---
## 参考连接
- [Istio入门](https://istio.io/latest/zh/docs/setup/getting-started/#download)