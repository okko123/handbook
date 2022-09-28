### OpenVPN使用MySQL认证
- OS: CentOS-7.6
- IP: 192.168.0.10

### OpenVPN安装参照
### MySQL安装
```bash
yum install -y mariadb-devel mariadb-libs

# 以docker方式拉取mariadb数据库
docker run \
--detach \
--name mariadb \
--env MYSQL_USER=example \
--env MYSQL_PASSWORD=secret \
--env MYSQL_ROOT_PASSWORD=secret \
--env MYSQL_ALLOW_EMPTY_PASSWORD=no \
-p 3306:3306 \
mariadb:10.5.6

# 登录mariadb，创建数据库、表、用户
> CREATE DATABASE IF NOT EXISTS openvpn DEFAULT CHARSET utf8;
> GRANT all on openvpn.* to openvpn@'%' identified by 'openvpn';
> FLUSH PRIVILEGE;
> USE openvpn;

# 创建user表和log表
> CREATE table user(name char(100)not null,password char(255)default null,active int(10)not null default 1,primary key(name));
> CREATE table log(msg char (254),user char(100),pid char(100),host char(100),rhost char(100),time char(100));

# 准备pam认证文件；pam配置参考github的pam_mysql页面。注意crypt设置为2，表示使用MySQL PASSWORD()函数
cat > /etc/pam.d/openvpn << EOF
auth sufficient pam_mysql.so user=openvpn passwd=openvpn host=192.168.0.10 db=openvpn table=user usercolumn=username passwdcolumn=password [where=user.active=1] sqllog=0 crypt=2
account required pam_mysql.so user=openvpn passwd=openvpn host=192.168.0.10 db=openvpn table=user usercolumn=username passwdcolumn=password [where=user.active=1] sqllog=0 crypt=2
EOF
```
---
### 检查
- 注意事项
  ```bash
  pam_mysql不能直接用yum install pam_mysql安装，系统自带的版本是0.7的，使用这个版本的话会导致后边OpenVPN  连接的时候认证不成功，/var/log/secure日志中会一直报下边错误

  openvpn: PAM unable to dlopen(/usr/lib64/security/pam_mysql.so): /usr/lib64/security/pam_mysql.  so: undefined symbol: pam_set_data
  openvpn: PAM adding faulty module: /usr/lib64/security/pam_mysql.so
  openvpn: PAM unable to dlopen(/usr/lib64/security/pam_mysql.so): /usr/lib64/security/pam_mysql.  so: undefined symbol: pam_set_data
  openvpn: PAM adding faulty module: /usr/lib64/security/pam_mysql.so
  openvpn: PAM unable to dlopen(/usr/lib64/security/pam_mysql.so): /usr/lib64/security/pam_mysql.  so: undefined symbol: pam_set_data
  ```
- 安装 cyrus-sasl工具验证pam认证
  ```bash
  yum install cyrus-sasl
  systemctl start saslauthd
  testsaslauthd -u xnile -p 123456 -s openvpn

  # 返回 0: OK "Success."则说明认证成功。
  ```
---
### 客户端配置
```bash
# 准备OpenVPN配置文件使用mysql认证

local 0.0.0.0
port 1194
proto udp
dev tun
user openvpn
group openvpn
ca ca.crt
cert server.crt
key server.key
dh dh.pem
#客户端地址池
server 10.255.255.0 255.255.255.0
#路由
push "route 192.168.1.0 255.255.255.255"
ifconfig-pool-persist ipp.txt 1
#心跳检测，10秒检测一次，2分钟内没有回应则视为断线
keepalive 10 120
#服务端值为0，客户端为1
tls-auth ta.key 0
cipher AES-256-CBC
#传输数据压缩
comp-lzo
persist-key
persist-tun
status openvpn-status.log
verb 3
verify-client-cert none
log "openvpn.log" 
#使用Mysql认证
plugin /usr/lib64/openvpn/plugins/openvpn-plugin-auth-pam.so "openvpn_mysql"
```
---
### 参考链接
- [CentOS 7安装OpenVPN并使用Mysql认证](https://blog.dianduidian.com/post/openvpn%E4%BD%BF%E7%94%A8mysql%E8%AE%A4%E8%AF%81/)
- [新版PAM_MySQL模块源代码](https://github.com/rikvdh/pam_mysql)