## deepflow工具使用笔记
1. 安装：使用helm工具进行安装。注意deepflow需要运行在k8s的环境中，且ClickHouse和MySQL需要使用PV保存数据。所以在安装前，确保系统有可用的StorageClass
   - 使用 helm --set global.storageClass 可指定 storageClass
   - 使用 helm --set global.replicas 可指定 deepflow-server 和 clickhouse 的副本数量
   ```bash
   # 安装OpenEBS，提供默认的StorageClass
   kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
   kubectl patch storageclass openebs-hostpath  -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

   # 安装deepflow，注意由于deepflow使用github源，所以会出现偶尔失败的情况
   helm repo add deepflow https://deepflowio.github.io/deepflow
   helm repo update deepflow # use `helm repo update` when helm < 3.7.0
   helm install deepflow -n deepflow deepflow/deepflow --create-namespace
   ```
2. 监控多个K8S集群
   ```bash
   # 使用deepflow-ctl工具获取server端的IP；deepflow-ctl工具需要单独下载。在server端执行：
   deepflow-ctl domain list
   NAME             ID           LCUUID                                TYPE              CONTROLLER_IP   CREATED_AT             SYNCED_AT              ENABLED  STATE      AGENT_WATCH_K8S
   k8s-d-J8Uv7wE0EC d-J8Uv7wE0EC 573695ef-ee06-5853-941f-142cdd8df5cd  kubernetes        1.2.3.4   2023-12-06 22:14:16    2023-12-07 11:54:02    ENABLE   NORMAL     host-V3

   # 在被监控的K8S集群上执行
   cat << EOF > values-custom.yaml
   deepflowServerNodeIPS:
   - 1.2.3.4  # FIXME: K8s Node IPs
   clusterNAME: k8s-1  # FIXME: name of the cluster in deepflow
   EOF

   helm repo add deepflow https://deepflowio.github.io/deepflow
   helm repo update deepflow # use `helm repo update` when helm < 3.7.0
   helm install deepflow-agent \
     -n deepflow \
     --create-namespace \
     -f values-custom.yaml \
     deepflow/deepflow-agent
   ```