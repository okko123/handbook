## kubernetes故障排查
### 节点not ready故障排查
```bash
[root@test-master-113 ~]# kubectl get nodes 
NAME              STATUS                            AGE       VERSION
test-master-113   Ready,SchedulingDisabled,master   347d      v1.7.6
test-slave-114    Ready                             206d      v1.7.6-custom
test-slave-115    NotReady                          292d      v1.7.6-custom
test-slave-116    Ready                             164d      v1.7.6-custom
test-slave-117    Ready                             292d      v1.7.6-custom

#not ready 的节点上的pod的状况
kubectl get pods -n kube-system -owide | grep test-slave-115
kubectl-m77z1                               1/1       NodeLost   1          24d       192.168.128.47    test-slave-115
kube-proxy-5h2gw                            1/1       NodeLost   1          24d       10.39.0.115       test-slave-115
filebeat-lvk51                              1/1       NodeLost   66         24d       192.168.128.24    test-slave-115

#登录test-slave-115节点，查看有问题的节点kubelet的日志
[root@test-slave-115 ~]# journalctl -f -u kubelet
```
### 节点日志出现ipvs报错
* Kubernetes: 1.18.1
* CentOS: 7.7
* Kernel: 3.10.0-1062
* 问题描述：k8s集群部署完成后，/var/log/messages中出现。在Kubernetest的 [Github issues](https://github.com/kubernetes/kubernetes/issues/89520) 中有讨论。分析的原因为Kubernetes使用的ipvs模块是比较新，而3.10内核中的ipvs模块老旧，缺少新版Kubernetes ipvs所需的依赖
  ```bash
  E0326 15:20:23.159364  1 proxier.go:1950] Failed to list IPVS destinations, error: parseIP Error ip=[10 96 0 10 0 0 0 0 0 0 0 0 0 0 0 0]
  E0326 15:20:23.159388  1 proxier.go:1192] Failed to sync endpoint for service: 10.8.0.10:53/UPD, err: parseIP Error ip=[10 96 0 16 0 0 0 0 0 0 0 0 0 0 0 0]
  E0326 15:20:23.159479  1 proxier.go:1950] Failed to list IPVS destinations, error: parseIP Error ip=[10 96 0 10 0 0 0 0 0 0 0 0 0 0 0 0]
  E0326 15:20:23.159501  1 proxier.go:1192] Failed to sync endpoint for service: 10.8.0.10:53/TCP, err: parseIP Error ip=[10 96 0 16 0 0 0 0 0 0 0 0 0 0 0 0]
  E0326 15:20:23.159595  1 proxier.go:1950] Failed to list IPVS destinations, erro
  ```
* 解决的方法：Kubernetes 集群各个节点的 CentOS 系统内核版本
  ```bash
  ## 载入公钥
  rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
  
  ## 安装 ELRepo 最新版本
  yum install -y https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm
  
  ## 列出可以使用的 kernel 包版本
  yum list available --disablerepo=* --enablerepo=elrepo-kernel
  
  ## 安装指定的 kernel 版本：
  yum install -y kernel-lt-4.4.218-1.el7.elrepo --enablerepo=elrepo-kernel
  
  ## 查看系统可用内核
  cat /boot/grub2/grub.cfg | grep menuentry
  menuentry 'CentOS Linux (3.10.0-1062.el7.x86_64) 7 (Core)' --class centos （略）
  menuentry 'CentOS Linux (4.4.218-1.el7.elrepo.x86_64) 7 (Core)' --class centos ...  （略）
  
  ## 设置开机从新内核启动
  grub2-set-default "CentOS Linux (4.4.218-1.el7.elrepo.x86_64) 7 (Core)"
  
  ## 查看内核启动项
  grub2-editenv list
  saved_entry=CentOS Linux (4.4.218-1.el7.elrepo.x86_64) 7 (Core)
  
  ## 重启系统使内核生效：
  reboot

  ## 启动完成查看内核版本是否更新：
  uname -r
  4.4.218-1.el7.elrepo.x86_64
  ```