## traefik使用记录
### 在kubernetes集群中部署
- 使用helm工具进行安装部署，要求：kubernetes集群的版本为1.14+
  ```bash
  wget https://get.helm.sh/helm-v3.2.4-linux-amd64.tar.gz
  tar xf helm-v3.2.4-linux-amd64.tar.gz
  cd linux-amd64
  ./helm repo add traefik https://traefik.github.io/charts
  ./helm repo update
  ./helm install traefik traefik/traefik --namespace=traefik
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
### 接入consul做服务发现
- 在traefik的deployment中的spec.template.spec.containers.args添加
  ```bash
  kubectl edit deployment traefik -n traefik
  - --providers.consulcatalog.endpoint.address=consul-ip
  - --providers.consulcatalog.endpoint.datacenter=consul-datacenter
  ```
- 登录traefik面板检查。
  ```bash
  # 在k8s中通过port-forward 进行端口暴露
  kubectl port-forward $(kubectl get pods --selector "app.kubernetes.io/name=traefik" --output=name) 9000:9000
  访问 ip:9000/dashboard/
  ```
- 测试
  ```bash
  curl -H host:service-name http://traefik-ip:port
  ```
  ---
## 参考文档
- [官方文档-路由](https://docs.traefik.io/routing/routers/#configuration-example)
- [中文翻译文档](https://docs.traefik.cn/toml#kubernetes-ingress-backend)
- [traefik-helm-chart](https://github.com/traefik/traefik-helm-chart)