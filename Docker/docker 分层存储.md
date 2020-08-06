docker 分层存储
graphdriver 类型为 overlay2

查看镜像层组成：docker history image_name:tag
docker history ubuntu:14.04


Docker 镜像层的内容一般在 Docker 根目录的 aufs 路径下，为 /var/lib/docker/overlay2/[uuid]/diff/


https://cloud.tencent.com/developer/article/1413244