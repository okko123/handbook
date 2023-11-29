## apisix使用笔记
### apisix-ingress、apisix-dashboard部署
- k8s-1.22.14
- helm-3.6.3
```bash
# 需要先创建data-apisix-etcd-0、data-apisix-etcd-1、data-apisix-etcd-2一共3个PVC

# 安装apisix本体
helm repo add apisix https://charts.apiseven.com
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
kubectl create ns ingress-apisix
helm install apisix apisix/apisix \
  --set gateway.type=NodePort \
  --set ingress-controller.enabled=true \
  --namespace ingress-apisix \
  --set ingress-controller.config.apisix.serviceNamespace=ingress-apisix
kubectl get service --namespace ingress-apisix

# 安装apisix-dashboard
helm install apisix-dashboard apisix/apisix-dashboard --namespace ingress-apisix
创建nodepord访问
cat > tmp.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  annotations:
  labels:
    app.kubernetes.io/instance: apisix-dashboard
    app.kubernetes.io/name: apisix-dashboard
    app.kubernetes.io/version: 3.0.0
  name: apisix-dashboard-nodeport
  namespace: ingress-apisix
spec:
  internalTrafficPolicy: Cluster
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  ports:
  - name: apisix-gateway
    nodePort: 32610
    port: 80
    targetPort: http
  selector:
    app.kubernetes.io/instance: apisix-dashboard
    app.kubernetes.io/name: apisix-dashboard
  type: NodePort
EOF

# 临时开启端口访问dashoard
kubectl port-forward service/apisix-dashboard 8080:80
```
### 配置技巧
- 路由配置->路径配置。没有配置通配符的情况下，为精准匹配。
  - /abc：只能匹配/abc的url
  - /abc/*：匹配以/abc开头的url，例如：/abc/qwe/sdf
- 对匹配的路径进行切分；/abc/qwe/index.html
  - 对/abc/*的路径进行匹配，然后将/qwe/index.html转发至后端服务上，需要在路由配置上，配置路径改写，正则改写
    ```bash
    ^/abc/(.*)
    /$1
    ```
- 开启TLS-1.1协议
  > 默认的情况下，APISIX只开启 TLS-1.2和TLS-1.3协议
    ```bash
    # 修改apisix的配置文件config.yaml，添加配置
    apisix:
      ssl:
        ssl_protocols: TLSv1.1 TLSv1.2 TLSv1.3
        ssl_ciphers: ECDHE-RSA-AES256-SHA:AES256-SHA:CAMELLIA256-SHA:ECDHE-RSA-AES128-SHA:AES128-SHA:CAMELLIA128-SHA
    ```
  > 检查TLS版本
    ```bash
    openssl s_client -connect www.baidu.com:443 -tls1_2
    openssl s_client -connect www.baidu.com:443 -tls1_1
    openssl s_client -connect www.baidu.com:443 -tls1

    nmap --script ssl-enum-ciphers -p 443 baidu.com 
    ```
### apisix 启用Prometheus插件
- 编辑apisix配置文件config.yaml
  ```bash
  plugin_attr:
    prometheus:
      export_addr:
        ip: "0.0.0.0"
        port: 9092
  ```
- 配置完成后，你可以通过以下命令提取相关监控指标：
  ```bash
  curl -i http://127.0.0.1:9092/apisix/prometheus/metrics

  #返回如下结果即为配置成功。

  HTTP/1.1 200 OK
  Server: openresty
  Date: Wed, 23 Mar 2022 13:22:58 GMT
  Content-Type: text/plain; charset=utf-8
  Transfer-Encoding: chunked
  Connection: keep-alive

  # HELP apisix_etcd_modify_indexes Etcd modify index for APISIX keys
  # TYPE apisix_etcd_modify_indexes gauge
  apisix_etcd_modify_indexes{key="consumers"} 0
  ...
  # TYPE apisix_node_info gauge
  apisix_node_info{hostname="APISIX"} 1
  ```
---
- [minikube install apisix](https://apisix.apache.org/docs/ingress-controller/deployments/minikube/)
- [两种方式教你在 K8s 中轻松部署 Apache APISIX](https://apisix.apache.org/zh/blog/2021/12/15/deploy-apisix-in-kubernetes/#%E9%83%A8%E7%BD%B2-apache-apisix-dashboard)
- [Is Apache APISIX support strip_path in Kong? ](https://github.com/apache/apisix/issues/2208)
- [APISIX的SSL协议](https://apisix.apache.org/zh/docs/apisix/ssl-protocol/)
- [使用 Prometheus 监控云原生 API 网关 APISIX](https://apisix.apache.org/zh/blog/2022/07/13/monitor-api-gateway-apisix-with-prometheus/)