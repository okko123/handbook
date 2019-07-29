## 在监控中发现，mongo分片的读取IO
## 处理过程
- 在其中一个分片的主节点上执行mongostat，query、command、getmore的值都保持在稳定水平
- 在OPS中检查监控，同样没有发现明显波动
- 使用mongo client登陆主节点，执行currentOp，查询执行超过10秒且活动的连接进程
```bash
db.currentOp(
   {
     "active" : true,
     "secs_running" : { "$gt" : 3 },
   }
)
```
- 在返回的结果中，查找opid
```bash
db.killOp(opid)
```

- [博客参考连接](http://www.mongoing.com/archives/2563)
- [官方文档](https://docs.mongodb.com/v3.4/reference/command/currentOp/)
- [博客](https://jacoobwang.github.io/2018/10/26/Mongodb%20currentop%E7%9B%91%E6%8E%A7/)