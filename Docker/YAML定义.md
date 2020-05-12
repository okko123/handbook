## pod定义的主要部分
POD定义由这么几个部分组成 首先是 YAML 中使用的 Kubernetes 版本和 YAML 描述的资源类型；其次是几乎在所有 ub es 资源中都可 找到的三大重
要部分
* metadata 包括名称、命名空间、标签和关于该容器的其他信息
* spec 包含 od 内容的实际说明 例如 od 的容器、卷和其他数据
* status 包含运行中的 pod 的当前信息，例如 pod 所处的条件 每个容器的描述和状态，以及内部 IP 和其他基本信息。
```YAML
apiVersion: v1
kind: Pod
metadata:
  name: kubia-manual
  labels:
    creation_method: manual
    env: prod
    release: stable
    app: kuia-manual
spec:
  containers:
  - image: luksa/kubia
    name: kubia
    ports:
    - containerPort: 8080
      protocol: TCP
```
* 查询pod yaml字段的方法kubectl explain pods