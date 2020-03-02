# CentOS7的新变化
目录
===
<!-- TOC -->
1. [修改主机名](#修改主机名)
2. [时间同步](#时间同步)
3. [修改时区](#修改时区)
4.
5.
6.
7. [服务管理](#服务管理)
<!-- /TOC -->
1. **修改主机名**
    - **CentOS6** : /etc/sysconfig/network
    - **CentOS7** : /etc/hostname 或者 $hostnamectl set-hostname new-hostname
2. **时间同步（chronyc的语法与ntpd类似）**
    - **CentOS6** : ntp && ntpq -p
    - **CentOS7**: chrony && chronyc sources
3. **修改时区**
    - **CentOS6** :
      ``` bash
      vim /etc/sysconfig/clock
      ZONE="Asia/Shanghai"
      UTC="no"
  
      #修改系统时区
      cp /usr/share/zoneinfo/Asia/Shanghai /etc/  localtime
      ```
  
    - **CentOS7** :
      ```bash
      timedatectl set-timezone Asia/Shanghai
      #查看当前系统设置的时间日期/时区
      timedatectl status
      ```
4. **修改地区**
    - **CentOS6** :
    - **CentOS7** :
        ``` bash
        localectl set-locale LANG=en_US.utf8
        #查看是否生效
        localectl status
        ```
5. **网络-IP配置**
    - **CentOS6** : 
        ```bash
        ifconfig -a
        ifconfig eth0 192.168.1.1/24
        route add default gw 192.168.1.254
        ```
   - **CentOS7** :
        ``` bash
        ip address show
        ip addr add 192.168.1.1/24 dev eth0
        ip route add default via 192.168.1.254 dev eth0

        #使用nmcli修改eth0网卡的配置
        nmcli connection modify eth0 ipv4.addresses 192.168.0.1/24 ipv4.dns 8.8.8.8,8.8.4.4 ipv4.method manual ipv6.method ignore
        ```
6. **网络-路由配置**
   - **CentOS6** : route -n / route -A inet6 -n
   - **CentOS7** : ip route show / ip -6 route show
7. **服务器管理**
    - **CentOS6** :
        ``` bash
        service service_name start/stop
        chkconfig service_name on/off
        chkconfig --list
        ```
    - **CentOS7** :
        ```bash
        systemctl start/stop/status/reload/restart      service_name
        systemctl enable/disable service_name
        systemctl list-unit-files
        systemctl list-unit-files NAME #单独显示当前服务是      否开启随机启动
        journalctl -u NAME.service --since today #过滤出指      定服务，今天的日志信息，
         ```
8. **sysctl系统参数配置**

## 文章参考
- [RHEL对/etc/sysconfig/clock内容说明](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/5/html/deployment_guide/ch-sysconfig#s2-sysconfig-clock)
- [RHEL对/etc/sysconfig/i18n内容说明](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/5/html/deployment_guide/ch-sysconfig#s2-sysconfig-i18n)
- [RHEL对timezonectl的使用说明](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system_administrators_guide/chap-configuring_the_date_and_time)
- [RHEL对localectl的使用说明](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system_administrators_guide/ch-keyboard_configuration)
- [RHEL对systemctl的使用说明](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system_administrators_guide/chap-managing_services_with_systemd)
