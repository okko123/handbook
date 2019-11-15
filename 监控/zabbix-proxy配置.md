# zabbix-proxy部署
* OS: CentOS 7
* zabbix: 3.2.11

## zabbix-proxy使用架构
![](img/zabbix-1.png)

## zabbix-proxy的源码安装
* zabbix_proxy使用主动模式，proxy主动去拉取agent的数据、主动推送数据到server上[zabbix_proxy.conf](conf/zabbix_proxy.conf)
```bash
yum install mariadb-devel -y
./configure --prefix=/usr/local/zabbix --enable-proxy --with-mysql
make
make install

# 新建数据库，zabbix-proxy只需要schema.sql
mysql> create database zabbix-proxy;
mysql> source schema.sql;

# zabbix-proxy启动，安装路径/usr/local/zabbix
/usr/local/zabbix/sbin/zabbix_proxy -c /usr/local/zabbix/etc/zabbix_proxy.conf
```

## 使用 config_cache_reload 选项重新加载 proxy 的配置缓存
/usr/local/zabbix/sbin/zabbix_proxy -c /usr/local/zabbix/etc/zabbix_proxy.conf

## web 界面配置
Administration -> Proxies -> Create proxy
其中Proxy name必须与proxy配置文件中的Hostname一致

### 参考连接
* [官方wiki](https://www.zabbix.com/documentation/3.2/manual/installation/install
* [zabbix_proxy数据库导入注意事项](https://www.zabbix.com/documentation/3.2/manual/appendix/install/db_scripts)