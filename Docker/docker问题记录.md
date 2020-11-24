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

## 查看docker空间占用
docker system df -v

[参考链接-1](https://stackoverflow.com/questions/39078715/specify-max-log-json-file-size-in-docker-compose)
[参考链接-2](https://colobu.com/2018/10/22/no-space-left-on-device-for-docker/)
[参考链接-3](https://success.docker.com/article/no-space-left-on-device-error)
[参考链接-4](https://ashub.cn/articles/42)
[Docker磁盘占用与清理问题](https://www.jianshu.com/p/470e29801be2)