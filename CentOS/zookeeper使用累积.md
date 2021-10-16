## zookeeper使用累积

### 设置snapshot清理
- 在配置文件中添加
 - autopurge.snapRetainCount：保留最近的快照和相应的事务日志数量，并删除其余的。默认为3，最小值为3
 - autopurge.purgeInterval：触发清理任务的时间间隔，以小时为单位，设置为正整数1及以上，以启用自动清理，默认为0
- 使用zookeeper自带脚本清理
  - bash zkCleanup.sh  /data/zookeeper -n 3000 
### 参考信息
[zookeeperAdmin](https://zookeeper.apache.org/doc/r3.6.1/zookeeperAdmin.html)