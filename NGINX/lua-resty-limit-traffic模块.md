## lua-resty-limit-traffic模块
resty.limit.req 限速不是特别准确。

比如按你的设置，期望 qps 到 300 时才开始对请求进行延迟，然而它内部计算时精度是毫秒，
300r/s 它认为是平均 3.333 ms 来一个请求，所以如果你测试的时候某一小段时间内请求十分密集，
比如达到了 1ms 一个请求，那么即使 qps 没到 300，incoming 函数计算出来的 delay 也会是大于 0.001 的。

   excess = max(tonumber(rec.excess) - rate * abs(elapsed) / 1000 + 1000, 0)

这是它的核心公式，rec.excess 是上次计算得到的超过 rate 的请求数（*1000），rate 是用户设置的请求频率（*1000），
elapsed 是距离上次检查至今过去的时间(ms)。

按刚才的例子来看，假设 elapsed 是 1ms，rec.excess 是 0，rate 是 300r/s，那么

excess = max(0 - 300 * 1000 * 1 / 100 + 1000, 0)

此时得到 excess 是 700，所以延迟时间 delay 会是

delay =700 / (300 * 1000)

也就是 7/3000。

[使用OpenResty实现动态限流](https://kuberxy.github.io/%E5%AE%B9%E9%87%8F%E8%A7%84%E5%88%92/2019/12/22/limit-traffic-by-openresty.html)
[OpenResty 动态流控的几种姿势](https://www.upyun.com/opentalk/417.html)
[有关lua-resty-limit-traffic模块](https://forum.openresty.us/d/3699-a739dc8cba48b361d649126bef0add20)