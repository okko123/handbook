## calico 配置路由反射模式
1. 关闭当前Calico Mesh模式
   ```bash
   cat << EOF | calicoctl create -f -
   apiVersion: projectcalico.org/v3
   kind: BGPConfiguration
   metadata:
     name: default
   spec:
     logSeverityScreen: Info
     nodeToNodeMeshEnabled: false
     asNumber: 63400
   EOF
   ```
2. 设置指定Node为RR，比如选择infra01_node为RR，“添加router-reflector标签，设置routeReflectorClusterID”。
   ```bash
   #先导出infra01_node的配置
   calicoctl get node infra01_node  --export -o yaml  > infra01_node.yaml

   #添加labels信息、routeReflectorClusterID信息
   cat infra01_node.yaml
   apiVersion: projectcalico.org/v3
   kind: Node
   metadata:
     labels:
       i-am-a-route-reflector: "true"
     name: infra01_node
   spec:
     bgp:
       ipv4Address: 192.168.0.3/16
       routeReflectorClusterID: 224.0.0.1
   
   calico apply -f infra01_node.yaml
   ```
3. 配置BGPPeer资源，告诉Node节点路由反射器。
   ```bash
   cat << EOF | calicoctl create -f -
   apiVersion: projectcalico.org/v3
   kind: BGPPeer
   metadata:
     name: peer-to-rrs
   spec:
     nodeSelector: !has(i-am-a-route-reflector)
     peerSelector: has(i-am-a-route-reflector)
   EOF
   ```
4. 查看bgppeer
```bash
calicoctl get bgppeers
 NAME          PEERIP   NODE                          ASN   
 peer-to-rrs            (global)                      0   
```
5. 通过netstat命令查看节点间calico-node的连接，可以看到非RR节点只与RR节点建立连接，而RR节点与所有节点建立连接。
```bash
netstat -natp | grep bird
```
### 参考信息
- [OpenShift支持Calico BGP 路由反射（RR）模式](https://www.jianshu.com/p/1ea22c6d26fd)