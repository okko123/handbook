## traefik使用记录
- traefik 3.3
- helm 3.17.1
- kubernetes 1.28.15
---
### 在kubernetes集群中部署
- 使用helm工具进行安装部署，要求：kubernetes集群的版本为1.22+，hel版本为：3.9+
  ```bash
  wget https://get.helm.sh/helm-v3.17.1-linux-amd64.tar.gz
  tar xf helm-v3.17.1-linux-amd64.tar.gz
  cd linux-amd64
  ./helm repo add traefik https://traefik.github.io/charts
  ./helm repo update
  ./helm install traefik traefik/traefik --namespace=traefik
  ```
- 创建deployment、svc、ingress测试
  ```bash
  cat > whoami.yaml <<'EOF'
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: whoami-deployment
    labels:
      app: whoami
  spec:
    replicas: 1
    selector:
      matchLabels:
        app: whoami
    template:
      metadata:
        labels:
          app: whoami
      spec:
        containers:
        - name: whoami
          image: traefik/whoami:v1.10
          ports:
          - containerPort: 80
  ---
  apiVersion: v1
  kind: Service
  metadata:
    name: whoami-service
  spec:
    selector:
      app: whoami
    ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  ---
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: whoami-ingress
  spec:
    ingressClassName: traefik
    rules:
    - http:
        paths:
        - path: /test
          pathType: Prefix
          backend:
            service:
              name: whoami-service
              port:
                number: 80
  EOF
  kubectl apply -f whoami.yaml
  ```
---
### 配置ingressroute
- 配置路由访问dashboard
  ```yaml
  apiVersion: traefik.io/v1alpha1
  kind: IngressRoute
  metadata:
    name: traefik-dashboard
  spec:
    routes:
    - match: PathPrefix(`/dashboard`)
      kind: Rule
      services:
      - name: api@internal
        kind: TraefikService
    - match: PathPrefix(`/api`)
      kind: Rule
      services:
      - name: api@internal
        kind: TraefikService
  ```
- 通过header头部，区分流量到不通的namespace中，注意service的名字不能相同
  ```yaml
  apiVersion: traefik.io/v1alpha1
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
- 使用正则方法配置Middleware和IngressRounte配置
   1. 配置Middleware
      ```bash
      cat > regex.yaml <<EOF
      apiVersion: traefik.io/v1alpha1
      kind: Middleware
      metadata:
        name: test-stripprefixregex
        namespace: default
      spec:
        stripPrefixRegex:
          regex:
          - /test/[a-z]+/
      EOF
      ```
   2. 配置ingressrounte
      ```bash
      cat > ingress.yaml <<EOF
      apiVersion: traefik.io/v1alpha1
      kind: IngressRoute
      metadata:
        name: test-gateway-ingress
        namespace: default
      spec:
        entryPoints:
        - web
        - metrics
        routes:
        - kind: Rule
          match: Host(`test.exmple.com`) && PathPrefix(`/test/wechat/`)
          middlewares:
          - name: test-stripprefixregex
          services:
          - name: wechat-service-8080
            namespace: default
            port: 8080
      EOF

      kubectl apply -f ingress.yaml
      ```
### traefik 路径切除
- 将/test/abc/new中的/test/abc路径切除，实现后端接收的请求为/new
1. 使用prefix的具体配置
   1. 配置Middleware
      ```bash
      cat > traefik-stripprefix.yaml <<EOF
      apiVersion: traefik.io/v1alpha1
      kind: Middleware
      metadata:
        name: test-stripprefix
        namespace: default
      spec:
        stripPrefix:
          prefixes:
            - /test/abc/
            - /test/qwe/
      EOF

      kubectl apply -f traefik-stripprefix.yaml
      ```
   2. 配置ingress
      ```bash
      cat > ingress.yaml <<EOF
      apiVersion: networking.k8s.io/v1
      kind: Ingress
      metadata:
        annotations:
          traefik.ingress.kubernetes.io/router.middlewares: namespace-test-stripprefix@kubernetescrd
        name: test-gateway-ingress
        namespace: default
      spec:
        ingressClassName: traefik
        rules:
        - host: test.example.com
          http:
            paths:
            - path: /test/wechat/
              backend:
                service:
                  name: wechat-service-8080
                  port:
                    number: 8080
      EOF

      kubectl apply -f ingress.yaml
      ```
### 查看traefik的控制面板
- 9100端口为prometheus的数据采集
- 8080端口
- 8000端口为http web协议
- 8443端口为https web协议
```bash
# 将traefik的9000端口映射到宿主的8888端口
kubectl port-forward pod/pod_name --address 192.168.1.1 8888:8000 -n traefik
# 在浏览器中打开http://192.168.1.1:8888/dashboard/#/
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
  kubectl port-forward $(kubectl get pods --selector "app.kubernetes.io/name=traefik" --output=name) 8000:8000
  访问 ip:8000/dashboard/
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