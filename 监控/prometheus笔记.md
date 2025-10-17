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
### Prometheus 标签relabeling动作
#### 规则
----
> relabeling 规则主要由以下的一些配置属性组成，但对于每种类型的操作，只使用这些字段的一个子集：
- action: 执行relabeling动作，可选值包括:replace、keep、drop、hashmod、labelmap、labeldrop或者labelkeep，默认值为replace。（不同的动作，使用下面的某一部分属性，如果没有配置，那么默认是replace）
- separator: 分隔符，一个字符串，用于在连接源标签 source_labels 时分隔它们，默认为 :
- source_labels: 源标签，使用配置的分隔符串联的标签名称列表，并与提供的正则表达式进行匹配。（要利用源标签钟指定的这些标签去做某一种动作）
- regex: 正则表达式，用于匹配串联的源标签，默认为(.*)，匹配任何源标签
- modules: 模数，串联的源标签哈希值的模，主要用于Prometheus水平分片
- replacement: replacement字符串，写在目标标签上，用于替换relabeling动作，它可以参考由regex捕获的正则表达式捕获组
#### action: replace 设置或替换标签值
---
> Relabeling 的一个常见操作就是设置（生成新的标签）或者覆盖（覆盖旧的标签）一个标签的，我们可以通过 replace 这个操作来完成，如果没有指定action 字段，则默认就是replace

> 一个 replace动作的规则配置方式如下所示
  ```bash
  action: replace
  source_labels: [<source label name list>]    # 要替换的源标签列表
  separator: <source labels separator>         # 默认为 ";" 多个标签, 要将标签连接起来有什么操作符
  regex: <regular expression>                  # 默认为 "(.*)" (匹配任何值))
  replacement: <replacement string>            # 默认为 "$1" (使用第一个捕获组作为 replacement 作为值)
  target_label: <target label>
  ```
> 该操作按顺序执行以下步骤
- 使用提供的 separator 分隔符将 source_labels 中的标签列表值连接起来
- 测试 regex 中的正则表达式是否与上一步连接的字符串匹配，如果不匹配，就跳到下一个 relabeling 规则，不替换任何东西
- 如果正则匹配，就提取正则表达式捕获组中的值，并将 replacement 字符串中对这些组的引用($1, $2, ...)用它们的值替换
- 把经过正则表达式替换的 replacement 字符串作为（$1, $2, ···） target_label 标签的新值存储起来
---
> 下面我们来简单看一看replace操作的示例。
1. 其实很简单，就是原标签是什么（标签源头）
2. 中间通过正则截取，截取之后拼接为新的值（中间处理与转换）
3. 最后得到一个新的标签或者重写标签，值也可以是新的值或者旧的值

> 设置一个固定的标签值，最简单的 replace 例子就是将一个标签设置为一个固定的值，比如你可以把 env 标签设置为 production，这里我们并没有设置规则的大部分属性，这是因为大部分的默认值已经可以满足这里的需求了，这里会将替换的字符串 production 作为 target_label 标签 env 的新值存储起来，也就是将 env 标签的值设置为 production。
```bash
action: replace
replacement: production
target_label: env
```
> 替换抓取任务端口
  - 另一个稍微复杂的示例是重写一个被抓取任务实例的端口，我们可以用一个固定的 80 端口来替换 __address__ 标签的端口
    1. 这里我们替换的源标签为 __address__
    2. 然后通过正则表达式 ([^:]+)(?::\d+)? 进行匹配，这里有两个捕获组，第一个匹配的是 host($1)，第二个匹配的是端口($2)，所以在 replacement 字符串中我们保留第一个捕获组 $1
    3. 然后将端口更改为 80，这样就可以将 __address__ 的实例端口更改为 80 端口
    4. 最后重新写回 __address__ 这个目标标签
    ```bash
    action: replace
    source_labels: [__address__]
    regex: ([^:]+)(?::\d+)? # 第一个捕获组匹配的是 host，第二个匹配的是 port 端口。
    replacement: "$1:80"
    target_label: __address__
    ```

> 总结三种写法: 下面三种常用的写法替换标签值,根据实际灵活使用
1. 直接替换源标签的值
```bash
- target_label: __address__
  replacement: "monitor.example.com:9115" # 修改指向实际的Blackbox exporter
```


2. 源标签生成新的标签
```bash
- source_labels: [__param_target]
  target_label: instance
```

3. 正则表达式来更改并且生成源标签的值
```bash
- action: replace</p>
  source_labels: [__address__]
  regex: ([^:]+)(?::\d+)? # 第一个捕获组匹配的是 host, 第二个匹配的是 port 端口。
  replacement: "$1:80"
  target_label: __address__
```
4. 取源标签的值, 并且生成新的标签, 最后赋值给新的标签
```bash
- source_labels: [__param_target]
  regex: (.*//(.+))
  replacement: $2
  target_label: instance     产生的新的标签, 标签值为正则匹配结果
```
> 标签的作用
- 可以基于已有的标签, 生成一个新标签
- 也可以创建新的标签
- 还可以过滤标签, 不想采集哪些, 或者想采集哪些
- 哪些标签不要了也可以将其删除
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