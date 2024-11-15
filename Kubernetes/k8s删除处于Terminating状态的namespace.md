## k8s中删除处于Terminating状态的namespace
> 每当删除 namespace 或 pod 等一些 Kubernetes 资源时，有时资源状态会卡在 Terminating，很长时间无法删除，甚至有时增加 --force grace-period=0 之后还是无法正常删除。这时就需要 edit 该资源，或者将该资源导出为 json（通过调用原生接口进行删除）, 将 finalizers 字段设置为 []，之后 Kubernetes 资源就正常删除了。

> 查看 ns 状态
```bash
# kubectl get ns
NAME              STATUS        AGE
default           Active        48d
kube-node-lease   Active        48d
kube-public       Active        48d
kube-system       Active        48d
monitoring        Terminating   61m
```
> 可以看到 monitoring 这个 namespace 一直处于Terminating状态，一般情况下强删是删不掉的，强删的方法如下：

  1. kubectl delete ns monitoring --force --grace-period=0；如果删不掉，就参考下面的方法
  2. 获取 namespace 的 json 文件
     ```bash
     # 查看monitoring.json的内容
     kubectl get ns monitoring -o json > /tmp/monitoring.json
     {
         "apiVersion": "v1",
         "kind": "Namespace",
         "metadata": {
             "annotations": {
                 "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Namespace\",\"metadata\":{\"annotations\":{},\"name\":\"monitoring\"}}\n"
             },
             "creationTimestamp": "2020-05-26T06:29:13Z",
             "deletionTimestamp": "2020-05-26T07:16:09Z",
             "name": "monitoring",
             "resourceVersion": "6710357",
             "selfLink": "/api/v1/namespaces/monitoring",
             "uid": "db09b70a-6198-443b-8ad7-5287b2483a08"
         },
         "spec": {
             "finalizers": [
                 "kubernetes"
             ]
         },
         "status": {
             "phase": "Terminating"
         }
     }

     # 修改此monitoring.json文件内容为：
     {
         "apiVersion": "v1",
         "kind": "Namespace",
         "metadata": {
             "annotations": {
                 "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Namespace\",\"metadata\":{\"annotations\":{},\"name\":\"monitoring\"}}\n"
             },
             "creationTimestamp": "2020-05-26T06:29:13Z",
             "deletionTimestamp": "2020-05-26T07:16:09Z",
             "name": "monitoring",
             "resourceVersion": "6710357",
             "selfLink": "/api/v1/namespaces/monitoring",
             "uid": "db09b70a-6198-443b-8ad7-5287b2483a08"
         },
         "spec": {
         },
         "status": {
             "phase": "Terminating"
         }
     }

     # 调用 api-server 接口进行删除；打开一个新的终端，或者把下面的命令放到后台执行
     kubectl proxy

     # 调用接口删除
     curl -k -H "Content-Type: application/json" -X PUT --data-binary @monitoring.json http://127.0.0.1:8001/api/v1/namespaces/monitoring/finalize
     {
       "kind": "Namespace",
       "apiVersion": "v1",
       "metadata": {
         "name": "monitoring",
         "selfLink": "/api/v1/namespaces/monitoring/finalize",
         "uid": "db09b70a-6198-443b-8ad7-5287b2483a08",
         "resourceVersion": "6710357",
         "creationTimestamp": "2020-05-26T06:29:13Z",
         "deletionTimestamp": "2020-05-26T07:16:09Z",
         "annotations": {
           "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Namespace\",\"metadata\":{\"annotations\":{},\"name\":\"monitoring\"}}\n"
         }
       },
       "spec": {
       },
       "status": {
         "phase": "Terminating"
       }
     }
     # 输出以上内容表示删除成功。
     ```
  3. 注: 如果kubectl get ns monitoring -o json的结果中"spec": {}中为空，则需要看下metadata部分是否有finalizers字段，如下以cattle-system所示：
```bash
{
    "apiVersion": "v1",
    "kind": "Namespace",
    "metadata": {
        "annotations": {
            "cattle.io/status": "{\"Conditions\":[{\"Type\":\"ResourceQuotaInit\",\"Status\":\"True\",\"Message\":\"\",\"LastUpdateTime\":\"2020-10-22T11:22:02Z\"},{\"Type\":\"InitialRolesPopulated\",\"Status\":\"True\",\"Message\":\"\",\"LastUpdateTime\":\"2020-10-22T11:22:07Z\"}]}",
            "field.cattle.io/projectId": "local:p-wfknh",
            "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Namespace\",\"metadata\":{\"annotations\":{},\"name\":\"cattle-system\"}}\n",
            "lifecycle.cattle.io/create.namespace-auth": "true"
        },
        "creationTimestamp": "2020-10-22T11:20:30Z",
        "deletionGracePeriodSeconds": 0,
        "deletionTimestamp": "2020-10-22T11:37:20Z",
        "finalizers": [
            "controller.cattle.io/namespace-auth"
        ],
        "labels": {
            "field.cattle.io/projectId": "p-wfknh"
        },
        "name": "cattle-system",
        "resourceVersion": "165368",
        "selfLink": "/api/v1/namespaces/cattle-system",
        "uid": "223ad163-507c-4efe-b3a3-d3bc4b7a5211"
    },
    "spec": {},
    "status": {
        "phase": "Terminating"
    }
}
```
  4. 这里"spec": {},结果为空，无论我们怎么执行，此时此 ns 都不会被删除，此时想弄清楚这个问题，需要先了解下finalizers这个的含义:
     > Finalizers 字段属于 Kubernetes GC 垃圾收集器，是一种删除拦截机制，能够让控制器实现异步的删除前（Pre-delete）回调。其存在于任何一个资源对象的 Meta 中，在 k8s 源码中声明为 []string，该 Slice 的内容为需要执行的拦截器名称。 对带有 Finalizer 的对象的第一个删除请求会为其 metadata.deletionTimestamp 设置一个值，但不会真的删除对象。一旦此值被设置，finalizers 列表中的值就只能被移除。 当 metadata.deletionTimestamp 字段被设置时，负责监测该对象的各个控制器会通过轮询对该对象的更新请求来执行它们所要处理的所有 Finalizer。 当所有 Finalizer 都被执行过，资源被删除。 metadata.deletionGracePeriodSeconds 的取值控制对更新的轮询周期。 每个控制器要负责将其 Finalizer 从列表中去除。 每执行完一个就从 finalizers 中移除一个，直到 finalizers 为空，之后其宿主资源才会被真正的删除。 看到这里有 finalizers 时，需要把下面的两行一并删除，方法如下：
     ```bash
     kubectl edit ns cattle-system
     进去后，直接删除即可，保存退出后，处于Terminating状态的ns便没有了。
     ```
- rancher的namespace无法删除
  > 由于不能从metrics获取数据，导致namespace的资源无法被清理。通过手动删除指定api服务后，完成rancher的namespace清理工作
    ```bash
    kubectl delete -n cattle-system MutatingWebhookConfiguration rancher.cattle.io
    kubectl delete validatingwebhookconfigurations rancher.cattle.io 

    kubectl get apiservice
    kubectl delete apiservice v1beta1.metrics.k8s.io
    ```
---
## 参考连接
- [k8s中删除处于Terminating状态的namespace](https://zhuanlan.zhihu.com/p/267924292?utm_source=wechat_session)
- [k8s ns 一直terminating，无法删除](https://blog.csdn.net/weixin_40161254/article/details/112267509)
- [k8s删除Terminating状态的命名空间](https://www.jianshu.com/p/76a3a28af07c)
- [k8s无法删除namespace](https://www.xswsym.online/pages/b0f6fd/#%E6%9F%A5%E7%9C%8Bnamespace)