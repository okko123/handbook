## 在k8s中安装kong 3.4 LTS
- k8s: 1.28.15
- kong: 3.4.3.16
- helm: 3.17.1

1. 使用docker拉起PG数据库
   ```bash
   docker run -d --name kong-database \
    -p 5432:5432 \
    -e "POSTGRES_USER=kong" \
    -e "POSTGRES_DB=kong" \
    -e "POSTGRES_PASSWORD=kongpass" \
    postgres:13
   ```
2. 初始化kong 的数据库
   ```bash
   docker run --rm \
   -e "KONG_DATABASE=postgres" \
   -e "KONG_PG_HOST=192.168.0.1" \
   -e "KONG_PG_PASSWORD=kongpass" \
   -e "KONG_PASSWORD=test" \
   kong/kong-gateway:3.4.3.16 kong migrations bootstrap
   ```
3. k8s安装kong
   ```bash
   helm repo add kong https://charts.konghq.com
   helm repo update

   # 创建kong的namespace和创建TLS证书
   kubectl create namespace kong
   kubectl create secret generic kong-enterprise-license --from-literal=license="'{}'" -n kong

   openssl req -new -x509 -nodes \
   -newkey ec:<(openssl ecparam -name secp384r1) \
   -keyout ./tls.key \
   -out ./tls.crt \
   -days 1095 \
   -subj "/CN=kong_clustering"

   kubectl create secret tls kong-cluster-cert --cert=./tls.crt --key=./tls.key -n kong

   # 编辑cp和dp的配置文件
   cat > cp-3.4.yaml <<"EOF"
   # Do not use Kong Ingress Controller
   ingressController:
    enabled: true

   image:
    repository: kong/kong-gateway
    tag: "3.4.3.16"

   # Mount the secret created earlier
   secretVolumes:
    - kong-cluster-cert

   env:
    # This is a control_plane node
    role: control_plane
    # These certificates are used for control plane / data plane communication
    cluster_cert: /etc/secrets/kong-cluster-cert/tls.crt
    cluster_cert_key: /etc/secrets/kong-cluster-cert/tls.key

    # Database
    # CHANGE THESE VALUES
    database: postgres
    pg_database: kong
    pg_user: kong
    pg_password: kongpass
    pg_host: 192.168.0.1
    pg_ssl: "off"

    # Kong Manager password
    password: kong_admin_password

   # Enterprise functionality
   enterprise:
    enabled: false
    license_secret: kong-enterprise-license

   # The control plane serves the Admin API
   admin:
    enabled: true
    http:
      enabled: true

   # Clustering endpoints are required in hybrid mode
   cluster:
    enabled: true
    tls:
      enabled: true

   clustertelemetry:
    enabled: true
    tls:
      enabled: true

   # Optional features
   manager:
    enabled: false

   portal:
    enabled: false

   portalapi:
    enabled: false

   # These roles will be served by different Helm releases
   proxy:
    enabled: false
   EOF

   helm install kong-cp kong/kong -n kong --values ./values-cp.yaml

   cat > dp-3.4.yaml <<"EOF"
   # Do not use Kong Ingress Controller
   ingressController:
    enabled: false

   image:
    repository: kong/kong-gateway
    tag: "3.4.3.16"

   # Mount the secret created earlier
   secretVolumes:
    - kong-cluster-cert

   env:
    # data_plane nodes do not have a database
    role: data_plane
    database: "off"

    # Tell the data plane how to connect to the control plane
    cluster_control_plane: kong-cp-kong-cluster.kong.svc.cluster.local:8005
    cluster_telemetry_endpoint: kong-cp-kong-clustertelemetry.kong.svc.cluster.local:8006

    # Configure control plane / data plane authentication
    lua_ssl_trusted_certificate: /etc/secrets/kong-cluster-cert/tls.crt
    cluster_cert: /etc/secrets/kong-cluster-cert/tls.crt
    cluster_cert_key: /etc/secrets/kong-cluster-cert/tls.key

   # Enterprise functionality
   enterprise:
    enabled: false
    license_secret: kong-enterprise-license

   # The data plane handles proxy traffic only
   proxy:
    enabled: true

   # These roles are served by the kong-cp deployment
   admin:
    enabled: false

   portal:
    enabled: false

   portalapi:
    enabled: false

   manager:
    enabled: false
   EOF

   helm install kong-dp kong/kong -n kong --values dp-3.4.yaml
   ```
