## ceph-csi 插件安装
- 环境信息
  - 系统环境: ubuntu-20.04.3
  - k8s环境: 1.22.8
  - ceph环境: 15.2.16
  - ceph-csi: 3.4.0

### 部署
1. 获取ceph的信息。这里只需要使用fsid、monitor的ip地址
   - fsid : 这个是 Ceph 的集群 ID。
   - 监控节点信息。目前 ceph-csi 只支持 v1 版本的协议，所以监控节点那里我们只能用 v1 的那个 IP 和端口号（例如，172.16.1.21:6789）。
   ```bash
   # ceph mon dump

   dumped monmap epoch 1
   epoch 1
   fsid a95b4e49-4ed5-42e7-9642-b3d5d8de9d72
   last_changed 2022-05-10T09:11:57.177561+0000
   created 2022-05-10T09:11:57.177561+0000
   min_mon_release 15 (octopus)
   0: v1:172.16.81.151:6789/0 mon.ceph01
   ```
2. 进入 ceph-csi 的 deploy/rbd/kubernetes 目录：
   ```bash
   wget https://github.com/ceph/ceph-csi/archive/refs/tags/v3.4.0.tar.gz
   tar xf v3.4.0.tar.gz
   cd ceph-csi-3.4.0/deploy/rbd/kubernetes

   ls -l ./
   total 48
   -rw-rw-r-- 1 nuc nuc  245 May 12 03:42 csi-config-map.yaml
   -rw-rw-r-- 1 nuc nuc  226 Jul 29  2021 csidriver.yaml
   -rw-rw-r-- 1 nuc nuc 1689 May 12 03:43 csi-nodeplugin-psp.yaml
   -rw-rw-r-- 1 nuc nuc 1022 May 12 03:43 csi-nodeplugin-rbac.yaml
   -rw-rw-r-- 1 nuc nuc 1315 May 12 03:43 csi-provisioner-psp.yaml
   -rw-rw-r-- 1 nuc nuc 3031 May 12 03:43 csi-provisioner-rbac.yaml
   -rw-rw-r-- 1 nuc nuc 7308 May 12 03:45 csi-rbdplugin-provisioner.yaml
   -rw-rw-r-- 1 nuc nuc 6108 May 12 03:46 csi-rbdplugin.yaml
   -rw-rw-r-- 1 nuc nuc  171 May 12 03:43 csi-rbd-secret.yaml
   -rw-rw-r-- 1 nuc nuc  711 May 12 06:37 storageclass.yaml
   ```
3. 将ceph的信息写入csi-config-map.yaml文件中
   ```bash
   cat > csi-config-map.yaml <<EOF
   ---
   apiVersion: v1
   kind: ConfigMap
   data:
     config.json: |-
       [
         {
           "clusterID": "a95b4e49-4ed5-42e7-9642-b3d5d8de9d72",
           "monitors": [
             "172.16.81.151:6789"
           ]
         }
       ]
   metadata:
     name: ceph-csi-config
   EOF

   ## 创建新的namespace用于部署ceph-csi
   kubectl create ns ceph-csi

   ## 导入configmap
   kubectl apply -n ceph-csi -f csi-configmap.yaml
   ```
4. 在ceph创建pool，创建用户，将上述的信息导入到k8s的secret中
   ```bash
   ## 创建一个新的 ceph 存储池（pool） 给 Kubernetes 使用：
   ceph osd pool create kubernetes-ceph

   ## 查看所有的pool
   ceph osd lspools
   1 device_health_metrics
   2 test-k8s
   3 kubernetes-ceph

   ## 新建用户
   ceph auth get-or-create client.kubernetes-user mon 'profile rbd' osd 'profile rbd pool=kubernetes-ceph' mgr 'profile rbd pool=kubernetes-ceph'

   [client.kubernetes-user]
       key = AQBnz11fclrxChAAf8TFw8ROzmr8ifftAHQbTw==

   ## 后面的配置需要用到这里的 key，如果忘了可以通过以下命令来获取：
   ceph auth get client.kubernetes-user

   ## 创建secret
   cat > csi-rbd-secret.yaml <<EOF
   apiVersion: v1
   kind: Secret
   metadata:
     name: csi-rbd-secret
     namespace: ceph-csi
   stringData:
     userID: kubernetes-user
     userKey: AQBnz11fclrxChAAf8TFw8ROzmr8ifftAHQbTw==
   EOF
   kubectl apply -f csi-rbd-secret.yaml
   ```
5. RBAC 授权
   - 将所有配置清单中的 namespace 改成 ceph-csi
     ```bash
     sed -i "s/namespace: default/namespace: ceph-csi/g" $(grep -rl "namespace: default" ./)
     sed -i -e "/^kind: ServiceAccount/{N;N;a\  namespace: ceph-csi  # 输入到这里的时候需要按一下回车键，在下一行继续输入
     }" $(egrep -rl "^kind: ServiceAccount" ./)
     ```
   - 创建必须的 ServiceAccount 和 RBAC ClusterRole/ClusterRoleBinding 资源对象
     ```bash
     kubectl create -f csi-provisioner-rbac.yaml
     kubectl create -f csi-nodeplugin-rbac.yaml
     ```
   - 创建 PodSecurityPolicy
     ```bash
     kubectl create -f csi-provisioner-psp.yaml
     kubectl create -f csi-nodeplugin-psp.yaml
     ```
6. 部署csi provisioner
   ```bash
   ## 将 csi-rbdplugin-provisioner.yaml 和 csi-rbdplugin.yaml 中的 kms 部分配置注释掉

   ## 部署
   kubectl -n ceph-csi create -f csi-rbdplugin-provisioner.yaml
   kubectl -n ceph-csi create -f csi-rbdplugin.yaml
   ```
7. 创建 Storageclass
   - 这里的 clusterID 对应之前步骤中的 fsid
   - imageFeatures 用来确定创建的 image 特征，如果不指定，就会使用 RBD 内核中的特征列表，但 Linux 不一定支持所有特征，所以这里需要限制一下。
   ```bash
   cat > storageclass.yaml <<EOF
   apiVersion: storage.k8s.io/v1
   kind: StorageClass
   metadata:
      name: csi-rbd-sc
   provisioner: rbd.csi.ceph.com
   parameters:
      clusterID: 154c3d17-a9af-4f52-b83e-0fddd5db6e1b
      pool: kubernetes-ceph
      imageFeatures: layering
      csi.storage.k8s.io/provisioner-secret-name: csi-rbd-secret
      csi.storage.k8s.io/provisioner-secret-namespace: ceph-csi
      csi.storage.k8s.io/controller-expand-secret-name: csi-rbd-secret
      csi.storage.k8s.io/controller-expand-secret-namespace: ceph-csi
      csi.storage.k8s.io/node-stage-secret-name: csi-rbd-secret
      csi.storage.k8s.io/node-stage-secret-namespace: ceph-csi
      csi.storage.k8s.io/fstype: ext4
   reclaimPolicy: Delete
   allowVolumeExpansion: true
   mountOptions:
      - discard
   EOF
   ```
---
### github上的安装教程
> 3.6版本后，需要导入ceph.conf的配置到configmap中（按需修改其中的内容）。进入examples目录
  ```bash
  kubectl apply -f ./ceph-conf.yaml
  ```
> 按需修改csi-config-map-sample.yaml的内容，修改cluster-ID、monitor的IP地址
  ```bash
  kubectl replace -f ./csi-config-map-sample.yaml
  ```
> 进入rbd目录，执行plugin-deploy.sh部署csi组件（创新CRD、role等信息）
  ```bash
  bash plugin-deploy.sh
  ```
> 成功部署插件后，您需要自定义 storageclass.yaml 和 secret.yaml 清单以反映您的 Ceph 集群设置。在配置好 secrets、monitors 等之后，你可以部署一个测试 Pod，挂载一个 RBD 镜像/CephFS 卷。
  ```bash
  kubectl create -f secret.yaml
  kubectl create -f storageclass.yaml
  kubectl create -f pvc.yaml
  kubectl create -f pod.yaml
  ```
---
### 使用ceph-csi插件
> Kubernetes 通过 PersistentVolume 子系统为用户和管理员提供了一组 API，将存储如何供应的细节从其如何被使用中抽象出来，其中 PV（PersistentVolume） 是实际的存储，PVC（PersistentVolumeClaim） 是用户对存储的请求。
- 下面通过官方仓库的示例来演示如何使用 ceph-csi。先进入 ceph-csi 项目的 example/rbd 目录，然后直接创建 PVC：
  ```bash
  cd ~/ceph-csi-3.4.0/examples/rbd/
  kubectl apply -f pvc.yaml

  ## 查看PVC 和申请成功的 PV
  $ kubectl get pvc
  NAME      STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
  rbd-pvc   Bound    pvc-57e46ddd-e65b-4f98-8210-e5ab9b9d292a   1Gi        RWO            csi-rbd-sc     171m

  $ kubectl get pv
  NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM             STORAGECLASS   REASON   AGE
  hpvc-57e46ddd-e65b-4f98-8210-e5ab9b9d292a   1Gi        RWO            Delete           Bound    default/rbd-pvc   csi-rbd-sc              172m

  
  ## 创建示例Pod
  $ kubectl apply -f pod.yaml

  ## 进入 Pod 里面测试读写数据
  $ kubectl exec -it csi-rbd-demo-pod bash
  root@csi-rbd-demo-pod:/# cd /var/lib/www/
  root@csi-rbd-demo-pod:/var/lib/www# ls -l
  total 4
  drwxrwxrwx 3 root root 4096 Sep 14 09:09 html
  root@csi-rbd-demo-pod:/var/lib/www# echo "hello world" > hello.txt
  root@csi-rbd-demo-pod:/var/lib/www# cat hello.txt
  hello world
  ```
---
## 参考信息
- [Kubernetes 使用 ceph-csi 消费 RBD 作为持久化存储](https://icloudnative.io/posts/kubernetes-storage-using-ceph-rbd/)
- [How to test RBD and CephFS plugins with Kubernetes 1.14+](https://github.com/ceph/ceph-csi/tree/devel/examples)