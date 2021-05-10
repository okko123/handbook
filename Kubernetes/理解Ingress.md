## 理解k8s的Ingress

暴露一个http服务的方式
service 是 k8s 暴露http服务的默认方式， 其中 NodePort 类型可以将http 服务暴露在宿主机的端口上，以便外部可以访问。 service模式的结构如下.
service -> label selector -> pods 
31217 -> app1 selector -> app1 1234
31218 -> app2 selector -> app2 3456
31218 -> app2 selector -> app2 4567

模式的优点
结构简单， 容易理解。
模式缺点

一个app 需要占用一个主机端口
端口缺乏管理
L4转发， 无法根据http header 和 path 进行路由转发

Ingress 模式
在service 之前加了一层ingress，结构如下
            ingress -> service -> label selector -> pods
            www.app1.com -> app1-service -> app1 selector -> app1 1234
80   ->     www.app2.com -> app2-service -> app2 selector -> app2 3456
            www.app3.com -> app3-service -> app3 selector ->app3 4567

模式的优点

增加了7层的识别能力，可以根据  http header, path 进行路由转发

模式缺点

复杂度提升

理解Ingress 实现
Ingress 的实现分为两个部分  Ingress Controller  和 Ingress .

Ingress Controller 是流量的入口，是一个实体软件， 一般是Nginx 和 Haproxy 。
Ingress 描述具体的路由规则。

Ingress Controller  会监听 api server上的 /ingresses 资源 并实时生效。
Ingerss 描述了一个或者多个 域名的路由规则，以 ingress 资源的形式存在。
简单说： Ingress 描述路由规则， Ingress Controller 实时实现规则。
设计理念
k8s 有一个贯穿始终的设计理念，即需求和供给的分离。 Ingress Controller和 Ingress 的实现也很好的实践了这一点。 要理解k8s ，时刻记住 需求供给分离的设计理念。
Ingress Controller 注意事项

一个集群中可以有多个 Ingress Controller， 在Ingress 中可以指定使用哪一个Ingress Controller
多个Ingress 规则可能出现竞争
Ingress Controller 本身需要以hostport 或者 service形式暴露出来。 云端可以使用云供应商lb 服务。
Ingress 可以为多个命名空间服务

Ingress Controller 做哪些设置
我们以nginx-ingress 为例. 我们可以设置如下几个全局参数

全局timeout时间
全局gzip 压缩
https 和 http2
全局 请求数量的 limit
vts 实时nginx 状态，可以监控流量

这里只列出了部分， 更多请参考文档 https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/configmap.md
如何设置 Ingress Controller
两种方式 configmap 和 custom template。 custom template 用来设置configmap不能设置的一些高级选项， 通常情况下，使用configmap 已经够用。
使用configmap 需要确保Ingress Controller时，启用了 configmap参数
Ingress 可以做哪些设置
我们以nginx-ingress 为例. 我们可以设置如下几参数

基于http-header  的路由
基于 path 的路由
单个ingress 的 timeout (不影响其他ingress 的 timeout 时间设置)
登录验证
cros
请求速率limit
rewrite 规则
ssl
这里只列出了部分， 更多请参考文档 https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/annotations.md


如何设置 Ingress
Ingress只能通过Annotations 进行设置。并且需要确保　Ingress Controller 启动时， 启用了 Annotations  选项
需求和供给分离的优点

Ingress Controller 放在独立命名空间中， 由管理员来管理。
Ingress 放在各应用的命名空间中， 由应用运维来设置。

如此可以实现权限的隔离， 又可以提供配置能力 。
总结

Ingress Controller 负责实现路由需求， Ingress负责描述路由需求
Ingress Controller 一个集群可以有多个
Ingress Controller 通过Configmap设置， Ingress 通过Annotations设置
Ingress Controller 设置全局规则， Ingress 设置局部规则
Ingress Controller 可为多个命名空间服务。
需求供给分离可以做到权限隔离，又能提供配置能力。


ingress：负载管理路由规则，类似于nginx的conf文件，或者您可以直接理解为系统的hosts文件，其更新添加可以通过yaml文件形式由k8s部署。
ingress controller：负责对外提供入口，简单说就是网关的实现。
k8s设计时，默认不提供具体的ingress controller实现，而是留给第三方集成，市面上常用的第三方网关组件会对k8s进行适配，网关组件通过与kubernetes API交互，能够动态的去感知集群中Ingress规则变化，然后读取规则并按照它自己的模板生成自己的配置规则加载使用；您可以理解为ingress controller是k8s定义的抽象类，而各网关组件是对他的具体实现。
这部分您可以参考这篇详细了解下ingress controller的选型https://www.cnblogs.com/upyun/p/12372107.html
而本文我们采用的是kong网关组件实现。

---
## 参考文档
- [nginx-ingress 文档](https://github.com/kubernetes/ingress-nginx)
- [理解k8s 的 Ingress](https://www.jianshu.com/p/189fab1845c5/)