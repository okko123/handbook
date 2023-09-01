## docker容器运行日志过大，官方建议处理方法
- 方法1：
```bash
cat /dev/null > /var/lib/docker/containers/container_id/container_log_name
```
- 方法2：
```bash
#修改docker容器的启动参数
docker run -it --log-opt max-size=10m --log-opt max-file=3 alpine ash

#修改docker-compose文件
services:
    service_name:        
        logging:
            driver: "json-file"
            options:
                max-size: "50m"
```

## 清理镜像
docker system prune -a
## 清理docker日志
docker inspect --format='{{.LogPath}}' [容器名/容器ID]
truncate -s 0 /var/lib/containers/1380d936...-json.log

## 查看docker空间占用
docker system df -v
## 容器自动重启
```bash
docker update --restart=onfailure:3 [容器名]
docker run --restart-always
docker update --restart=always [容器ID]
```
## Dockerfile: ENTRYPOINT和CMD的区别
[参考连接-1](https://zhuanlan.zhihu.com/p/30555962)

## docker使用entrypoint执行时报permission denied错误
问题在于用户没有文件的执行权限。解决方法：将sh作为ENTRYPOINT数组的第一个参数
ENTRYPOINT ["sh", "./entrypoint.sh"]
### 中文乱码
使用CentOS8的官方dockers镜像，默认的locale为en_US.UTF-8，java应用输出中文会出现乱码，需要将locale设置为C.UTF-8。在Dockerfile中设置：
```dockerfile
ENV LANG=C.UTF-8
```
---
[参考链接-1](https://stackoverflow.com/questions/39078715/specify-max-log-json-file-size-in-docker-compose)
[参考链接-2](https://colobu.com/2018/10/22/no-space-left-on-device-for-docker/)
[参考链接-3](https://success.docker.com/article/no-space-left-on-device-error)
[参考链接-4](https://ashub.cn/articles/42)
[Docker磁盘占用与清理问题](https://www.jianshu.com/p/470e29801be2)