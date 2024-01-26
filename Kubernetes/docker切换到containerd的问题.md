## docker 切换到 containerd的问题
- 镜像清理
  > crictl rmi --prune
- 镜像构建
- 语法
- containers的控制台日志清理
  > containerd作为k8s容器运行时的情况下， 容器日志的落盘由kubelet来完成，保存到/var/log/pods/$CONTAINER_NAME目录下，同时在/var/log/containers目录下创建软链接，指向日志文件

  > 方法一：在kubelet参数中指定： --container-log-max-files=5 --container-log-max-size="100Mi" 方法二：在KubeletConfiguration中指定： "containerLogMaxSize": "100Mi", "containerLogMaxFiles": 5,

  > 创建一个软链接/var/log/pods指向数据盘挂载点下的某个目录 在TKE中选择"将容器和镜像存储在数据盘"，会自动创建软链接/var/log/pods