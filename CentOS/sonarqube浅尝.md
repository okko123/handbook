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
      hostname: sonarqube.qdama.cn
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