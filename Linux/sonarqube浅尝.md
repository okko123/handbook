## sonarqube浅尝
### 安装，使用docker的方式进行部署
- 配置Postgres
  ```bash
  psql
  create user sonar with password 'sonar';
  create database sonar owner sonar;
  grant all privileges on senar to sonar;
  ```
- 启动sonarqube
  ```bash
  mkdir -p /data/sonarqube/{data,logs,extensions}
  cat > sonarqube.yaml <<EOF
  version: "3.9"
  
  services:
    sonarqube:
      hostname: sonarqube.abc.cn
      image: sonarqube:9.0.1-community
      restart: always
      volumes:
        - /data/sonarqube/data:/opt/sonarqube/data
        - /data/sonarqube/logs:/opt/sonarqube/logs
        - /data/sonarqube/extensions:/opt/sonarqube/extensions
      ports:
        - "9000:9000/tcp"
      environment:
       - sonar.jdbc.username=sonar
       - sonar.jdbc.password=sonar
       - sonar.jdbc.url=jdbc:postgresql://192.168.1.1/sonar
  EOF

  docker-compose -f sonarqube.yaml up -d
- 安装中文语言包
  - 登录web页面，在页面上找到 配置 > 市场
  - 在搜索框输入 chinese ，出现一个 Chinese Pack ，点击右侧的 install 按钮安装。
  - 安装成功后，会提示重启SonarQube服务器。点击Restart。
  
  ```
### sonarqube配置LDAP认证
```bash
version: "3"

services:
  sonarqube:
    image: sonarqube:10.3.0-community
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
      LDAP_USER_BASEDN: ou=研发部,ou=发展中心,dc=abc,dc=cn
      LDAP_USER_REQUEST: (&(objectClass=inetOrgPerson)(cn={login}))
      LDAP_USER_REALNAMEATTRIBUTE: cn
      LDAP_USER_EMAILATTRIBUTE: mail
      LDAP_GROUP_BASEDN: ou=groups,dc=abc,dc=cn
      LDAP_GROUP_REQUEST: (&(objectClass=groupOfUniqueNames)(uniqueMember={dn}))
      LDAP_GROUP_IDATTRIBUTE: cn
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_extensions:/opt/sonarqube/extensions
      - sonarqube_logs:/opt/sonarqube/logs
    ports:
      - "9000:9000"
volumes:
  sonarqube_data:
  sonarqube_extensions:
  sonarqube_logs:
  postgresql:
  postgresql_data:

```
### Jenkins配置sonarqube
- 在sonarqube中生成token。登录web页面，在页面上找到Administration > 我的账号 > 安全 > 生成令牌
- 在Jenkins中安装sonarqube scanner插件。系统管理 > 插件管理 > 可选插件 > 搜索sonarqube scanner
- 在Jenkins中配置连接sonarqube服务器的地址。系统管理 > 系统设置 > sonarqube servers。
  - 配置Name、Server URL、token
- 在Jenkins的pipeline中配置sonarqub scanner。
  ```bash
     stage('SonarQube analysis') {
         steps {
             withSonarQubeEnv('SonarQubeServer') {
                 sh '/usr/local/sonar-scanner/bin/sonar-scanner ' +
                 "-Dsonar.projectKey=自己生成随机字符串 " +
                 "-Dsonar.projectName=project-name " +
                 "-Dsonar.sourceEncodeing=UTF-8" +
                 "-Dsonar.language=java " +
                 "-Dsonar.projectVersion=1.0 " +
                 "-Dsonar.java.binaries=."
             }
         }
     }
  ```