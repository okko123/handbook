## pmm监控工具使用
### 使用docker方式部署pmm-server

### 数据库配置
- 登录数据库创建监控用户
  ```mysql
  CREATE USER 'pmm'@'192.168.1.1' IDENTIFIED BY 'pass' WITH MAX_USER_CONNECTIONS 10;
  GRANT SELECT, PROCESS, SUPER, REPLICATION CLIENT, RELOAD ON *.* TO 'pmm'@'192.168.1.1';
  ```
- 安装pmm-agent，使用pmm2。pmm-server地址为192.168.1.100
  ```bash
  rpm -ivh https://downloads.percona.com/downloads/pmm2/2.23.0/binary/redhat/7/x86_64/pmm2-client-2.23.0-6.el7.x86_64.rpm
  
  # 初始化pmm-agent
  pmm-agent setup --config-file=/usr/local/percona/pmm2/config/pmm-agent.yaml --server-address=192.168.1.100 --server-insecure-tls --server-username=admin --server-password=admin
  
  # 添加监控mysql实例；pmm-admin add mysql --username=pmm --password=pass  --query-source=perfschema SERVICE_NAME MYSQL_INSTANCE
  pmm-admin add mysql --username=pmm --password=pass  --query-source=perfschema 3306-ip-192-168-1-10 192.168.1.10:3306

  # 添加监控mongo实例；
  sudo pmm-admin add mongodb --username=pmm_mongodb --password=password --query-source=profiler --cluster=test-cluster --host=192.168.1.20 --environment=qa --service-name=mongo-ip-192.168.1.20 --port=27017
  ```