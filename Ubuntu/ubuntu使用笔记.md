### ubuntu 使用笔记
- 设置时区：timedatectl set-timezone Asia/Shanghai
- 设置24小时的时间格式：localectl set-locale LC_TIME=C.UTF-8
- 修改系统时间
  - 关闭时间同步: timedatectl set-ntp 0
  - 设置时间: date -s "YY/MM/DD"，
    - 设置日期为2022-12-25: date -s 22/12/25
    - 设置时间为18点30分: date -s 18:30:00
    - 设置指导日期时间2022-12-25 18点30分: 2022-12-15 18:00:00
### iso镜像写入u盘
- iso写入U盘：dd if=xxx.iso of=/dev/sda bs=4M。
  > dd工具可以响应USR1的信号，当收到此信号时，dd命令会向终端输出此时的进度信息。当将dd开始运行后，再打开一个终端窗口，输入：
    - 方法一: watch -n 5 pkill -USR1 ^dd$
    - 方法二: watch -n 5 killall -USR1 dd
    - 方法三: while killall -USR1 dd; do sleep 5; done

### ubuntu 安装v2ray
1.下载v2ray的二进制包
2.修改config.json文件
3.v2ray --config config.json启动

- docker使用socket5代理
  ```bash
  mkdir -p /etc/systemd/system/docker.service.d/
  cat > /etc/systemd/system/docker.service.d/http-proxy.conf <<EOF
  [Service]
  Environment="HTTP_PROXY=socks5://127.0.0.1:10808/" "HTTPS_PROXY=socks5://127.0.0.1:10808/"
  EOF
  
  systemctl daemon-reload
  systemctl restart docker
  ```
---
### 参考连接
- [V2Ray 配置指南](https://toutyrater.github.io/advanced/outboundproxy.html)