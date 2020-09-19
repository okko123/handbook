## traefik使用记录
### 在kubernetes集群中部署
- 使用helm工具进行安装部署，要求：kubernetes集群的版本为1.14+
  ```bash
  wget https://get.helm.sh/helm-v3.2.4-linux-amd64.tar.gz
  tar xf helm-v3.2.4-linux-amd64.tar.gz
  cd linux-amd64
  ./helm update
  git clone https://github.com/containous/traefik-helm-chart

  # 指定traefik使用traefik的namespace
  helm install ./traefik-helm-chart --namespace=traefik
  ```
### 查看traefik的控制面板
```bash
# 将traefik的9000端口映射到宿主的8888端口
kubectl port-forward pod/pod_name --address 192.168.1.1 8888:9000 -n traefik
# 在浏览器中打开http://192.168.1.1:8888/dashboard/#/
```
### 配置ingress
### 配置ingressroute
- 通过header头部，区分流量到不通的namespace中，注意service的名字不能相同
  ```yaml
  apiVersion: traefik.containo.us/v1alpha1
  kind: IngressRoute
  metadata:
    name: test-gateway-ingress
    namespace: traefik
  spec:
    entryPoints:
      - web
    routes:
    - match: HeadersRegexp(`X-Id`, `100000|200000`) && Host(`test.abc.com`) && PathPrefix(`/`)
      kind: Rule
      priority: 12
      services:
      - name: master-gateway-8080
        namespace: master
        port: 8080
        passHostHeader: true
        responseForwarding:
          flushInterval: 100ms
    - match: Host(`test.abc.com`) && PathPrefix(`/`)
      kind: Rule
      priority: 12
      services:
      - name: gateway-8080
        namespace: dev
        port: 8080
        passHostHeader: true
        responseForwarding:
          flushInterval: 100ms
  ```

  ---
## 参考文档
- [官方文档-路由](https://docs.traefik.io/routing/routers/#configuration-example)
- [中文翻译文档](https://docs.traefik.cn/toml#kubernetes-ingress-backend)