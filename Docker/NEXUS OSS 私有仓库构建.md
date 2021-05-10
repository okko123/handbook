## NEXUS OSS 私有仓库构建
- 官方网站下载NEXUS的二进制包，[下载页面](https://help.sonatype.com/repomanager3/download/download-archives---repository-manager-3)
- [系统要求](https://help.sonatype.com/repomanager3/installation/system-requirements)
  - 要求JRE8以上
  - 最低要求4核8G内存
- 启动
  - 命令行下直接启动：解压二进制包后，进入目录执行bin/nexus start启动nexus
  - 使用systemd启动：
    ```bash
    # 将nexus解压到/opt目录下
    tar -xf nexus-$VERSION-unix.tar.gz -C /opt
    useradd nexus

    cat > /etc/systemd/system/nexus.service <<EOF
    [Unit]
    Description=nexus service
    After=network.target
      
    [Service]
    Type=forking
    LimitNOFILE=65536
    ExecStart=/opt/nexus-$VERSION/bin/nexus start
    ExecStop=/opt/nexus-$VERSION/bin/nexus stop
    User=nexus
    Restart=on-abort
    TimeoutSec=600
      
    [Install]
    WantedBy=multi-user.target

    systemctl daemon-reload
    systemctl start nexus
    systemctl enable nexus
    
    # 出现Please define INSTALL4J_JAVA_HOME to point to a suitable JVM 报错信息的处理方法
    修改bin/nexus文件，修改 INSTALL4J_JAVA_HOME_OVERRIDE ， 指向JAVA_HOME即可解决问题

    ```
### 配置https
- 创建Java Keystore file 文件路径：$data-dir/etc/ssl/keystore.jks
  - jks文件创建：
    - 使用keytool工具生成jks
      ```bash    
      
      NEXUS_DOMAIN=nexus.example.com
      NEXUS_IP_ADDRESS=192.16.1.1
      PASSWD=password
  
      keytool -genkeypair -keystore keystore.jks -storepass ${PASSWD}  -keypass ${PASSWD} -alias nexus -keyalg RSA -keysize 2048 -validity 5000 -dname "CN=${NEXUS_DOMAIN}, OU=Nexus, O=Nexus, L=Beijing, ST=Beijing, C=CN" -ext "SAN=IP:${NEXUS_IP_ADDRESS}" -ext "BC=ca:true"
      ```
    - 使用openssl工具生成jks
      ```bash
      # 自签证书生成私钥和证书cert.crt、cert.key，passvalue填入jks文件的密码
      # 第一步：把用户证书转换成P12格式
      openssl pkcs12 -name nexus -export -in cert.crt -inkey cert.key -out keystore.p12 -passout pass:<passvalue>

      # 第二步：把p12格式文件加入到JKS格式
      keytool -importkeystore -srckeystore keystore.p12 -srcstoretype PKCS12 -destkeystore keystore.jks -srcstorepass <passvalue> -deststorepass <passvalue>

      # 查看jks文件的内容
      keytool --list -keystore keystore.jks -storepass <passvalue>
      ```
- 修改nexus的配置文件，文件路径：$data-dir/etc/nexus.properties。
  - 添加：application-port-ssl=8443
  - 在nexus-args行末追加：${jetty.etc}/jetty-https.xml
  - 添加：ssl.etc=${karaf.data}/etc/ssl
- 修改jetty-https.xml文件，文件路径：$install-dir/etc/jetty/jetty-https.xml
  - 修改"KeyStorePassword"、"KeyManagerPassword"、"TrustStorePassword"的密码配置，必须与jks的密码一致
- 重启nexus，应用新配置。
- 通过8443端口访问https页面
- [注意]默认配置下，不支持SNI证书，需要修改配置${jetty.etc}/jetty-https.xml启用。需要重启nexus服务
  - 将\<New id="sslContextFactory" class="org.eclipse.jetty.util.ssl.SslContextFactory">，修改为\<New id="sslContextFactory" class="org.eclipse.jetty.util.ssl.SslContextFactory$Server">
### 在NEXUS中配置docker registry（私有仓库）
1. Repository - Repositories - Create repository - 选择 docker（hosted）
2. 填一个名称（如 docker-local）
3. 勾上 HTTPS，填一个端口（如 7709）
4. 点击 Create repository ，创建仓库
5. 配置 Realms：Security - Realms，把 Docker Realm 激活
6. 验证 Docker 能否正常与 Nexus Docker 仓库正常通信（提前将nexus的自签证书配置到docker的/etc/docker/cert.d目录下）。注意这里的端口号为仓库配置端口，不是nexus的web访问端口。
   ```bash
   docker login 192.168.1.1:7709
   ```
### 在NEXUS OSS中清理镜像
1. 使用docker API / Nexus REST API / UI 页面删除对应的镜像，以上操作在nexus中，镜像被标记删除。并不是否磁盘空间
2. 在nexus的task中添加以下2个任务，并执行后，才会释放空间
   1. Configure and run the 'Docker - Delete unused manifests and images' task to delete orphaned docker layers.
   2. Configure and run the 'Admin - Compact blob store' task to reclaim disk space from the blob store for any assets already marked soft-deleted, including the Docker related ones created using options in this article.
### 参考资料
- https://help.sonatype.com/repomanager3/installation/run-as-a-service#RunasaService-systemd
- [官方文档，配置ssl](https://help.sonatype.com/repomanager3/system-configuration/configuring-ssl#ConfiguringSSL-InboundSSL-ConfiguringtoServeContentviaHTTPS)
- [如何把PEM格式证书转换成JKS格式](https://www.jianshu.com/p/7e5917604c2d)
- [从jks证书中提取公钥和私钥（jks证书转pem证书）](https://www.jianshu.com/p/ba35c7f47d8a)
- [使用 Nexus OSS 为 Docker 镜像提供代理/缓存功能](https://jenkins-zh.github.io/wechat/articles/2020/05/2020-05-13-using-nexus-oss-as-a-proxy-cache-for-docker-images/)
- [How to delete docker images from Nexus Repository Manager](https://support.sonatype.com/hc/en-us/articles/360009696054-How-to-delete-docker-images-from-Nexus-Repository-Manager)