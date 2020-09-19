## kubectl工具使用
* 创建资源：kubectl create
    * configmap
    * deployment
    * namespace
    * service
    * secret
* 获取信息：kubectl get;列出受支持的资源类型(kubectl api-resources)
    * all
    * configmaps (aka 'cm')
    * deployments (aka 'deploy')
    * endpoints (aka 'ep')
    * ingresses (aka 'ing')
    * jobs
    * namespaces (aka 'ns')
    * nodes (aka 'no')
    * persistentvolumeclaims (aka 'pvc')
    * persistentvolumes (aka 'pv')
    * pods (aka 'po')
    * secrets
    * services (aka 'svc')
    * certificatesigningrequests (aka 'csr')
* 获取yaml配置文件帮助：kubectl explain
* 删除资源：kubectl delete
  * pods
  * deployment
* 获取集群pod、service的CIDR记录
  * kubectl cluster-info dump | grep -m 1 service-cluster-ip-range
  * kubectl cluster-info dump | grep -m 1 cluster-cidr
## kubernetes 污点使用
* kubectl taint node [node] key=value[effect]   
  * 其中[effect] 可取值: [ NoSchedule | PreferNoSchedule | NoExecute ]
  * NoSchedule: 一定不能被调度
  * PreferNoSchedule: 尽量不要调度
  * NoExecute: 不仅不会调度, 还会驱逐Node上已有的Pod
  ```bash
  ## master节点设置taint
  kubectl taint nodes master1 node-role.kubernetes.io/master=:NoSchedule
  ## 所有节点删除taint
  kubectl taint nodes --all node-role.kubernetes.io/master-
  ```
## kubernetes pv和pvc使用记录
* https://kubernetes.io/zh/docs/concepts/storage/volumes/#hostpath
## alphine系统使用笔记
* 安装telnet：apk add busybox-extras
## docker使用命令
* 运行alphine系统，并进入命令行：docker run -it alphine:lastest
## 参考链接
* http://docs.kubernetes.org.cn/537.html
* https://kubernetes.io/docs/concepts/services-networking/ingress/