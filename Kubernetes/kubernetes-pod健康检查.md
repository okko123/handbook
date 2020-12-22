## pod健康检查（LivenessProbe和ReadinessProbe）
- LivenessProbe:用于判断容器是否存活（running状态），如果LivenessProbe探针探测到容器不健康，则kubelet杀掉该容器，并根据容器的重启策略做相应的处理。如果一个容器不包含LivenessProbe探针，则kubelet认为该容器的LivenessProbe探针返回的值永远是“Success”。
- ReadinessProbe：用于判断容器是否启动完成（ready状态），可以接收请求。如果ReadinessProbe探针检测到失败，则Pod的状态被修改。Endpoint Controller将从Service的Endpoint中删除包含该容器所在Pod的Endpoint。

### LivenessProbe三种实现方式： 
1. HTTP GET探针对容器的ip地址（指定端口和路径）执行HTTP GET请求。响应状态码是2xx或3xx则探测成功。
2. TCP套接字探针尝试建立TCP连接，成功建立则成功。
3. Exec探针，在容器内执行任意命令，检测命令的退出状态码，是0则成功，其他失败。