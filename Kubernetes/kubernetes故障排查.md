##kubernetes故障排查
###节点not ready故障排查
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