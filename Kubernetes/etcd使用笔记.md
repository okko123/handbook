## etcd使用笔记
- 查询成员
  ```bash
  ETCDCTL_API=3 etcdctl --endpoints 127.0.0.1:2379 \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  member list
  ```
- 删除成员
  ```bash
  ETCDCTL_API=3 etcdctl --endpoints 127.0.0.1:2379 \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  member remove 3f24efb55330441d
  ```
- 增加成员
  ```bash
  ETCDCTL_API=3 etcdctl --endpoints 127.0.0.1:2379 \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  member add cnhqvztpre01 --peer-urls=http://10.111.105.121:2380
  ```
- etcd制作快照
  ```bash
  ETCDCTL_API=3 etcdctl --endpoints 127.0.0.1:2379 snapshot save snapshotdb
  ```