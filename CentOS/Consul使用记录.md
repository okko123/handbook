## consul使用记录
### 集群状态查看
consul operator raft list-peers

### 查看members状态
consul members list

consul join -wan IP
consul members -wan

consul operator raft list-peers

多数据中心配置
https://segmentfault.com/a/1190000022361099