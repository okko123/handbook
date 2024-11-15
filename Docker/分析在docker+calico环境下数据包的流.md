## 使用iptables规则链分析在docker+calico环境下数据包的流向
1. 实验环境
   |系统|IP|节点|
   |-|-|-|
   |Ubuntu 22.04|192.168.1.1|A|
   |Ubuntu 22.04|192.168.1.2|B|
   |Ubuntu 22.04|192.168.1.3|c|
2. 运行服务
   1. docker版本
   2. calico版本
3. 设置iptables的调试日志
```bash
iptables -t raw -A OUTPUT -p icmp -j LOG
iptables -t raw -A PREROUTING -p icmp -j LOG
iptables -t raw -A OUTPUT -p icmp -j TRACE   
iptables -t raw -A PREROUTING -p icmp -j TRACE   

#调整rsyslog日志配置，添加kern日志记录
vim /etc/rsyslog.conf

kern.* /var/log/iptables.log

systemctl restart rsyslog
```
4. 创建测试容器
   1. 创建calico网络net1（节点A）
       ```bash
       docker network create --driver calico --ipam-driver calico-ipam net1
       ```
    2. 创建容器（节点A）
       ```bash
       docker run --net net1 --name web1 -itd  mybusybox    
       docker run --net net1 --name web2 -itd  mybusybox  
       ```
    3. 创建容器（节点B）
       ```bash
       docker run --net net1 --name web3 -itd  mybusybox    
       ```
---
### 测试场景
- 容器与宿主机之间的通信
- 容器与calico集群中非宿主机之间的通信
- 同节点上，不同容器之间的通信
- 跨节点环境下，不同容器之间的通信
---
1. 从宿主机到容器；总结：
   - 从宿主到容器，数据走的是OUTPUT链 --> POSTROUTING链
   - 容器给宿主的答复，走的是INPUT链
   - 只能在主链间跳转，不能是子链调主链
2. 从容器到宿主机；总结：
   - 从容器到宿主，数据走的是PREOUTING链 --> INPUT链
   - 宿主机答复容器，数据走的是OUTPUT链 
3. 从容器访问calico集群中的非宿主机
4. 从calico集群中的非宿主机访问容器
5. 同节点上，不同容器间的访问
6. 跨节点，容器间相互访问
---
### 参考信息
1. [使用iptables规则链分析在docker+calico环境下数据包的流向](https://www.jianshu.com/p/099ecf623eb5)