## Prometheus-operator 监控报错
在Prometheus的告警页面中出现：KubeControllerManagerDown、KubeSchedulerDown；根据ServiceMonitor -> Service -> endpoints(pod) 服务发现机制，查看到KubeControllerManager、KubeScheduler没有对应的svc，所以我们需要创建对应的svc。需要注意，1.18下，kube-controller-manager的labels为component=kube-scheduler，kube-scheduler的labels为component=kube-scheduler
- 检查kube-controller-manager、kube-scheduler的配置文件
  ```bash
  kubectl get servicemonitor kube-controller-manager -n monitoring -o yaml
  # 输出内容：注意检查selector下的matchLabels，service的labes需要与其匹配上，port的名字需要与service的port名对应上
  apiVersion: monitoring.coreos.com/v1
  kind: ServiceMonitor
  metadata:
    annotations:
    labels:
      k8s-app: kube-controller-manager
    name: kube-controller-manager
    namespace: monitoring
  
    省略部分内容

      port: http-metrics
    jobLabel: k8s-app
    namespaceSelector:
      matchNames:
      - kube-system
    selector:
      matchLabels:
        k8s-app: kube-controller-manager
  ```
- 由于kube-controller-manager的http监听端口为10252；kube-scheduler的http监听端口为10251，由于1.18以后，kube-controller-manager、kube-scheduler关闭http端口的监听，使用https端口监听：kube-controller-manager端口10257 kube-scheduler端口10259。因此需要添加https的监听端口
  ```bash
  cat > fix.yaml <<EOF
  kind: Service
  apiVersion: v1
  metadata:
     name: kube-controller-manager
     labels:
       k8s-app: kube-controller-manager
     namespace: kube-system
  spec:
     selector:
       component: kube-controller-manager
     clusterIP: None
     ports:
       - name: http-metrics
         port: 10252
         targetPort: 10252
         protocol: TCP
       - name: https-metrics
         port: 10257
         targetPort: 10257
         protocol: TCP
  ---
  kind: Service
  apiVersion: v1
  metadata:
     name: kube-scheduler
     labels:
       k8s-app: kube-scheduler
     namespace: kube-system
  spec:
     selector:
       component: kube-scheduler
     clusterIP: None
     ports:
       - name: http-metrics
         port: 10251
         targetPort: 10251
         protocol: TCP
       - name: https-metrics
         port: 10259
         targetPort: 10259
         protocol: TCP
  EOF

  kubectl -f apply fix.yaml
  ```
- 由于kube-controller-manager和kube-scheduler默认监听的IP为：127.0.0.1，需要修改kube-controller-manager和kube-scheduler配置，让其绑定到0.0.0.0。配置文件所在目录/etc/kubernetes/manifests。
  1. 修改kube-controller-manager.yaml中--bind-address=0.0.0.0
  2. 修改kube-scheduler.yaml中--bind-address=0.0.0.0
  3. 重启kubelet；systemctl restart kubelet
  4. 测试curl -I -k https://IP:10257/healthz，返回200即为正常

## 参考连接
- [容器云平台No.7~kubernetes监控系统prometheus-operator](https://zhuanlan.zhihu.com/p/258344576)