## Elasticsearch mappings使用
- 一般的，mapping则又可以分为动态映射（dynamic mapping）和静态（显式）映射（explicit mapping）和精确（严格）映射（strict mappings），具体由dynamic属性控制。
  - 动态映射；dynamic: true
  - 静态映射；dynamic: false
  - 严格模式；dynamic: strict
- 小结
  - 动态映射（dynamic：true）：动态添加新的字段（或缺省）。
  - 静态映射（dynamic：false）：忽略新的字段。在原有的映射基础上，当有新的字段时，不会主动的添加新的映射关系，只作为查询结果出现在查询中。
  - 严格模式（dynamic： strict）：如果遇到新的字段，就抛出异常。
---
### 参考信息
- [Elasticsearch - mappings之dynamic的三种状态](https://www.cnblogs.com/Neeo/articles/10585035.html#%E4%B8%A5%E6%A0%BC%E6%A8%A1%E5%BC%8Fdynamicstrict)