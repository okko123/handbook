ctr、crictl的用法

### crictl的配置文件
cat > /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: true
EOF

### 查看命名空间
ctr ns ls

### 镜像标记tag
ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.2 k8s.gcr.io/pause:3.2
注意: 若新镜像reference 已存在, 需要先删除新reference, 或者如下方式强制替换
ctr -n k8s.io i tag --force registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.2 k8s.gcr.io/pause:3.2

删除镜像
ctr -n k8s.io i rm k8s.gcr.io/pause:3.2

拉取镜像
ctr -n k8s.io i pull -k k8s.gcr.io/pause:3.2

推送镜像
ctr -n k8s.io i push -k k8s.gcr.io/pause:3.2

导出镜像
ctr -n k8s.io i export pause.tar k8s.gcr.io/pause:3.2

导入镜像
ctr -n k8s.io i import pause.tar

不支持 build,commit 镜像

查看容器相关操作
ctr c

运行容器
签名:ctr run [command options] [flags] Image|RootFS ID [COMMAND] [ARG…]
例子:
ctr -n k8s.io run --null-io --net-host -d
–env PASSWORD=$drone_password
–mount type=bind,src=/etc,dst=/host-etc,options=rbind:rw
–mount type=bind,src=/root/.kube,dst=/root/.kube,options=rbind:rw
$image sysreport bash /sysreport/run.sh

–null-io: 将容器内标准输出重定向到/dev/null
–net-host: 主机网络
-d: 当task执行后就进行下一步shell命令,如没有选项,则会等待用户输入,并定向到容器内
容器日志
注意: 容器默认使用fifo创建日志文件, 如果不读取日志文件,会因为fifo容量导致业务运行阻塞
如要创建日志文件,建议如下方式创建:
ctr -n k8s.io run --log-uri file:///var/log/xx.log …

停止容器, 需要先停止容器内的task, 再删除容器
ctr -n k8s.io tasks kill -a -s 9 {id}
ctr -n k8s.io c rm {id}

2 crictl用法
crictl 工具 是为k8s使用containerd而制作的, 其他非k8s的创建的 crictl是无法看到和调试的, 也就是说用ctr run 运行的容器无法使用crictl 看到
crictl 使用命名空间 k8s.io.

cri plugin区别对待pod和container

ps: 列出在k8s.io 命名空间下的业务容器
pods: 列出在k8s.io 命名空间下的sandbox容器,在k8s里,通常是pause容器
logs: 打印业务容器日志
create: 创建容器,这里需要先创建sandbox, 获取sandbox容器的id后,再用此id创建业务容器
inspect: 列出业务容器状态
inspectp: 列出sandbox容器状态

---
- [使用 crictl 对 Kubernetes 节点进行调试](https://kubernetes.io/zh/docs/tasks/debug-application-cluster/crictl/)