## WireGuard 组网
---
### 点对点组网
- 服务器A的信息
  - OS: Ubuntu 20.04
  - IP: 192.168.0.10
  - 虚拟IP：172.16.1.11(内网: 172.16.11.0/24)
- 服务器B的信息
  - OS: Ubuntu 20.04
  - IP: 192.168.0.20
  - 虚拟IP：172.16.1.12(内网: 172.16.12.0/24)
- 安装WireGuard，并生成key
  ```bash
  apt install -y wireguard

  cd /etc/wireguard/
  wg genkey | tee privatekey | wg pubkey > publickey
  ```
- 服务器A上执行以下配置
  ```bash
  cat > wg0.conf <<EOF
  [Interface]
  Address = 172.16.1.11/24
  ListenPort = 16000
  PrivateKey = eDAKXVHliMhTsbAeodifK8insJNM633MwMyYWl8FHFw=   #本端 Privatekey
  
  [Peer]
  PublicKey = YJsN6XOCY+9nTFXuTjtKHnh/Xxq6bLEtH8iI9s3TEzI=    #对端 Publickey
  AllowedIPs = 172.16.1.12/32,172.16.12.0/24
  Endpoint = 192.168.0.20:16000
  PersistentKeepalive = 25
  EOF
  ```
- 服务器A上执行以下配置
  ```bash
  cat > wg0.conf <<EOF
  [Interface]
  Address = 172.16.1.12/24
  ListenPort = 16000
  PrivateKey = eDAKXVHliMhTsbAeodifK8insJNM633MwMyYWl8FHFw=   #本端 Privatekey
  
  [Peer]
  PublicKey = YJsN6XOCY+9nTFXuTjtKHnh/Xxq6bLEtH8iI9s3TEzI=    #对端 Publickey
  AllowedIPs = 172.16.1.12/32,172.16.12.0/24
  Endpoint = 192.168.0.20:16000
  PersistentKeepalive = 25
  EOF
  ```
- wireguard启动
  ```bash
  # 启动
  wg-quick up /etc/wireguard/wg0.conf

  # 停止
  wg-quick down /etc/wireguard/wg0.conf

  # 查看组网状态
  wg show all
  ```
---
### 参考连接
- [个人办公用 wireguard 组网笔记](https://zhangguanzhang.github.io/2020/08/05/wireguard-for-personal/)
- [WireGuard 教程：WireGuard 的搭建使用与配置详解](https://fuckcloudnative.io/posts/wireguard-docs-practice/)