# haproxy安装配置
* OS: CentOS7
* haproxy: 1.9.8

* 配置rsyslog接收日志，打开udp监听514端口
  ```bash
  cat > /etc/rsyslog.d/haproxy.conf <<'EOF'
  # Collect log with UDP
  $ModLoad imudp
  $UDPServerAddress 127.0.0.1
  $UDPServerRun 514

  # Creating separate log files based on the severity
  local0.* /var/log/haproxy-traffic.log
  local0.notice /var/log/haproxy-admin.log

  # Restart rsyslog service
  systemctl restart rsyslog
  ```

* 修改haproxy配置文件，添加log的配置。[haproxy.conf](conf/haproxy.conf)

---
### 参考连接
* [HAPROXY官方blog](https://www.haproxy.com/blog/introduction-to-haproxy-logging/)