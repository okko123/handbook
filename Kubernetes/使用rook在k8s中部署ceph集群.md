# 使用rook在k8s中部署ceph集群
## 基本信息
- rook ceph: 1.9
- k8s: 1.22
- ceph要求:
  - 裸设备（无分区、无文件系统）
  - 需要安装lvm2软件
  - 裸分区（无文件系统）

### 部署
```bash
git clone --single-branch --branch v1.9.1 https://github.com/rook/rook.git
cd rook/deploy/examples
kubectl create -f crds.yaml -f common.yaml -f operator.yaml
# 如果没有修改cluster.yaml文件，在每一个节点上创建OSD
kubectl create -f cluster.yaml

# 正常启动集群后，应该有如下的Pods
kubectl -n rook-ceph get pod

NAME                                                 READY   STATUS      RESTARTS   AGE
csi-cephfsplugin-2h84n                               3/3     Running     0          16h
csi-cephfsplugin-45258                               3/3     Running     0          16h
csi-cephfsplugin-hdnqv                               3/3     Running     0          16h
csi-cephfsplugin-provisioner-5f75cff447-r2n2d        6/6     Running     0          16h
csi-cephfsplugin-provisioner-5f75cff447-twcms        6/6     Running     0          16h
csi-cephfsplugin-s96vn                               3/3     Running     0          16h
csi-rbdplugin-khwlb                                  3/3     Running     0          16h
csi-rbdplugin-phxnv                                  3/3     Running     0          16h
csi-rbdplugin-provisioner-5fb99f9f75-42bvq           6/6     Running     0          16h
csi-rbdplugin-provisioner-5fb99f9f75-phlb5           6/6     Running     0          16h
csi-rbdplugin-q5xvb                                  3/3     Running     0          16h
csi-rbdplugin-vvlh2                                  3/3     Running     0          16h
rook-ceph-crashcollector-k8s-w-01-cbd864546-rnvcs    1/1     Running     0          16h
rook-ceph-crashcollector-k8s-w-02-7cf6847b69-fj7jn   1/1     Running     0          16h
rook-ceph-crashcollector-k8s-w-03-78f459cd64-s9bqr   1/1     Running     0          16h
rook-ceph-crashcollector-k8s-w-04-7584c77fbc-2nd9w   1/1     Running     0          16h
rook-ceph-mgr-a-d559d5d7b-fdz79                      2/2     Running     0          16h
rook-ceph-mgr-b-64c4c99f7d-wcmbl                     2/2     Running     0          16h
rook-ceph-mon-a-7574dff7c8-v2b4t                     1/1     Running     0          16h
rook-ceph-mon-b-645c9ff954-fmcjt                     1/1     Running     0          16h
rook-ceph-mon-c-5549c7d97-xcdhx                      1/1     Running     0          16h
rook-ceph-operator-5d4845db5f-fcfb9                  1/1     Running     0          16h
rook-ceph-osd-0-5b9c67db8f-7lntp                     1/1     Running     0          16h
rook-ceph-osd-1-5c5965f4cc-kswdd                     1/1     Running     0          16h
rook-ceph-osd-2-6458f7574d-g474d                     1/1     Running     0          16h
rook-ceph-osd-3-7bfcb49bd-ksjdq                      1/1     Running     0          16h
rook-ceph-osd-prepare-k8s-w-01--1-8rbpr              0/1     Completed   0          16h
rook-ceph-osd-prepare-k8s-w-02--1-bvg7j              0/1     Completed   0          16h
rook-ceph-osd-prepare-k8s-w-03--1-dtjmg              0/1     Completed   0          16h
rook-ceph-osd-prepare-k8s-w-04--1-kz6nf              0/1     Completed   0          16h
rook-ceph-tools-86dbcb7664-6nmdv                     1/1     Running     0          16h

# 验证集群的健康状态，使用Rook toolbox
kubectl create -f deploy/examples/toolbox.yaml

# 等待toolbox容器正常运行后
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- bash

# 执行以下命令，检查ceph的集群健康信息
ceph status
ceph osd status
ceph df
rados df
```

### 清理ceph部署
```bash
kubectl delete -f operator.yaml -f cluster.yaml

# 每个节点上删除此目录，里面缓存ceph的mons 和 osds信息
rm -rf /var/lib/rook
```

# 删除块存储和文件存储
kubectl delete -f ../wordpress.yaml
kubectl delete -f ../mysql.yaml
kubectl delete -n rook-ceph cephblockpool replicapool
kubectl delete storageclass rook-ceph-block
kubectl delete -f csi/cephfs/kube-registry.yaml
kubectl delete storageclass csi-cephfs
---
## 参考信息
- [Ceph Quickstart](https://rook.io/docs/rook/v1.9/quickstart.html)
- [Rook Toolbox](https://rook.io/docs/rook/v1.9/ceph-toolbox.html)
- [Cleaning up a Cluster](https://rook.io/docs/rook/v1.9/ceph-teardown.html)