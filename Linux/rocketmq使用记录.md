## rocketmq使用记录
- 首先进入RocketMQ工程，进入/RocketMQ/bin在该目录下有个mqadmin脚本
  - mqadmin下可以查看有哪些命令
    1. 查看具体命令的使用 : sh mqadmin
       > sh mqadmin help 命令名称  

    2. 例如，查看 updateTopic 的使用
       > sh mqadmin help updateTopic
1. 关闭nameserver和所有的broker:
   - 进入到bin下： 
     > sh mqshutdown namesrv

     > sh mqshutdown broker
2. 查看所有消费组group:
   > sh mqadmin consumerProgress -n 192.168.1.23:9876
3. 查看指定消费组下的所有topic数据堆积情况：
   > sh mqadmin consumerProgress -n 192.168.1.23:9876 -g warning-group
4. 查看所有topic :
   > sh mqadmin topicList -n 192.168.1.23:9876
5. 查看topic信息列表详情统计
   > sh mqadmin topicstatus -n 192.168.1.23:9876 -t topicWarning
6. 新增topic
   > sh mqadmin updateTopic –n 192.168.1.23:9876 –c DefaultCluster –t topicWarning
7. 删除topic
   > sh mqadmin deleteTopic –n 192.168.1.23:9876 –c DefaultCluster –t topicWarning
8. 查询集群消息
   > sh mqadmin  clusterList -n 192.168.1.23:9876