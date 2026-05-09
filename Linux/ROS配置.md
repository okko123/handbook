# ROS配置
---
### 配置情况
* ether1的ip: 10.0.0.254; 接入内网，asNumber: 64512
* ether2的ip: 172.16.81.188; 接入公网
* k8s集群的ip: 10.0.0.20 - 10.0.0.23，asNumber: 64513
* 测试用客户端的ip: 10.0.0.50
---
### 配置ip地址和默认路由
```bash
/ip/address/add address=10.0.0.254/24 interface=ether1
/ip/address/add address=172.16.81.188/24 interface=ether2
/ip/router/add dst-address=0.0.0.0/0 gateway=172.16.81.254
```
---
### 配置桥接转发流量
```bash
/ip/firewall/nat/add action=masquerade chain=srcnat out-interface=ether2
```
---
### 配置BGP Peer; as为路由端的编号，router-id使用路由器的IP作为ID
```bash
/routing/bgp/instance/add name=default as=64512 router-id=10.1.1.254

/routing/bgp/connection/add name=peer1 \
instance=default \
remote.address=10.1.1.20/32 \
remote.as=64513 \
local.role=ebgp \
connect=yes \
listen=yes

/routing/bgp/connection/add name=peer2 \
instance=default \
remote.address=10.1.1.21/32 \
remote.as=64513 \
local.role=ebgp \
connect=yes \
listen=yes

/routing/bgp/connection/add name=peer3 \
instance=default \
remote.address=10.1.1.22/32 \
remote.as=64513 \
local.role=ebgp \
connect=yes \
listen=yes
```
---
### 在使用 Node-to-Node Mesh 的情况下，每增加一个 K8s 节点就要在 RouterOS 手动配置一个 Peer 确实非常低效。
1. 利用 RouterOS 7 的 BGP Dynamic Listen
   - 扩容 K8s 节点时，只要 IP 在 10.0.0.20-10.0.0.50 范围内，RouterOS 会自动创建 Peer，无需任何手动操作。
     ```bash
     /routing/bgp/connection/add \
         name=k8s-dynamic-mesh \
         remote.address-list=10.0.0.0/24 \
         remote.as=64512 \
         listen=yes \
         local.role=ebgp \
         templates=default

     # 在 Address List 中定义你的 K8s 节点网段
     /ip/firewall/address-list/add address=10.0.0.20-10.0.0.50 list=k8s-nodes-list

     # 进阶优化：配合 IP Firewall Address List（更安全）
     # 如果你希望更精细地控制哪些 IP 可以建立 BGP，虽然 connection 命令行里没有 address-list 参数，但你可以通过 Firewall (Input 链) 来配合：
     # 在 connection 中设置 remote.address=0.0.0.0/0（允许所有）。

     /ip/firewall/address-list/add address=10.0.0.21-10.0.0.30 list=k8s-nodes
     /ip/firewall/filter/add action=accept chain=input dst-port=179 protocol=tcp src-address-list=k8s-nodes comment="Allow BGP from K8s nodes"
     /ip/firewall/filter/add action=drop chain=input dst-port=179 protocol=tcp comment="Drop other BGP"
     ```
2. 配置 Calico 路由反射器 (Route Reflector)
```bash
## ros端配置
/routing/bgp/connection/add \
name=peer \
instance=default \
remote.address=10.1.1.21 \
remote.as=64513 \
local.role=ebgp \
connect=yes \
listen=yes

## calico 端配置
kubectl label node worker01 rack=rack-1
kubectl annotate node worker01 projectcalico.org/RouteReflectorClusterID=244.0.0.1
kubectl label node worker01 route-reflector=true

cat > peer-1.yaml <<EOF
apiVersion: projectcalico.org/v3
kind: BGPPeer
metadata:
  name: rack1-tor
spec:
  # 交换机or路由器的IP地址
  peerIP: 10.1.1.254
  # 交换机or路由器的AS号
  asNumber: 64512
  nodeSelector: rack == 'rack-1'
EOF
./calicoctl apply -f peer-1.yaml

cat > peer-2.yaml <<EOF
kind: BGPPeer
apiVersion: projectcalico.org/v3
metadata:
  name: peer-with-route-reflectors
spec:
  nodeSelector: all()
  peerSelector: route-reflector == 'true'
EOF
./calicoctl apply -f peer-2.yaml

cat > bgp-config.yaml <<EOF
apiVersion: projectcalico.org/v3
kind: BGPConfiguration
metadata:
  name: default
spec:
  logSeverityScreen: Info
  nodeToNodeMeshEnabled: false
  asNumber: 64512
EOF
./calicoctl apply -f bgp-config.yaml
```

检查
kubectl -n kube-system exec -it calico-node-w8tx9 -- birdcl show protocols