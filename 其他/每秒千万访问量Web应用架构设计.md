每秒千万访问量Web应用架构设计
几个术语
在进行一切讨论前，有必要先看几个压测工程师经常提到的术语。

RPS
RPS（Requests Per Second）指系统在单位时间内（每秒）处理请求的数量。比如在 100 秒内给一个系统发起 1000 个请求，而这些请求在这 100 秒时间内全部返回了，那么可以认为系统经受住了 1000/100 = 10 RPS 的流量。为了严谨性需要说明一下：这里用 100 秒而不是 1 秒，是考虑到减小时间边界引起的误差（考虑第 1 秒钟和第 100 秒钟的请求以及响应，他们一定概率是不完整的）。

并发度
指在同一个时间点发起的请求数量，比如 12306 统一在下午两点钟放票，100 个人在下午两点钟同时向 12306 发起请求，此时可以认为并发度为 100。

QPS
QPS（Query Per Second） 是指在一定并发度下，服务器每秒可以处理的最大请求数。 QPS 与 RPS 的定义类似，但前者是后者的一个极限值，且前者受到并发度的约束。

为什么说 QPS 要受到并发度的约束呢？可以想象这样两个场景：① 一个系统在 1 个并发的情况下的 QPS 为 100，这就意味着每个请求的响应时间为 1/100 = 0.01 秒。② 一个系统在 10 个并发的情况下 QPS 为 100， 对于每个并发来说，每个请求的响应时间变成了 1/(100/10) = 0.1 秒。从上面可以看出，相同的 QPS 下，并发度不同，响应时间不同，用户的体验自然也不同。

服务器平均请求处理时间 与 用户平均等待时间
服务器平均请求处理时间 = 1/QPS（秒）。如果一个系统的 QPS 为 1000，无论请求是由 1 个并发发起的还是 100 个并发发起的， 均意味着服务器处理一个请求的平均时间为 1/1000 = 0.001 秒。但是在并发度不同时，相同的 QPS 数据用户感受到的响应时间是不同的，这就有了：用户平均等待时间 = 1/(QPS/并发度) = 并发度/QPS（秒）。

上面的简单推导让我想起了小学三年级做的“应用题”，虽然有点绕但是很有意义，大家多咂摸咂摸吧😆。

---
### 参考连接
[漫谈从零访问量到每秒千万访问量的架构设计](https://jingwei.link/2019/01/13/architecture-from-zero-to-millions-req.html)