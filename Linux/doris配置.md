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