## kong网关部署记录
### 使用docker初始化pg数据库
- 已经部署pg数据库，并创建kong的用户，kong的数据库
- 初始化数据库
  ```bash
  docker run --rm \
    -e "KONG_DATABASE=postgres" \
    -e "KONG_PG_HOST=192.168.1.1" \
    -e "KONG_PG_USER=kong" \
    -e "KONG_PG_PASSWORD=kong" \
    -e "KONG_CASSANDRA_CONTACT_POINTS=kong-database" \
    kong:latest kong migrations bootstrap
  ```
### 混合模式，Control Plane / Data Plane Separation (CP/DP)
- 混合模式部署的优势
  - 由于仅CP节点需要直接连接到数据库，因此可以大大减少数据库上的通信量。
  - 增强的安全性，一旦DP节点之一受到入侵，攻击者将无法影响Kong群集中的其他节点。
  - 易于管理，因为管理员只需与CP节点进行交互即可控制和监视整个Kong集群的状态
### 当kong使用consul做服务发现时
- 在kong-proxy的deployment中，在spec.template.spec字段下添加配置
  ```bash
  dncConfig:
    searches:
      - service.consul
  ```
### 在k8s集群中安装部署kong
- 使用helm安装kong标准版，开启ingressController，helm版本3.5.3，命名空间为kong
  ```bash
  kubectl create ns kong
  helm repo add kong https://charts.konghq.com
  helm repo update
  helm install kong/kong --generate-name \
  --set ingressController.installCRDs=false \
  --set ingressController.enabled=true \
  --namespace kong
  ```
- 使用helm安装kong的混合模式，helm版本3.5.3，命名空间为kong
  - 由于cp、dp节点间使用TLS进行通信，因此需要使用证书。使用openssl创建证书
    ```bash
    openssl req -new -x509 -nodes -newkey ec:<(openssl ecparam -name secp384r1) \
    -keyout /tmp/cluster.key -out /tmp/cluster.crt \
    -days 1095 -subj "/CN=kong_clustering"
    ```
  - 将证书导入k8s中
    ```bash
    kubectl create ns kong
    kubectl create secret tls kong-cluster-cert --cert=/tmp/cluster.crt --key=/tmp/cluster.key -n kong
    ```
  - 更新helm源
    ```bash
    helm repo add kong https://charts.konghq.com
    helm repo update
    ```
  - 安装控制节点。关闭自带的postgresql配置，添加命名空间、关闭迁移操作、健康检查、滚动更新和proxy（启用ingressController），github中的样例：[minimal-kong-hybrid-control.yaml](https://github.com/Kong/charts/blob/main/charts/kong/example-values/minimal-kong-hybrid-control.yaml)
    - 如果启用ingress controller，你必须将DP代理的svc指定为其发布目标，以使ingress的状态信息保持最新。否则在关闭proxy模式下，会因为无法访问publish_service的地址导致启动失败
      ```yaml
      ingressController:
        env:
          publish_service: kong/kong-proxy-kong-proxy
      ```
    - Replace hybrid with your DP nodes' namespace and example-release-data with the name of the DP release.
    - 修改后的配置文件：[minimal-kong-hybrid-control.yaml](scripts/minimal-kong-hybrid-control.yaml)
      ```bash
      ./helm  install kong-admin kong/kong  -f minimal-kong-hybrid-control.yaml  --namespace kong
      ```
  - 安装数据节点。修改cluster_control_plane，与control_plane进行通信。github中的样例：[minimal-kong-hybrid-data.yaml](https://github.com/Kong/charts/blob/main/charts/kong/example-values/minimal-kong-hybrid-data.yaml)
    - Note that the cluster_control_plane value will differ depending on your environment. control-plane-release-name will change to your CP release name, hybrid will change to whatever namespace it resides in. See Kubernetes' documentation on Service DNS for more detail.
    - 修改后的配置文件：[minimal-kong-hybrid-data.yaml](scripts/minimal-kong-hybrid-data.yaml)
      ```bash
      ./helm  install kong-proxy kong/kong  -f minimal-kong-hybrid-data.yaml --namespace kong
      ```
  - 检查集群状态，在控制节点上执行，正常的结果如下：
    ```bash
    curl http://ip:8001/clustering/data-planes
    {
        "data": [
            {
                "config_hash": "a9a166c59873245db8f1a747ba9a80a7",
                "hostname": "data-plane-2",
                "id": "ed58ac85-dba6-4946-999d-e8b5071607d4",
                "ip": "192.168.10.3",
                "last_seen": 1580623199,
                "ttl": 1139376,
                "version": "2.2.1",
            },
            {
                "config_hash": "a9a166c59873245db8f1a747ba9a80a7",
                "hostname": "data-plane-1",
                "id": "ed58ac85-dba6-4946-999d-e8b5071607d4",
                "ip": "192.168.10.4",
                "last_seen": 1580623200,
                "ttl": 1139377,
                "version": "2.3.0",
            }
        ],
        "next": null
    }
    ```
### konga ui面板安装
- 使用docker部署PostgreSQL数据库；必须使用版本9，因为konga不支持新版的pg
  ```bash
  mkdir /data/pg-data
  cat > pg-composefile.yaml <<EOF
  version: "3.9"
  services:
    postgres:
      image: postgres:9.6.23-alpine3.14
      container_name: kong-database
      restart: always
      ports:
        - 5432:5432
      volumes:
        - /data/pg-data:/var/lib/postgresql/data
      environment:
        POSTGRES_PASSWORD: mysecretpassword
  EOF

  ./docker-compose -f pg-composefile.yaml up -d

  # 进入pg容器，切换posgres用户，创建用户和数据库
  su - postgres
  psql

  # 创建用户kong，并设置密码kong。
  CREATE USER kong WITH PASSWORD 'kong';

  # 创建数据库，这里为konga_db，并指定所有者为kong
  CREATE DATABASE kong_db OWNER kong;

  # 将konga_db数据库的所有权限都赋予kong，否则kong只能登录控制台，没有任何数据库操作权限。
  GRANT ALL PRIVILEGES ON DATABASE konga_db TO kong;

  #对数据库进行初始化，必须在pg中创建konga使用的数据库，konga_db
  docker run --rm pantsel/konga:latest -c prepare -a postgres  -u postgresql://kong:kong@192.168.1.1:5432/konga_db
  ```
### 测试验证
- 创建deployment，nginx和echoserver；在default的命名空间中
  ```bash
  # nginx
  kubectl create deployment web --image=nginx:1.14.2
  # echo server
  echo "apiVersion: v1
  kind: Service
  metadata:
    labels:
      app: echo
    name: echo
  spec:
    ports:
    - port: 8080
      name: high
      protocol: TCP
      targetPort: 8080
    - port: 80
      name: low
      protocol: TCP
      targetPort: 8080
    selector:
      app: echo
  ---
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    labels:
      app: echo
    name: echo
  spec:
    replicas: 1
    selector:
      matchLabels:
        app: echo
    strategy: {}
    template:
      metadata:
        creationTimestamp: null
        labels:
          app: echo
      spec:
        containers:
        - image: e2eteam/echoserver:2.2
          name: echo
          ports:
          - containerPort: 8080
          env:
            - name: NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
          resources: {}
  "|kubectl apply -f -
  ```
- 创建ingress
  ```bash
  echo "
  apiVersion: extensions/v1beta1
  kind: Ingress
  metadata:
    name: demo
    annotations:
      konghq.com/strip-path: "true"
      kubernetes.io/ingress.class: kong
  spec:
    rules:
    - http:
        paths:
        - path: /foo
          backend:
            serviceName: echo
            servicePort: 80
  ---
  apiVersion: extensions/v1beta1
  kind: Ingress
  metadata:
    name: nginx-example-ingress
    annotations:
      konghq.com/strip-path: "true"
      kubernetes.io/ingress.class: kong
  spec:
   rules:
   - host: nginx.example.com
     http:
       paths:
       - path: /
         backend:
           serviceName: web
           servicePort: 80
  " | kubectl apply -f -
  ```
- 使用curl进行验证，由于自建K8S没有与云的LB进行联动，因此不能获取LB的公网IP。可用其中一个node节点的IP替换。执行kubectl get svc -n kong |grep kong-proxy，获取data-plane节点的暴露端口
  ```bash
  kubectl get svc -n kong
  NAME                        TYPE           CLUSTER-IP      EXTERNAL-IP   PORT  (S)                         AGE
  kong-control-kong-admin     NodePort       10.96.20.114    <none>        8001:30059/TCP,  8444:30966/TCP   124m
  kong-control-kong-cluster   ClusterIP      10.106.35.216   <none>        8005/  TCP                        124m
  kong-control-kong-proxy     LoadBalancer   10.100.44.132   <pending>     80:31404/  TCP                    124m
  kong-data-kong-proxy        LoadBalancer   10.101.61.214   <pending>     80:30909/TCP,443:31047/TCP      124m

  kubectl get nodes -o wide
  NAME    STATUS   ROLES                  AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
  k8s01   Ready    control-plane,master   9d    v1.20.5   172.16.84.137   <none>        Ubuntu 20.04.1 LTS   5.4.0-42-generic   docker://20.10.5
  k8s02   Ready    <none>                 9d    v1.20.5   172.16.84.139   <none>        Ubuntu 20.04.1 LTS   5.4.0-71-generic   docker://20.10.5

  # 访问kong proxy的正常内容
  curl -i 172.16.84.139:30909
  HTTP/1.1 404 Not Found
  Date: Thu, 22 Apr 2021 09:48:27 GMT
  Content-Type: application/json; charset=utf-8
  Connection: keep-alive
  Content-Length: 48
  X-Kong-Response-Latency: 0
  Server: kong/2.3.3
  
  {"message":"no Route matched with those values"}r

  # 访问echo-server
  curl -i 172.16.84.139:30909/foo

  # 访问nginx首页
  curl -H host:nginx.example.com
  ```
---
- [kong混合模式说明](https://docs.konghq.com/gateway-oss/2.3.x/hybrid-mode/)
- [配置说明](https://docs.konghq.com/gateway-oss/2.3.x/configuration/)
- [使用helm安装kong的参数设置](https://github.com/Kong/charts/tree/main/charts/kong#hybrid-mode)
- [Kubernetes Ingress Controller](https://docs.konghq.com/kubernetes-ingress-controller/1.2.x/introduction/)
- [kong-ingress-controller文档](https://docs.konghq.com/kubernetes-ingress-controller/1.2.x/deployment/k4k8s/)
- [kong访问的样例](https://docs.konghq.com/kubernetes-ingress-controller/1.2.x/guides/getting-started/)
- [kong helm charts的说明文档](https://github.com/Kong/charts/blob/main/charts/kong/README.md)