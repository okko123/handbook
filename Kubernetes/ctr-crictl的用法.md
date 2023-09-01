## ctr、crictl的用法
- ctr、crictl、docker命令的对比
  ---
  |命令|Docker|Containerd|Containerd|
  |----|----|----|----|
  |命令|docker|crictl（推荐）|ctr|
  |查看容器列表|docker ps|crictl ps|ctr -n k8s.io c ls|
  |查看容器详情|docker inspect|crictl inspect|ctr -n k8s.io c info|
  |查看容器日志|docker logs|crictl logs|无|
  |容器内执行命令|docker exec|crictl exec|无|
  |挂载容器|docker attach|crictl attach|无|
  |显示容器资源使用情况|docker stats|crictl stats|无|
  |创建容器|docker create|crictl create|ctr -n k8s.io c create|
  |启动容器|docker start|crictl start|ctr -n k8s.io run|
  |停止容器|docker stop|crictl stop|无|
  |删除容器|docker rm|crictl rm|ctr -n k8s.io c del|
  |查看镜像列表|docker images|crictl images|ctr -n k8s.io i ls|
  |查看镜像详情|docker inspect|crictl inspecti|无|
  |拉取镜像|docker pull|crictl pull|ctr -n k8s.io i pull|
  |推送镜像|docker push|无|ctr -n k8s.io i push|
  |删除镜像|docker rmi|crictl rmi|ctr -n k8s.io i rm|
  |查看Pod列表|无|crictl pods|无|
  |查看Pod详情|无|crictl inspectp|无|
  |启动Pod|无|crictl runp|无|
  |停止Pod|无|crictl stopp|无|

- crictl的配置文件
  ```bash
  cat > /etc/crictl.yaml <<EOF
  runtime-endpoint: unix:///run/containerd/containerd.sock
  image-endpoint: unix:///run/containerd/containerd.sock
  timeout: 10
  debug: true
  EOF
  ```
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
ctr -n k8s.io image pull -u {username}:{password} --plain-http docker.xxx.cn:5000/maxfaith/miop_ui:development

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
- [如何丝滑般将 Kubernetes 容器运行时从 Docker 切换成 Containerd](https://mp.weixin.qq.com/s/Ry6m6dWMv_MRIHL0kh-uhA)