rocketmq使用记录

删除消费组
./mqadmin deleteSubGroup -c cluster-name -n "192.168.1.1:9876;192.168.1.2:9876" -g groupname

查看消费组情况
./mqadmin  consumerProgress  -g groupname -n "192.168.1.1:9876;192.168.1.2:9876"

rocketmq监控计算
统计producter的offset
sum(rocketmq_producer_offset{cluster="ztadminCluster"}) by (topic)

(sum(rocketmq_producer_offset{cluster="ztadminCluster"}) by (topic) - on(topic)  group_right  sum(rocketmq_consumer_offset{cluster="ztadminCluster"}) by (group,topic)) - ignoring(group) group_left sum (avg_over_time(rocketmq_producer_tps{cluster="ztadminCluster"} [5m])) by (topic)*5*60 > 0