## calico命令行使用记录
使用-o wide 获取更多信息
# 获取节点
calicoctl get nodes
# 获取节点的配置信息
calicoctl get node node_name -o yaml > node.yaml
# 获取ip池列表
calicoctl get ippool