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
## 参考资料
- [官方配置https指南](https://goharbor.io/docs/1.10/install-config/configure-https/)