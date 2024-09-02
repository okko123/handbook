### elasticsearch 时区问题
> 在ES内部默认使用UTC时间并且是以毫秒时间戳的long型存储。针对日期字段的查询其实是对long型时间戳的范围查询

> 解决方案是你存储的时间字符串本身就带有时区信息

---
- [ES系列之一文带你避开日期类型存在的坑](https://blog.csdn.net/pony_maggie/article/details/104957681)