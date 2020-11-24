## 阿里云CSI插件安装
- CSI插件的版本为1.0.7，[GitHub地址](https://github.com/kubernetes-sigs/alibaba-cloud-csi-driver)
- k8s集群的版本为：1.18.3
### 安装过程
1. 下载包，并添加rbac授权
   ```bash
   wget https://github.com/kubernetes-sigs/alibaba-cloud-csi-driver/archive/v1.0.7.tar.gz
   tar xf v1.0.7.tar.gz
   cd alibaba-cloud-csi-driver-1.0.7
   
   # 添加新的rbac授权
   kubectl apply -f deploy/rbac.yaml
   ```
2. 安装云盘、nas插件
   - 注意k8s 1.16以后的版本，将DaemonSet、StatefulSet、Deployment的apiversion: apps/v1beat2的版本移除，需要将apiversion由apps/v1beta2修改为apps/v1，因此需要修改yaml的配置
   - daemonset的配置中需要指定spec.selector，需要手动补充信息在disk-provisioner.yaml
   - 如果修改了kubelet的工作目录，需要修改xxx-plugin.yaml；例如kubelete的工作目录为:/data/kubelet，需要执行sed -i 's|/var/lib/kubelet|/data/kubelet|g' xxx-plugin.yaml。否则安装完毕后，csi插件提示driver not found的问题
   - 需要在xxx-plugin.yaml、xxx-provisioner.yaml配置AK / SK 或者使用ram角色，然后将角色配置到ecs上
   ```bash
   # 安装云盘的插件安装
   kubectl create -f ./deploy/disk/disk-plugin.yaml
   kubectl create -f ./deploy/disk/disk-provisioner.yaml
   
   # 安装nas的插件安装
   kubectl apply -f ./deploy/nas/
   
   # 检查
   kubectl get pods -n kube-system|grep -i csi
   kubectl get CSIDriver
   ```
3. 使用云盘静态存储卷，云盘静态存储卷挂载需要的权限：
   - AttachDisk
   - DetachDisk
   - DescribeDisks
   ```bash
   # 使用模板创建静态卷 PV 和 PVC
   # driver：定义驱动类型。取值为diskplugin.csi.alibabacloud.com，表示使用阿里云云盘 CSI 插件。
   # volumeHandle：定义云盘 ID。

   cat > pvc.yaml <<EOF
   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata:
     name: csi-pvc
   spec:
     accessModes:
     - ReadWriteOnce
     resources:
       requests:
         storage: 25Gi
     selector:
       matchLabels:
         alicloud-pvname: static-disk-pv
   ---
   apiVersion: v1
   kind: PersistentVolume
   metadata:
     name: csi-pv
     labels:
       alicloud-pvname: static-disk-pv
   spec:
     capacity:
       storage: 25Gi
     accessModes:
       - ReadWriteOnce
     persistentVolumeReclaimPolicy: Retain
     csi:
       driver: diskplugin.csi.alibabacloud.com
       volumeHandle: d-wz92s6d95go6ki9xge6b
   EOF

   kubectl apply -f pvc.yaml

   # 创建应用挂载卷
   cat > nginx-disk-dept.yaml <<EOF
   apiVersion: apps/v1
   kind: StatefulSet
   metadata:
     name: web
   spec:
     selector:
       matchLabels:
         app: nginx
     serviceName: "nginx"
     template:
       metadata:
         labels:
           app: nginx
       spec:
         containers:
         - name: nginx
           image: nginx
           ports:
           - containerPort: 80
             name: web
           volumeMounts:
           - name: pvc-disk
             mountPath: /data
         volumes:
           - name: pvc-disk
             persistentVolumeClaim:
               claimName: csi-pvc
   EOF

   kubectl apply -f nginx-disk-dept.yaml
   ```
4. 使用NAS动态存储卷
   1. 创建nas的StorageClass
      ```bash
      cat > alicloud-nas-subpath.yaml <<EOF
      apiVersion: storage.k8s.io/v1
      kind: StorageClass
      metadata:
        name: alicloud-nas-subpath
      mountOptions:
      - nolock,tcp,noresvport
      - vers=3
      parameters:
        volumeAs: subpath
        server: "xxxxxxx.cn-hangzhou.nas.aliyuncs.com:/k8s/"
      provisioner: nasplugin.csi.alibabacloud.com
      reclaimPolicy: Retain
      EOF

      kubectl apply -f alicloud-nas-subpath.yaml
      ```
   2. 创建pvc
      ```bash
      cat > pvc.yaml <<EOF
      kind: PersistentVolumeClaim
      apiVersion: v1
      metadata:
        name: nas-csi-pvc
      spec:
        accessModes:
          - ReadWriteMany
        storageClassName: alicloud-nas-subpath
        resources:
          requests:
            storage: 20Gi
      EOF

      kubectl apply -f pvc.yaml
      ```

   3. 启动nginx容器挂载
      ```bash
      cat > nginx-1.yaml <<EOF
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: deployment-nas-1
        labels:
          app: nginx-1
      spec:
        selector:
          matchLabels:
            app: nginx-1
        template:
          metadata:
            labels:
              app: nginx-1
          spec:
            containers:
            - name: nginx
              image: nginx:1.7.9
              ports:
              - containerPort: 80
              volumeMounts:
                - name: nas-pvc
                  mountPath: "/data"
            volumes:
              - name: nas-pvc
                persistentVolumeClaim:
                  claimName: nas-csi-pvc
      EOF
      
      kubectl apply -f nginx-1.yaml
      ```
## 参考信息
- [阿里云Kubernetes CSI实践 - 部署详解](https://developer.aliyun.com/article/708649)
- [阿里云 CSI 插件介绍](https://developer.aliyun.com/article/745953)
- [云盘CSI插件安装-GitHub](https://github.com/kubernetes-sigs/alibaba-cloud-csi-driver/blob/master/docs/disk.md)
- [存储管理-CSI](https://help.aliyun.com/document_detail/134722.html?spm=a2c4g.11186623.6.793.71ac20dbkNyvCx)
