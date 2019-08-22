# rabbitmq部署安装笔记
* 安装erlang
```bash
#Adding repository
yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y
wget https://packages.erlang-solutions.com/erlang-solutions-1.0-1.noarch.rpm
rpm -Uvh erlang-solutions-1.0-1.noarch.rpm
yum clean all
yum makecache

#Install erlang
yum install erlang -y
```
* 安装rabbitmq
```bash
#Install rabbitmq
rpm --import https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey
rpm --import https://packagecloud.io/gpg.key
rpm --import https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc
cat > /etc/yum.repos.d/rabbitmq.repo << 'EOF'
[bintray-rabbitmq-server]
name=bintray-rabbitmq-rpm
baseurl=https://dl.bintray.com/rabbitmq/rpm/rabbitmq-server/v3.7.x/sles/11
gpgcheck=0
repo_gpgcheck=0
enabled=1
EOF
rpm --import https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc
yum install rabbitmq-server-3.7.17-1.el7.noarch.rpm
yum install rabbitmq-server-3.7.17
```

* 使用rabbitmqctl配置vhosts、用户、密码、权限
```bash
rabbitmqctl add_vhost VHOST_NAME
rabbitmqctl add_user USER PASSWORD
rabbitmqctl set_permissions -p VHOST_NAME USER '.*' '.*' '.*'
```
* 使用rabbitmq-plugins开启management web ui
```bash
# 默认访问端口15672，guest用户只允许localhost进行访问
rabbitmq-plugins enable rabbitmq_management
```
* 参考信息
  - [rabbitmq官方文档](https://www.rabbitmq.com/install-rpm.html)
  - [rabbitmq内存使用](https://www.rabbitmq.com/memory-use.html)
  - [erlang官方文档](https://www.erlang-solutions.com/resources/download.html)
  - [权限配置](https://www.jianshu.com/p/7d071bffea24)