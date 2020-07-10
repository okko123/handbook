## docker 构建镜像

### docker 推送镜像到私有harbor中
```bash
#使用http方式登录需要修改/etc/docker/daemon.json的文件（当文件不存在时请手动创建），添加内容："insecure-registries":["ip/domain"] 
docker login domain/ip

docker tag SOURCE_IMAGE[:TAG] 192.168.1.1/jdk/REPOSITORY[:TAG]
docker push 192.168.1.1/jdk/REPOSITORY[:TAG]
```

### docker 删除无效tag
docker rmi docker_images