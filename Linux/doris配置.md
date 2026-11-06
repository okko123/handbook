### FE配置
- max_routine_load_task_num_per_be
  - 默认值：5；是否可以动态配置：true；是否为 Master FE 节点独有的配置项：true；每个 BE 的最大并发例 Routine Load 任务数。这是为了限制发送到 BE 的 Routine Load 任务的数量，并且它也应该小于 BE config routine_load_thread_pool_size（默认 10），这是 BE 上的 Routine Load 任务线程池大小。

- max_routine_load_task_concurrent_num
  - 默认值：5；是否可以动态配置：true；是否为 Master FE 节点独有的配置项：true；单个 Routine Load 作业的最大并发任务数

- max_routine_load_job_num
  - 默认值：100；最大 Routine Load 作业数，包括 NEED_SCHEDULED, RUNNING, PAUSE


### BE配置
- routine_load_thread_pool_size
  - 默认值：10；参数描述：routine load 任务的线程池大小。这应该大于 FE 配置 'max_concurrent_task_num_per_be'

### routine load导入操作
- desired_concurrent_number
  - 默认值：5；参数描述：单个导入子任务（load task）期望的并发度，修改 Routine Load 导入作业切分的期望导入子任务数量。在导入过程中，期望的子任务并发度可能不等于实际并发度。实际的并发度会根据集群的节点数、负载情况，以及数据源的情况综合考虑，使用公式以下可以计算出实际的导入子任务数：min(topic_partition_num, desired_concurrent_number, max_routine_load_task_concurrent_num)，其中：
    - topic_partition_num 表示 Kafka Topic 的 parititon 数量
    - desired_concurrent_number 表示设置的参数大小
    - max_routine_load_task_concurrent_num 为 FE 中设置 Routine Load 最大任务并行度的参数

### 在FE的日志中查找慢日志
- 在 Doris 的 FE 节点中查找慢日志，主要通过审计日志文件 fe.audit.log 来实现。这个文件会记录所有执行过的 SQL，并将执行时间超过阈值的查询标记为 slow_query。在fe.audit.log 中，执行较慢的查询会带有一个特殊的 slow_query 标签。 使用 grep 命令即可快速过滤出所有慢查询记录：
```bash
# 打印第11个字段，按 = 取第二个值，如歌这个值大于1000，就打印整行完整内容
tail -n1000 123.log | awk -F '|' '{
    split($11, a, "=");
    if (a[2]+0 > 1000) print $0
}' | more
```
### 创建用户
```bash
# 需要先创建
CREATE USER 'jack'@['example_domain'] IDENTIFIED BY '12345';
GRANT SELECT_PRIV,ALTER_PRIV,LOAD_PRIV ON ctl1.db1.tbl1  TO 'jack'@'192.8.%';
```

```bash
grep "slow_query" /path/to/fe.audit.log

# 一个典型的慢查询日志条目会包含以下关键信息，例如：
2024-07-18 11:23:13,042 [slow_query] |Client=127.0.0.1|User=root|Time(ms)=11603|ScanBytes=...|Stmt=select ...|CpuTimeMS=918556|...
📋 理解关键字段
找到慢查询日志后，理解这些字段的含义可以帮助你快速定位问题：

字段名 (示例)	含义	用途
Time(ms)	查询总执行时间（毫秒）	判断是否真的是慢查询，超过阈值（默认5秒）会被标记
ScanBytes / ScanRows	扫描的数据量和行数	判断是否存在全表扫描或大量数据扫描，这是性能瓶颈的常见原因
Stmt	具体的 SQL 语句	复现和优化问题的关键，可以直接拿这个 SQL 去分析
QueryId	查询的唯一 ID	可以通过这个 ID 在 fe.log 或其他诊断工具中关联更详细的执行信息（Profile）
CpuTimeMS	SQL 消耗的 CPU 时间	帮助区分是计算密集型（CPU高） 还是 IO密集型（扫描数据多） 的查询
peakMemoryBytes	查询过程中使用的最大内存	用于排查内存超限或OOM问题
```

- 如何调整慢查询阈值
  > 如果默认的5秒阈值（qe_slow_log_ms）不符合你的需求，可以在 FE 的配置文件 fe.conf 中修改。修改后需要重启 FE 节点才能生效。
  ```bash
  # 将慢查询阈值修改为1秒
  qe_slow_log_ms = 1000
  
  # 进阶方式：使用系统表进行分析
  如果你使用的是 Doris 2.1 或更高版本，还可以通过查询内置的 audit_log 系统表进行更灵活的慢查询分析，无需直接操作日志文件。
  
  首先，你需要在 Doris 中开启审计日志表功能（如果未开启），可能需要设置 enable_audit_log_table = true 并重启 FE。开启后，可以通过 SQL 进行分析：
  
  # sql
  -- 查询最近1小时内执行时间超过3秒的慢查询
  SELECT * FROM __internal_schema.audit_log 
  WHERE query_time > 3000 
    AND time >= NOW() - INTERVAL 1 HOUR
  ORDER BY query_time DESC;
  ```
