## kubernetes问题记录
### kubect get cs出现scheduler、controller-manager出现connection refused的报错
- 由于上游kubernetes弃用组件状态，在1.18.8上scheduler、controller-manager监听的为10257、10259，并使用https协议。[信息来源](https://github.com/Azure/AKS/issues/173)
### kube-proxy启用ipvs模式
- 默认情况下，kube-proxy不启用ipvs模式，需要修改kube-proxy的configmap
  ```bash
  # 将mode的值修改为ipvs
  kubectl edit configmap -n kube-system kube-proxy
  kubectl rollout restart -n kube-system daemonset/kube-proxy

  # 修改完毕后需要重启所有kube-proxy的容器
  for pod in `kubectl get pods -n kube-system|grep kube-proxy|awk '{print $1}'`
  do
    kubectl delete pods -n kube-system $pod
  done
  ```

### Kubernetes 问题定位技巧：容器内抓包
```bash
在使用 kubernetes 跑应用的时候，可能会遇到一些网络问题，比较常见的是服务端无响应(超时)或回包内容不正常，如果没找出各种配置上有问题，这时我们需要确认数据包到底有没有最终被路由到容器里，或者报文到达容器的内容和出容器的内容符不符合预期，通过分析报文可以进一步缩小问题范围。那么如何在容器内抓包呢？本文提供实用的脚本一键进入容器网络命名空间(netns)，使用宿主机上的tcpdump进行抓包。

使用脚本一键进入 pod netns 抓包
发现某个服务不通，最好将其副本数调为1，并找到这个副本 pod 所在节点和 pod 名称

kubectl get pod -o wide
Copy
登录 pod 所在节点，将如下脚本粘贴到 shell (注册函数到当前登录的 shell，我们后面用)

  function e() {
      set -eu
      ns=${2-"default"}
      pod=`kubectl -n $ns describe pod $1 | grep -A10 "^Containers:" | grep -Eo 'docker://.*$' | head -n 1 | sed 's/docker:\/\/\(.*\)$/\1/'`
      pid=`docker inspect -f {{.State.Pid}} $pod`
      echo "entering pod netns for $ns/$1"
      cmd="nsenter -n --target $pid"
      echo $cmd
      $cmd
  }
Copy
一键进入 pod 所在的 netns，格式：e POD_NAME NAMESPACE，示例：

e istio-galley-58c7c7c646-m6568 istio-system
e proxy-5546768954-9rxg6 # 省略 NAMESPACE 默认为 default
Copy
这时已经进入 pod 的 netns，可以执行宿主机上的 ip a 或 ifconfig 来查看容器的网卡，执行 netstat -tunlp 查看当前容器监听了哪些端口，再通过 tcpdump 抓包：

tcpdump -i eth0 -w test.pcap port 80
Copy
ctrl-c 停止抓包，再用 scp 或 sz 将抓下来的包下载到本地使用 wireshark 分析，提供一些常用的 wireshark 过滤语法：

# 使用 telnet 连上并发送一些测试文本，比如 "lbtest"，
# 用下面语句可以看发送的测试报文有没有到容器
tcp contains "lbtest"
# 如果容器提供的是http服务，可以使用 curl 发送一些测试路径的请求，
# 通过下面语句过滤 uri 看报文有没有都容器
http.request.uri=="/mytest"
Copy
脚本原理
我们解释下步骤二中用到的脚本的原理
查看指定 pod 运行的容器 ID
kubectl describe pod <pod> -n mservice
Copy
获得容器进程的 pid
docker inspect -f {{.State.Pid}} <container>
Copy
进入该容器的 network namespace
nsenter -n --target <PID>
Copy
依赖宿主机的命名：kubectl, docker, nsenter, grep, head, sed
```
### Pod 拓扑分布约束
```yml
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  topologySpreadConstraints:
    - maxSkew: <integer>
      topologyKey: <string>
      whenUnsatisfiable: <string>
      labelSelector: <object>
```
- 你可以定义一个或多个 topologySpreadConstraint 来指示 kube-scheduler 如何根据与现有的 Pod 的关联关系将每个传入的 Pod 部署到集群中。字段包括：
  - maxSkew 描述 Pod 分布不均的程度。这是给定拓扑类型中任意两个拓扑域中 匹配的 pod 之间的最大允许差值。它必须大于零。取决于 whenUnsatisfiable 的 取值，其语义会有不同。
当 whenUnsatisfiable 等于 "DoNotSchedule" 时，maxSkew 是目标拓扑域 中匹配的 Pod 数与全局最小值之间可存在的差异。
当 whenUnsatisfiable 等于 "ScheduleAnyway" 时，调度器会更为偏向能够降低 偏差值的拓扑域。
  - topologyKey 是节点标签的键。如果两个节点使用此键标记并且具有相同的标签值， 则调度器会将这两个节点视为处于同一拓扑域中。调度器试图在每个拓扑域中放置数量 均衡的 Pod。
whenUnsatisfiable 指示如果 Pod 不满足分布约束时如何处理：
  - DoNotSchedule（默认）告诉调度器不要调度。
  - ScheduleAnyway 告诉调度器仍然继续调度，只是根据如何能将偏差最小化来对 节点进行排序。
  - labelSelector 用于查找匹配的 pod。匹配此标签的 Pod 将被统计，以确定相应 拓扑域中 Pod 的数量。 有关详细信息，请参考标签选择算符。


- https://kubernetes.io/zh/docs/concepts/workloads/pods/pod-topology-spread-constraints/ 

### kubernetes上报Pod已用内存不准问题分析
- https://cloud.tencent.com/developer/article/1637682
- 监控数据是采集的kubernetes上报的container_memory_working_set_bytes字段：
- 分析kubernetes代码可以看到container_memory_working_set_bytes是取自cgroup memory.usage_in_bytes 与memory.stat total_inactive_file两者的差值:
- 分析内核代码发现memory.usage_in_bytes的统计数据是包含了所有的file cache的， total_active_file和total_inactive_file都属于file cache的一部分，并且这两个数据并不是业务真正占用的内存，只是系统为了提高业务的访问IO的效率，将读写过的文件缓存在内存中，file cache并不会随着进程退出而释放，只会当容器销毁或者系统内存不足时才会由系统自动回收。
- kubectl top pod 得到的内存使用量，并不是 cadvisor 中的 container_memory_usage_bytes，而是 container_memory_working_set_bytes，计算方式为：
  - container_memory_usage_bytes = container_memory_rss + container_memory_cache + kernel memory
  - container_memory_working_set_bytes = container_memory_usage_bytes – total_inactive_file（未激活的匿名缓存页）
  - container_memory_working_set_bytes 是容器真实使用的内存量，也是 limit限制时的 oom 判断依据。
  - cadvisor 中的 container_memory_usage_bytes 对应 cgroup 中的 memory.usage_in_bytes 文件，但 container_memory_working_set_bytes 并没有具体的文件，他的计算逻辑在 cadvisor 的代码中
- [参考连接](https://imroc.io/posts/kubernetes/capture-packets-in-container/)
---
### 添加master节点
1. 在master上生成新的token，这一步跟node节点加入相同
   ```bash
   kubeadm token create --print-join-command
   kubeadm join 127.0.0.1:8443 --token izskvs.zusj16444vhnc725 --discovery-token-ca-cert-hash sha256:263be26e9eeb814bfb33eeb75595a199624860913c8285270395fa9a938d2948
   ```
2. 在master节点上传证书；执行完会在kube-system名称空间下创建名为kubeadm-certs的Secret，里面包含master节点需要用到的证书公钥和私钥。
   ```bash
   kubeadm init phase upload-certs --upload-certs
   [upload-certs] Storing the certificates in Secret "kubeadm-certs" in the "kube-system" Namespace
   [upload-certs] Using certificate key:
   d82a6f600fe57cb4f7dc703e674e3f6458b67f5b7480a7fb8a4f83daab96182f
   ```
3. 在新的master节点上执行加入命令；跟node节点相比就多了--control-plane为控制平台，需要带上certificate key
   ```bash
   kubeadm join 127.0.0.1:8443 --token izskvs.zusj16444vhnc725 \
     --discovery-token-ca-cert-hash sha256:263be26e9eeb814bfb33eeb75595a199624860913c8285270395fa9a938d2948 \
     --control-plane --certificate-key d82a6f600fe57cb4f7dc703e674e3f6458b67f5b7480a7fb8a4f83daab96182f
   ```
---
### k8s用户
- system:serviceaccounts代表serviceaccounts用户组
- system:unauthenticated代表匿名用户组

服务账户 的用户名前缀为 system:serviceaccount:，属于前缀为 system:serviceaccounts: 的用户组。

说明：
system:serviceaccount: （单数）是用于服务账户用户名的前缀；
system:serviceaccounts: （复数）是用于服务账户组名的前缀。
- [使用 RBAC 鉴权](https://kubernetes.io/zh/docs/reference/access-authn-authz/rbac/)



链接：https://www.zhihu.com/question/526869937/answer/2011558095755696079

---
### 故障案例
- 场景四：DNS 解析时有时无，nslookup 正常但 curl 失败？这个问题特别诡异。你在 Pod 里执行 nslookup kubernetes.default，返回 IP 正常；但 curl http://my-service 却超时。很多人以为是 CoreDNS 崩了，其实更可能是 DNS 缓存 + ndots 陷阱。K8s 默认给 Pod 的 /etc/resolv.conf 加了 ndots:5，意思是：如果域名中点少于 5 个，就先尝试拼接 search domain（比如 my-service.namespace.svc.cluster.local）。但如果 search domain 太多，或者网络延迟高，就会导致 DNS 查询超时重试，最终失败。
   ```bash
   # 验证方法：# 进入 Pod
   kubectl exec -it your-pod -- sh
   ​
   # 查看 resolv.conf
   cat /etc/resolv.conf
   ​
   # 手动测试带完整域名的解析（绕过 ndots）
   nslookup my-service.namespace.svc.cluster.local
   ​
   # 对比短域名
   nslookup my-service如果短域名慢或失败，长域名正常，基本就是 ndots 问题。解决方案：应用层改用 FQDN（完整域名）：比如代码里写 http://my-service.namespace.svc.cluster.local:8080；调整 Pod 的 dnsConfig：
   spec:
     dnsConfig:
       options:
         - name: ndots
           value: "1"
         - name: timeout
           value: "2"
           # 升级 CoreDNS 到最新版，并开启缓存插件（cache 30）；
           # 监控 CoreDNS 的 latency 和 error rate，用 Prometheus + Grafana 做告警。
           # 冷知识：K8s 1.27+ 已支持 dnsPolicy: ClusterFirstWithHostNet，对 hostNetwork Pod 更友好。
   ```