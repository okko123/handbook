## Elasticsearch的节点角色
Node rolesedit
You define a node’s roles by setting node.roles in elasticsearch.yml. If you set node.roles, the node is only assigned the roles you specify. If you don’t set node.roles, the node is assigned the following roles:

master
data
data_content
data_hot
data_warm
data_cold
data_frozen
ingest
ml
remote_cluster_client
transform
---
- [elasticsearch 7.16 - Node](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-node.html)