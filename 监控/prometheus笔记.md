### Prometheus删除指定metrics下收集的值
- 前置要求，打开管理API接口
  ```bash
  # promehteus启动时候添加参数
  ./prometheus --web.enable-admin-api

  # kube-Prometheus打开需要修改配置文件
  kubectl edit prometheus -n monitoring k8s

  # 在resource字段下增加，保存退出；触发Prometheus自动重启
  enableAdminAPI: true
  ```
1. 删除指定Metric名称的全部数据
   ```bash
   curl -X POST -g 'http://127.0.0.1:9090/api/v1/admin/tsdb/delete_series?match[]=node_cpu_seconds_total'
   ```
2. 删除指定Metric名称和特定label名称的全部数据
   ```bash
   curl -X POST -g 'http://127.0.0.1:9090/api/v1/admin/tsdb/delete_series?match[]=node_cpu_seconds_total{mode="idle"}'
   curl -X PUT -g 'http://127.0.0.1:9090/api/v1/admin/tsdb/delete_series?match[]=node_cpu_seconds_total{mode="idle"}'
   ```
3. 删除指定时间范围内的Metric数据
   ```bash
   # 这里的开始时间，结束时间为unix 时间戳
   curl -X POST -g 'http://127.0.0.1:9090/api/v1/admin/tsdb/delete_series?start=1578301194&end=1578301194&match[]=node_cpu_seconds_total{mode="idle"}'
   ```
4. 数据清理：数据清理会从磁盘已经被delete_series 接口删除的数据，并清理现有的tombstones。可以在使用delete_series 接口删除数据之后使用它来释放空间
   ```bash
   # 如果清理成功，会返回204
   curl -X POST 'http://127.0.0.1:9090/api/v1/admin/tsdb/clean_tombstones'
   curl -X PUT 'http://127.0.0.1:9090/api/v1/admin/tsdb/clean_tombstones'
   ```
---
### prometheus 数据类型
- histogram
  1. histogram是柱状图，在Prometheus系统中的查询语言中，有三种作用：
     1. 对每个采样点进行统计（并不是一段时间的统计），打到各个桶(bucket)中
     2. 对每个采样点值累计和(sum)
     3. 对采样点的次数累计和(count)
```bash
度量指标名称: [basename]的柱状图, 上面三类的作用度量指标名称
[basename]_bucket{le=“上边界”}, 这个值为小于等于上边界的所有采样点数量
[basename]_sum
[basename]_count
```
- summary
  1. 因为histogram在客户端就是简单的分桶和分桶计数，在prometheus服务端基于这么有限的数据做百分位估算，所以的确不是很准确，summary就是解决百分位准确的问题而来的。summary直接存储了 quantile 数据，而不是根据统计区间计算出来的。
Prometheus的分为数称为quantile，其实叫percentile更准确。百分位数是指小于某个特定数值的采样点达到一定的百分比
     - summary是采样点分位图统计。 它也有三种作用：
       1. 在客户端对于一段时间内（默认是10分钟）的每个采样点进行统计，并形成分位图。（如：正态分布一样，统计低于60分不及格的同学比例，统计低于80分的同学比例，统计低于95分的同学比例）
       2. 统计班上所有同学的总成绩(sum)
       3. 统计班上同学的考试总人数(count)
- 参考信息
  1. [prometheus的summary和histogram指标的简单理解](https://blog.csdn.net/wtan825/article/details/94616813)
---
```bash
process_max_fds	traefik进程最大的fd
process_open_fds	进程打开的fd
process_resident_memory_bytes	进程占用内存
process_start_time_seconds	进程启动时间
process_virtual_memory_bytes	进程占用虚拟内存

traefik_backend_open_connections	traefik后端打开链接
traefik_backend_request_duration_seconds_bucket	traefik后端请求处理时间
traefik_backend_request_duration_seconds_sum	总时间
traefik_backend_request_duration_seconds_count	总请求时间
traefik_backend_requests_total	一个后端处理的总请求数(按status code, protocol, and method划分)

traefik_config_last_reload_failure	traefik上次失败reload的时间
traefik_config_last_reload_success	上次成功reload的时间
traefik_config_reloads_failure_total	失败次数
traefik_config_reloads_total	成功次数

traefik_entrypoint_open_connections	入口点存在打开链接的数量(method and protocol划分)
traefik_entrypoint_request_duration_seconds_bucket	在入口点处理请求花费的时间(status code, protocol, and method.)
traefik_entrypoint_requests_total	一个入口点处理的总请求数(状态码分布)
```