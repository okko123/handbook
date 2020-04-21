## kubectl工具使用
* 创建资源：kubectl create
    * configmap
    * deployment
    * namespace
    * service
    * secret
* 获取信息：kubectl get
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
* 获取yaml配置文件帮助：kubectl explain
* 删除资源：kubectl delete
  * pods
  * deployment
## kubenetest pv和pvc使用记录
* https://kubernetes.io/zh/docs/concepts/storage/volumes/#hostpath
## alphine系统使用笔记
* 安装telnet：apk add busybox-extras
## docker使用命令
* 运行alphine系统，并进入命令行：docker run -it alphine:lastest
## 参考链接
* http://docs.kubernetes.org.cn/537.html
* https://kubernetes.io/docs/concepts/services-networking/ingress/