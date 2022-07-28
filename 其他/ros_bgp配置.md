- ROS
  - eth0: 10.1.1.234/24
  - eth1: 192.168.1.10/24
  - route-id: 6.6.6.6
  - AS: 6666
- VyOS
  - eth0: 10.1.1.235/24
  - eth1: 192.168.2.10/24
  - route-id: 6.6.6.6
  - AS: 6666
## 初始化，配置网卡eth3的ip，网关
/ip address add address=172.16.81.100 netmask=255.255.255.0 interface=ether3
/ip route add gateway=172.16.81.254

## 配置bgp路由
/ip address add address=192.168.0.253 netmask=255.255.255.0 interface=ether1
/routing bgp instance set default as=63400 redistribute-static=no
/routing bgp peer add remote-address=192.168.0.15 remote-as=63400 address-familers=ip
/routing bgp network add network=192.168.1.0/24

## 配置NAT
/ip firewall net add chain=scrnat action=masquerade

## 配置DNS
/ip dns set servers=223.5.5.5,223.6.6.6