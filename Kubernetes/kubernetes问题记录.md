## kubernetes问题记录
### kubect get cs出现scheduler、controller-manager出现connection refused的报错
- 由于上游kubernetes弃用组件状态，在1.18.8上scheduler、controller-manager监听的为10257、10259，并使用https协议。[信息来源](https://github.com/Azure/AKS/issues/173)
### kube-proxy启用ipvs模式
- 默认情况下，kube-proxy不启用ipvs模式，需要修改kube-proxy的configmap
  ```bash
  # 将mode的值修改为ipvs
  kubectl edit configmap -n kube-system kube-proxy

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
- [参考连接](https://imroc.io/posts/kubernetes/capture-packets-in-container/)