MongoDB sharding迁移那些事（一）
张友东（林青）  2016-09-22 4939浏览量

简介： 如果不了解 MongoDB Sharded Cluster 原理，请先阅读 MongoDB Sharded cluster架构原理 关于MongoDB Sharding，你应该知道的 关于 sharding 迁移，会分3个部分来介绍，本文为第一部分 负载均衡及迁移策略 chunk 迁移


如果不了解 MongoDB Sharded Cluster 原理，请先阅读

[MongoDB Sharded cluster架构原理](https://developer.aliyun.com/article/32434)
[关于MongoDB Sharding，你应该知道的](https://developer.aliyun.com/article/60096)
关于 sharding 迁移，会分3个部分来介绍，本文为第一部分

负载均衡及迁移策略
chunk 迁移流程
Balancer 运维管理
为什么要进行 chunk 迁移？
MongoDB sharding 主要有3个场景需要进行 chunk 迁移

场景1
当多个 shard 上 chunk 数量分布不均时，MongoDB 会自动的在 shard 间迁移 chunk，尽可能让各个 shard 上 chunk 数量均匀分布，就是大家经常说到的负载均衡。

场景2
用户调用 removeShard 命令后，被移除 shard 上的 chunk 就需要被迁移到其他的 shard 上，等该 shard 上没有数据后，安全下线。（注意： shard 上没有分片的集合，需要手动的 movePrimary 来迁移，系统不会自动的迁移）。

场景3
MongoDB sharding 支持 shard tag功能，可以对 shard、及shard key range 打标签，系统会自动将对应 range 的数据迁移到拥有相同 tag 的 shard 上。例如

mongos> sh.addShardTag("shard-hz", "hangzhou")
mongos> sh.addShardTag("shard-sh", "shanghai")
mongos> sh.addTagRange("shtest.coll", {x: 1}, {x: 1000}, "hangzhou")
mongos> sh.addTagRange("shtest.coll", {x: 2000}, {x: 5000}, "shanghai")
对2个 shard 添加了标签，对某个集合的shard key range 也添加了标签，这样该集合里 x 值为[1, 1000)的文档都会分布到 shard-hz，而 x 值为[2000, 5000)的文档则会分布到 shard-sh 里。

迁移工作谁来做？
3.2版本里，Mongos 有个后台的 Balancer 任务，该任务不断对针对上述3种场景来判断是否需要迁移 chunk，如果需要，则发送 moveChunk 命令到源 shard 上开始迁移，整个迁移过程比较复杂，将在第二部分进行专门的介绍。

除了上述场景会触发自动 chunk 迁移，MongoDB 也提供了 moveChunk 命令，让用户能主动的触发数据迁移。

Balancer 如何工作？
一个 Sharded Cluster 里可能有很多个 mongos，如果所有的 mongos 的 Balancer 同时去触发迁移，整个集群就乱了，为了不出乱子，同一时刻只能让一个 Balancer 去做负载均衡。

Balancer 在开始负载均衡前，会先抢锁，抢到锁的 Balancer 继续干活，没抢到锁的则继续等待，一段时间后再尝试抢锁。

这里的锁实际上是config server里 config.locks集合下的一个特殊文档，Balancer 使用 findAndModify 命令去更新文档的 state 字段（类似set state=1 if state==0的逻辑），更新成功即为抢锁成功。

抢锁成功后，Balancer 就开始遍历所有分片的集合，针对每个集合，执行下述步骤，看是否需要 进行 chunk 迁移。

Step1: 获取集合对应的 chunk 分布信息
获取 shard 的元信息 (draining代表 shard 是否正在被移除）

shard 名	maxSize	draining	tag	host
shard0	100G	false	tag0	replset0
shard1	100G	false	tag1	replset1
获取集合的 chunk 分布信息

shard 名	chunk 列表
shard0	chunk(min, -100), chunk(-100, 0)
shard1	chunk(0, 100), chunk(100, max)
获取集合对应的 tag 信息

Range	tag
(20, 80)	tag0
Step2： 检查是否需要 chunk 分裂
如果集合没有设置 tag range，这个步骤不需要做任何事情。其主要是检查 TagRange 跟 chunk 是否存在存在交叉，如果有，则以 Range.min（Range 的下限）为分割点，对 chunk 进行 split。例如

上述（20， 80）的 Range的 tag 为『tag0』，跟chunk（0， 100）有交叉的部分，于是就会在20这个点进行分裂，分裂为 chunk(0, 20) 以及 chunk(20, 100)，接下来就可以将 chunk(20, 100)从 shard1 迁移到 shard0，就能满足 tag 分布规则了，这个步骤只是为迁移做准备工作，具体的迁移在 Step4 中完成。

Step3： 迁移 draining shard 上的chunk
当用户 removeShard 将某个 shard 移除时，MongoDB 会将该 shard 标记为 draining 状态， Blancer 在做迁移时，如果发现某个 shard 处于 draining 状态，就会主动将shard 上的chunk 迁移到其他 shard。 Blancer 会挑选拥有最少 chunk 的 shard 作为迁移目标，构建迁移任务。

Step4： 迁移 tag 不匹配的 chunk
Step2 时，已经将 chunk 根据 tag range 边界进行了 split，这时 Balancer 只需要检查哪些 chunk 所属 shard 的 tag 与自身的不匹配，如果不匹配，则构建迁移任务，将 chunk 迁移到 tag 匹配的 shard 上。

Step5： 负载均衡迁移
Balancer 还会基于各个 shard 持有的 chunk 数量来做负载均衡迁移，如果一个集合在2个 shard 里的 chunk 数量相差超过一定阈值，则会触发迁移。 (通过对比持有 chunk 最多和最少的 shard)

集合的 chunk 数量	迁移阈值
< 20	2
< 80	4
>=80	8
迁移阈值如上表所示，意思是当集合的 chunk 数量小于20时，如果2个 shard 间 chunk 数量相差大于或等于2时，就会构建迁移任务，将某个 chunk 从『持有 chunk 最多的 shard』迁移到『持有 chunk 最少的 shard』。

Step5：执行迁移
根据 Step 3~5 里构建出的迁移任务，开始真正的迁移。

值得注意的是，Step3、Step4里的迁移虽然是必须要做的，为了确保系统功能正常运转，但其仍然是由 Balancer 来控制的，如果关闭了 Balancer，就可能导致 removeShard、shard tag 逻辑无法正常工作，所以关闭 Balancer 一定要慎重，Balancer 的运维管理将在第三部分详细介绍。

---
## 参考资料
- [Sharded Cluster Balancer](https://docs.mongodb.com/manual/core/sharding-balancer-administration/)
- [removeShard Command](https://docs.mongodb.com/manual/tutorial/remove-shards-from-cluster/)
- [Manage Shard Tags](https://docs.mongodb.com/manual/tutorial/manage-shard-zone/)