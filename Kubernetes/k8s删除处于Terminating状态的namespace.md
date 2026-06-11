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

> 在 Kubernetes 中，像 Rancher 这样的集群管理工具会注册一个全局的 准入 Webhook（Admission Webhook）。它的逻辑是：每当你对集群里的 Namespace 进行增删改查时，K8s 核心 API 都会先强制把请求发给 rancher-webhook 这个服务（Service）进行安全校验，校验通过了才允许执行。
- 现在的核心矛盾是：
  - 你尝试删除（或修改）Namespace。
  - K8s 按照规则去寻找名为 rancher-webhook 的 Service。
  - 结果这个 Service 已经不存在了（not found） 或者所在的整个 cattle-system 命名空间都被删掉了。
  - 由于校验通道断了，K8s 为了安全起见，选择 “一刀切”拒绝所有针对 Namespace 的操作，导致你的 patch 或 delete 命令全部报 InternalError 被弹回。

- 解决方案：打碎拦截器（临时解死锁）
  - 既然这个 Webhook 服务已经没有了，我们就需要直接把 K8s 里的这个“过期的拦截规则”删掉，解除它对集群 Namespace 操作的封锁。
  - 请直接在终端执行以下命令：
    1. 第一步：强制删除卡死的 Namespace Webhook 验证规则
       ```bash
       # 1. 列出并确认 Rancher 相关的 webhook 配置
       kubectl get validatingwebhookconfigurations | grep rancher
       kubectl get mutatingwebhookconfigurations | grep rancher

       # 2. 如果确认这些配置可以被删除，执行删除操作
       kubectl delete validatingwebhookconfigurations <name1> <name2>
       kubectl delete mutatingwebhookconfigurations <name1> <name2>
       ```
    2. 第二步：如果还报类似的错误，可以直接清理掉整个 Rancher 残留的 Webhook 配置：
       ```bash
       kubectl delete validatingwebhookconfigurations.admissionregistration.k8s.io rancher.cattle.io
       kubectl delete validatingwebhookconfigurations.admissionregistration.k8s.io rancher.cattle.io.namespaces
       ```
    3. 第三步：重新执行清理命令；把这个拦路虎删掉之后，K8s 核心 API 就不再尝试去连接那个不存在的 rancher-webhook 服务了。现在你可以重新执行刚刚的 patch 命令，Namespace 就会瞬间被抹去：
       ```bash
       kubectl patch ns cattle-impersonation-system -p '{"metadata":{"finalizers":null}}' --type=merge
       ```
---
## 参考连接
- [k8s中删除处于Terminating状态的namespace](https://zhuanlan.zhihu.com/p/267924292?utm_source=wechat_session)
- [k8s ns 一直terminating，无法删除](https://blog.csdn.net/weixin_40161254/article/details/112267509)
- [k8s删除Terminating状态的命名空间](https://www.jianshu.com/p/76a3a28af07c)
- [k8s无法删除namespace](https://www.xswsym.online/pages/b0f6fd/#%E6%9F%A5%E7%9C%8Bnamespace)