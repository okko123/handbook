## calico 配置路由反射模式
### 网络架构图![](img/k8s-bgp-1.png)
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
   
   calicoctl apply -f infra01_node.yaml
   ```
3. 配置BGPPeer资源，告诉Node节点路由反射器。根据实际选择单RR，还是双RR
   - 单RR节点部署
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
   - 多RR节点部署（多个主机节点作为RR）
     ```bash
     cat << EOF | calicoctl create -f -
     apiVersion: projectcalico.org/v3
     kind: BGPPeer
     metadata:
       name: rrs-mesh
     spec:
       nodeSelector: has(i-am-a-route-reflector)
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
- [H3C交换机配置OSPF导入外部路由](https://www.h3c.com/cn/d_201802/1065959_30005_0.htm#_Toc505352341)
- [H3C交换机配置BGP与IGP交互配置](https://www.h3c.com/cn/d_201802/1065961_30005_0.htm#_Toc505352832)
- [Kubernetes网络组件之Calico策略实践(BGP、RR、IPIP)](https://blog.51cto.com/14143894/2463392?source=drh)