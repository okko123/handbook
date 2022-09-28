### 使用kong代替traefik出现的问题
- 问题描述：
  1. 重建k8s集群，使用kong代替traefik。
  2. 使用helm部署kong；kong的版本为2.3；启用ingress控制器
  3. k8s中部署了miniapp-gateway的ingress，service；deployment部署，但副本数保持为0。因此ep是没有分配地址
```bash
kubectl get service -n qdm-stage|grep mini
miniapp-gateway-8080                 ClusterIP   172.3.5.143      <none>        8080/TCP            4d
zz-miniapp-gateway-8080              ClusterIP   172.4.82.210     <none>        8080/TCP            4d
zz-miniapp-gateway-debug-9090        NodePort    172.11.233.80    <none>        9090:32710/TCP      4d
 
kubectl get deployment -n qdm-stage|grep mini
zz-miniapp-gateway        0/0     0            0           4d
 
kubectl get ingress -n qdm-stage|grep mini
NAME                           CLASS   HOSTS                             ADDRESS   PORTS   AGE
zz-miniapp-gateway-ingress     kong    miniapp-k8s01-stage.qdama.cn                80      5s
 
kubectl get ep -n qdm-stage|grep mini
NAME                                 ENDPOINTS               AGE
miniapp-gateway-8080                 <none>                  4d
zz-miniapp-gateway-8080              <none>                  4d
zz-miniapp-gateway-debug-9090        <none>                  4d
```
访问miniapp的接口，会出现错误

curl -XPOST -header -data https://miniapp-k8s01-stage.qdama.cn/miniapp/common/wechat/formid/getwechatsessionkey
 
{
    "code": 0,
    "now": 1664247470000,
    "message": "",
    "url": "/miniapp/common/wechat/formid/getwechatsessionkey",
    "data": {
        "message": "failure to get a peer from the ring-balancer"
    },
    "traceid": "59d5e41e996f7000"
}
原因：
由于ep没有地址，因为kong就会报出无法找到对端的错误
解决方法：
方法1：删除ingress配置
方法2：将deployment的副本数据调整为1+，是的ep能分配IP地址