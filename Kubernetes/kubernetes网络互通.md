## kubernetes 网络互通
### 使用node节点进行流量转发
- k8s 集群中新加一台配置不高（2核4G）的 node 节点（node-3）专门做路由转发，连接办公室网络和 k8s 集群 pod、svc。
  - node-3 IP 地址 10.129.83.159
  - 内网DNS IP 地址 10.129.83.159
  - pod网段 172.20.0.0/16，svc网段 10.68.0.0/16
  - 办公网段 10.129.0.0/24
- 给node-3节点打上污点标签（taints），不让 k8s 调度 pod 来占用资源：kubectl taint nodes node-3 forward=node-3:NoSchedule
- 在node-3节点，做snat
  ```bash
  cat > /etc/sysctl.d/k8s.conf << EOF
  net.ipv4.ip_forward = 1
  EOF
  sysctl -p

  iptables -t nat -A POSTROUTING -s 10.129.0.0/24 -d 172.20.0.0/16 -j MASQUERADE
  iptables -t nat -A POSTROUTING -s 10.129.0.0/24 -d 10.68.0.0/16 -j  MASQUERADE
  ```
- 在办公室的出口路由器上，设置静态路由，将 k8s pod 和 service 的网段，路由到 node-3节点上
  ```bash
  ip route 172.20.0.0 255.255.0.0 10.129.83.159
  ip route 10.68.0.0  255.255.0.0 10.129.83.159
  ```
- 自建DNS，建议使用coreDNS
- 参考连接：
  - [办公环境下k8s网络互通方案](https://www.cnblogs.com/xiaobao2/p/11461345.html)
  - [让外部的开发机直接访问Kubernetes群集内的服务！](https://www.jianshu.com/p/6d408880c346)
### 使用vpn方式进行流量转发
### 通过Telepresence联通kubernetes
- 需要在客户端上安装一下组件，并且在客户端上配置kubectl.conf的用户凭证
  - docker
  - kubectl
  - telepresence
- 参考连接：
  - https://www.telepresence.io/
  - [自从用上 Telepresence 后，本地调试 Kubernetes 中的微服务不再是梦！](https://cloud.tencent.com/developer/article/1537743)
  - [用Telepresence在本地调试Kubernetes服务](https://cloud.tencent.com/developer/article/1548539)



