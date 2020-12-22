Elasticsearch启动参数优化
## 禁用内存交换
ES官方一般会建议我们关闭内存交换。内存交换是操作系统的概念，简单来讲它提供一种机制，当内存空间不够用时，使用部分磁盘的空间交换到内存中暂用。因为磁盘的访问速度远远不及内存，所以开启这个会降低集群的性能。我们可以通过在elasticsearch.yml文件中增加如下的配置：
```bash
   cat >> /etc/elasticsearch/elasticsearch.yml<<EOF
   bootstrap.memory_lock: true
   EOF

   #使用systemd启动elasticsearch，需要修改elasticsearch启动配置，路径为：/usr/lib/systemd/system/elasticsearch.service，添加以下内容
   LimitMEMLOCK=infinity
```
1
是否锁住内存，避免交换(swapped)带来的性能损失,默认值是: false。设置完成后，需要重启ES。然后我们可以通过以下命令实时查看请求的输出中的 mlockall 值来查看是否成功应用了此设置。

GET _nodes?filter_path=**.mlockall
1
如果看到 mlockall 为 false ，则表示 mlockall 请求已失败。您还将在日志中看到一行包含更多信息的行，内容为“无法锁定 JVM 内存”。

## 参考信息
- [官方文档，配置系统参数](https://www.elastic.co/guide/en/elasticsearch/reference/current/setting-system-settings.html#systemd)