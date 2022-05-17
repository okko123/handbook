## Elasticsearch的节点角色
> 小集群可以不考虑结群节点的角色划分，大规模ES集群建议将Master Node、Data Node和Coordinating Node独立出来，每个节点各司其职。

> Node rolesedit You define a node’s roles by setting node.roles in elasticsearch.yml. If you set node.roles, the node is only assigned the roles you specify. If you don’t set node.roles, the node is assigned the following roles:
---
### 7版本以后，角色的配置方法更新
> 使用node.role配置替换旧版本的node.master/node.data/node.ingest等角色
  - 在elasticsearch.yml中不配置node.role。es会默认给节点分配一下角色。注意每个集群都必须要master/data_content/data_hot三种角色
    - master
    - data
    - data_content
    - data_hot
    - data_warm
    - data_cold
    - data_frozen
    - ingest
    - ml
    - remote_cluster_client
    - transform
- master
  > 主要负责集群中索引的创建、删除以及数据的Rebalance等操作。Master不负责数据的索引和检索，所以负载较轻。当Master节点失联或者挂掉的时候，ES集群会自动从其他Master节点选举出一个Leader。为了防止脑裂，常常设置参数为discovery.zen.minimum_master_nodes=N/2+1，其中N为集群中Master节点的个数。建议集群中Master节点的个数为奇数个，如3个或者5个。

  > 编辑elasticsearch.yaml配置文件，设置一个节点为Master节点的方式如下：
    ```bash
    node.master: true
    node.data: false 
    node.ingest: false 
    search.remote.connect: false
    ```
- data
  > 主要负责集群中数据的索引和检索，一般压力比较大。建议和Master节点分开，避免因为Data Node节点出问题影响到Master节点。

  > 编辑elasticsearch.yaml配置文件，设置一个节点为Data Node节点的方式如下：
    ```bash
    node.master: false
    node.data: true
    node.ingest: false
    search.remote.connect: false
    ```
- data_content
- data_hot
- data_warm
- data_cold
- data_frozen
- ingest
- ml
- remote_cluster_client
- transform
---
- [elasticsearch 7.16 - Node](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-node.html)
- [Elasticsearch（ES）集群中节点的角色](https://www.jianshu.com/p/7c4818dda91a)