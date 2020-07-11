## harbor 镜像仓库部署
### 准备自签证书
1. 创建CA的私钥和证书
   ```bash
   openssl genrsa -out ca.key 4096
   openssl req -x509 -new -nodes -sha512 -days 3650 \
   -subj "/C=CN/ST=Guangdong/L=Guangzhou/O=example/OU=Personal/CN=yourdomain.com" \
   -key ca.key \
   -out ca.crt
   ```
2. 创建服务端私钥证书
   ```bash
   openssl genrsa -out yourdomain.com.key 4096
   openssl req -sha512 -new \
       -subj "/C=CN/ST=Guangdong/L=Guangzhou/O=example/OU=Personal/CN=yourdomain.com" \
       -key yourdomain.com.key \
       -out yourdomain.com.csr
   ```
3. 创建x509 v3扩展文件
   ```bash
   cat > v3.ext <<-EOF
   authorityKeyIdentifier=keyid,issuer
   basicConstraints=CA:FALSE
   keyUsage = digitalSignature, nonRepudiation, keyEncipherment,    dataEncipherment
   extendedKeyUsage = serverAuth
   subjectAltName = @alt_names
   
   [alt_names]
   DNS.1=yourdomain.com
   DNS.2=yourdomain
   DNS.3=hostname
   IP.1=192.168.1.1
   IP.2=172.16.1.1
   EOF
   ```
4. 使用私有CA，签发证书
   ```bash
   openssl x509 -req -sha512 -days 3650 \
       -extfile v3.ext \
       -CA ca.crt -CAkey ca.key -CAcreateserial \
       -in yourdomain.com.csr \
       -out yourdomain.com.crt
   ```
### harbor和docker配置自签证书
1. 配置证书位置，使用位置/etc/docker/cert.d/ca
   ```bash
   #配置harbor的证书位置
   mkdir -p /etc/docker/cert.d/ca
   cp yourdomain.com.crt /etc/docker/cert.d/ca/
   cp yourdomain.com.key /etc/docker/cert.d/ca/
   #配置docker信任证书的位置
   openssl x509 -inform PEM -in yourdomain.com.crt -out yourdomain.com.cert
   cp yourdomain.com.crt /etc/docker/cert.d/yourdomain.com/
   cp yourdomain.com.key /etc/docker/cert.d/yourdomain.com/
   cp ca.crt /etc/docker/certs.d/yourdomain.com/
   #如果你不使用默认https的443端口，请在文件夹上添加端口
   /etc/docker/certs.d/yourdomain.com:port 或者 /etc/docker/certs.d/harbor_IP:port
   ```
2. 重启docker engine服务
   ```bash
   systemctl restart docker
   ```
3. 配置harbor服务，修改harbor的配置文件，harbor.yml，确认打开https配置，并配置certificate和private_key的路径
   ```bash
   ./prepare
   docker-compose down -v
   docker-compose up -d
   ```
4. 验证
   - docker login yourdomain.com
   - 在浏览器打开：https://yourdomain.com

## 参考资料
- [官方配置https指南](https://goharbor.io/docs/1.10/install-config/configure-https/)
- [Harbor 使用自签证书支持 Https 访问](https://www.chenshaowen.com/blog/support-https-access-harbor-using-self-signed-cert.html   )