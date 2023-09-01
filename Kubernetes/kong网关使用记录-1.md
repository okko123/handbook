## kong网关使用记录
### Ingress的说明
---
- Ingress的实现分为2个部分
  - Ingress: 描述具体路由规则，描述一个或多个域名的路由规则，以ingress资源的形式存在
  - Ingress Controller：流量入口，是一个实体软件。会监听API Server上的ingress资源，并实时生效

- kong网关端口说明，默认情况下，KONG监听的端口为：
    - 8000：此端口是KONG用来监听来自客户端传入的HTTP请求，并将此请求转发到上有服务器（kong根据配置的规则转发到真实的后台服务地址。）
     - 8443：此端口是KONG用来监听来自客户端传入的HTTPS请求的。它跟8000端口的功能类似，转发HTTPS请求的。可以通过修改配置文件来禁止它
     - 8001：Admin API，通过此端口，管理者可以对KONG的监听服务进行配置，插件设置、API的增删改查、以及负载均衡等一系列的配置都是通过8001端口进行管理；
     - 8444：通过此端口，管理者可以对HTTPS请求进行监控；
### KongA WebUI的使用记录
---
- KongA使用postgreSQL数据库，且版本只能用9。使用docker拉取kongA镜像
  ```bash
  # 拉取镜像
  docker pull pantsel/konga
  
  # 对数据库进行初始化，必须在pg中创建konga使用的数据库，konga_database
  docker run \
      --rm pantsel/konga:latest \
      -c prepare \
      -a postgres \
      -u postgresql://konguser:kongpassword@192.168.1.1:5432/konga_database
  # 运行
  docker run -p 1337:1337 \
             -e "TOKEN_SECRET=admin" \
             -e "DB_ADAPTER=postgres" \
             -e "DB_HOST=192.168.1.1" \
             -e "DB_PORT=5432" \
             -e "DB_USER=kong" \
             -e "DB_PASSWORD=kong" \
             -e "DB_DATABASE=konga_database" \
             -e "NODE_ENV=production" \
             --name konga \
             --detach \
             pantsel/konga
  ```
- 访问konga UI 的地址ip:1337，配置初始化用户，配置kong的管理地址
### Prometheus监控
---
### kong日志格式修改
---
- 修改kong-proxy的deployment配置，在env下添加以下新的配置
  ```bash
  - name: KONG_NGINX_HTTP_LOG_FORMAT
    value: custom_fmt '$remote_addr - $remote_user [$time_local] "$request"
      $status "$upstream_status" $body_bytes_sent "$http_referer" "$http_user_agent"
      "$request_time" "$upstream_response_time"'
  ```
- 修改KONG_ADMIN_ACCESS_LOG、KONG_PROXY_ACCESS_LOG的内容。
  ```bash
  - name: KONG_ADMIN_ACCESS_LOG
    value: /dev/stdout custom_fmt
  - name: KONG_PROXY_ACCESS_LOG
    value: /dev/stdout custom_fmt
  ```
### kong关闭版本号显示，更多配置参考/etc/kong/kong.conf.default配置文件
---
- 修改kong-proxy的deployment配置，在env下添加以下新的配置
  ```bash
  - name: KONG_HEADERS
    value: "off"
  ```
### kong的strip_path使用
---
- ingress配置，kong中的strip_path用于是否将请求中的url中path前缀进行剥离，在kong controller的不同版本中, 使用方法不同。开启后，会讲path的路径去除，再转发到后端的服务上
  - 在1.x的版本中, strip_path需要使用kongingress进行指定
  - 在2.x中, 直接在ingress中指定annotataion即可
```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: sample-ingresses
  annotations:
    konghq.com/strip-path: "true"
    kubernetes.io/ingress.class: kong
spec:
  rules:
  - http:
     paths:
     - path: /billing
       backend:
         serviceName: billing
         servicePort: 80
     - path: /comments
       backend:
         serviceName: comments
         servicePort: 80
     - path: /invoice
       backend:
         serviceName: invoice
         servicePort: 80
```
---
### kong admin API的使用
- 获取路由信息
  ```bash
  # 获取所有路由信息
  GET /routes

  # 获取指定服务的路由信息
  GET/services/{service name or id}/routes
  ```
### kong的域名解析规则
- 在kong配置service后（假设新建一个cms-service服务），查询3种类型的DNS解析（SRV、CNAME、A），kong使用的dns规则为：
  - cms-service.kong.svc.cluster.local
  - cms-service.svc.cluster.local
  - cms-service.cluster.local
  - cms-service
## 参考信息
- [Expose your Services with Kong Gateway](https://docs.konghq.com/getting-started-guide/2.4.x/expose-services/)
- [helm变量说明](https://github.com/Kong/charts/tree/main/charts/kong)
- [Kong学习(strip_path使用)](https://izsk.me/2020/09/23/Kong-strip-path/)
- [Kong API文档](https://docs.konghq.com/gateway/latest/admin-api/#route-object)