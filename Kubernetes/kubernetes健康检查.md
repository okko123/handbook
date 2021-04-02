## Pod健康检查（LivenessProbe和ReadinessProbe）
- LivenessProbe:用于判断容器是否存活（running状态），如果LivenessProbe探针探测到容器不健康，则kubelet杀掉该容器，并根据容器的重启策略做相应的处理。如果一个容器不包含LivenessProbe探针，则kubelet认为该容器的LivenessProbe探针返回的值永远是“Success”。
- ReadinessProbe：用于判断容器是否启动完成（ready状态），可以接收请求。如果ReadinessProbe探针检测到失败，则Pod的状态被修改。Endpoint Controller将从Service的Endpoint中删除包含该容器所在Pod的Endpoint。

### LivenessProbe三种实现方式： 
1. HTTP GET探针对容器的ip地址（指定端口和路径）执行HTTP GET请求。响应状态码是2xx或3xx则探测成功。
2. TCP套接字探针尝试建立TCP连接，成功建立则成功。
3. Exec探针，在容器内执行任意命令，检测命令的退出状态码，是0则成功，其他失败。

### 配置探测器
- Probe有很多配置字段，可以使用这些字段精确的控制存活和就绪检测的行为：
  - initialDelaySeconds：容器启动后要等待多少秒后存活和就绪探测器才被初始化，默认是 0 秒，最小值是 0。
periodSeconds：执行探测的时间间隔（单位是秒）。默认是 10 秒。最小值是 1。
  - timeoutSeconds：探测的超时后等待多少秒。默认值是 1 秒。最小值是 1。
  - successThreshold：探测器在失败后，被视为成功的最小连续成功数。默认值是 1。 存活探测的这个值必须是 1。最小值是 1。
  - failureThreshold：当探测失败时，Kubernetes 的重试次数。 存活探测情况下的放弃就意味着重新启动容器。 就绪探测情况下的放弃 Pod 会被打上未就绪的标签。默认值是 3。最小值是 1。
- HTTP Probes 可以在 httpGet 上配置额外的字段：
  - host：连接使用的主机名，默认是 Pod 的 IP。也可以在 HTTP 头中设置 “Host” 来代替。
  - scheme ：用于设置连接主机的方式（HTTP 还是 HTTPS）。默认是 HTTP。
  - path：访问 HTTP 服务的路径。
  - httpHeaders：请求中自定义的 HTTP 头。HTTP 头字段允许重复。
  - port：访问容器的端口号或者端口名。如果数字必须在 1 ～ 65535 之间。

- 对于 HTTP 探测，kubelet 发送一个 HTTP 请求到指定的路径和端口来执行检测。 除非 httpGet 中的 host 字段设置了，否则 kubelet 默认是给 Pod 的 IP 地址发送探测。 如果 scheme 字段设置为了 HTTPS，kubelet 会跳过证书验证发送 HTTPS 请求。 大多数情况下，不需要设置host 字段。 这里有个需要设置 host 字段的场景，假设容器监听 127.0.0.1，并且 Pod 的 hostNetwork 字段设置为了 true。那么 httpGet 中的 host 字段应该设置为 127.0.0.1。 可能更常见的情况是如果 Pod 依赖虚拟主机，你不应该设置 host 字段，而是应该在 httpHeaders 中设置 Host。
- 对于一次 TCP 探测，kubelet 在节点上（不是在 Pod 里面）建立探测连接， 这意味着你不能在 host 参数上配置服务名称，因为 kubelet 不能解析服务名称。
---
## 参考连接
[配置存活、就绪和启动探测器](https://v1-18.docs.kubernetes.io/zh/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-readiness-probes)
[Pod 的生命周期](https://v1-18.docs.kubernetes.io/zh/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-readiness-probes)