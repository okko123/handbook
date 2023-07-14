### v2ray linux客户端
```bash
wget https://github.com/v2fly/v2ray-core/releases/download/v4.31.0/v2ray-linux-64.zip
mkdir v2ray
unzip -d v2ray v2ray-linux-64.zip

bash <(curl -L -s https://install.direct/go.sh)
此脚本会自动安装以下文件：

/usr/bin/v2ray/v2ray：V2Ray 程序；
/usr/bin/v2ray/v2ctl：V2Ray 工具；
/etc/v2ray/config.json：配置文件；
/usr/bin/v2ray/geoip.dat：IP 数据文件
/usr/bin/v2ray/geosite.dat：域名数据文件
```
=== Docker使用socks5代理
1.创建docker服务插件目录
  ```bash
  sudo mkdir -p /etc/systemd/system/docker.service.d
  ```
2.创建一个名为http-proxy.conf的文件
  ```bash
  sudo touch /etc/systemd/system/docker.service.d/http-proxy.conf
  ```
3.编辑http-proxy.conf的文件
  ```bash
  sudo vim /etc/systemd/system/docker.service.d/http-proxy.conf
  ```
4.写入内容(将代理ip和代理端口修改成你自己的)
  ```bash
  [Service]
  Environment="HTTP_PROXY=socks5://127.0.0.1:1080" "HTTPS_PROXY=socks5://127.0.0.1:1080" "NO_PROXY=localhost,127.0.0.1,docker-registry.somecorporation.com"
  ```
5.重新加载服务程序的配置文件
  ```bash
  sudo systemctl daemon-reload
  ```
6.重启docker
  ```bash
  sudo systemctl restart docker
  ```
7.验证是否配置成功
  ```bash
  systemctl show --property=Environment docker
  ```