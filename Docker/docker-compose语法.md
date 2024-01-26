## docker-compose 语法
- 样例: 
  - image：配置镜像地址
  - environment：配置环境变量
  - ports：配置暴露的端口
  - volumes：挂载目录或者一个已存在的数据卷容器，格式：HOST:CONTAINER / HOST:CONTAINER:ro，后者对于容器来说，数据卷是只读的，这样可以有效保护宿主机的文件系统
  - network：配置网络

  ```yaml
  version: "3"

  services:
    sonarqube:
      image: sonarqube:10.3.0-community
      restart_policy: on-failure
      dns:
        - 8.8.8.8
        - 8.8.4.4
      restart: always
      resources:
        limits:
          cpus: '1'
          memory: 1024M
        reservations:
          cpus: '0.5'
          memory: 512M
      environment:
        SONAR_JDBC_URL: jdbc:postgresql://192.168.1.1:5432/sonar
        SONAR_JDBC_USERNAME: sonar
        SONAR_JDBC_PASSWORD: sonar
        SONAR_SECURITY_REALM: LDAP
        SONAR_AUTHENTICATOR_DOWNCASE: true
        LDAP_URL: ldap://192.168.1.1:389
        LDAP_BINDDN: cn=auth,dc=abc,dc=cn
        LDAP_BINDPASSWORD: 123456
        LDAP_AUTHENTICATION: simple
        LDAP_REALM: abc.cn
        LDAP_STARTTLS: false
        LDAP_USER_BASEDN: ou=研发部,dc=abc,dc=cn
        LDAP_USER_REQUEST: (&(objectClass=inetOrgPerson)(cn={login}))
        LDAP_USER_REALNAMEATTRIBUTE: cn
        LDAP_USER_EMAILATTRIBUTE: mail
        LDAP_GROUP_BASEDN: ou=groups,dc=abc,dc=cn
        LDAP_GROUP_REQUEST: (&(objectClass=groupOfUniqueNames)(uniqueMember={dn}))
        LDAP_GROUP_IDATTRIBUTE: cn
      ports:
        - "9000:9000"
      volumes:
        - /data/sonarqube_data/data:/opt/sonarqube/data
        - /data/sonarqube_data/extensions:/opt/sonarqube/extensions
        - /data/sonarqube_data/logs:/opt/sonarqube/logs
      restart: always
  ```
- 使用自定义的网络
  ```yaml
  version: "3"
  services:
    nginx1:
      image: nginx:1.25.3
      networks:
        - nginx

  networks:
    nginx:
      name: custom_nginx
  ```
---
### 参考信息
- [Docker Compose 网络设置](https://juejin.cn/post/6844903976534540296)
- [Networking in Compose](https://docs.docker.com/compose/networking/)
- [docker compose 配置文件 .yml 全面指南](https://zhuanlan.zhihu.com/p/387840381)