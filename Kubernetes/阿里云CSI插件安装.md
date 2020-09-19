## 阿里云CSI插件安装
- CSI插件的版本为1.0.7，[GitHub地址](https://github.com/kubernetes-sigs/alibaba-cloud-csi-driver)
- k8s集群的版本为：1.18.3

```bash
wget https://github.com/kubernetes-sigs/alibaba-cloud-csi-driver/archive/v1.0.7.tar.gz
tar xf v1.0.7.tar.gz
cd alibaba-cloud-csi-driver-1.0.7

# 添加新的rbac授权
kubectl apply -f deploy/rbac.yaml

## 云盘的插件安装
## 1. 注意k8s 在1.16中把DaemonSet、StatefulSet、Deployment的apiversion由apps/v1beta2修改为apps/v1，因此需要修改yaml的配置
## 2. daemonset的配置中需要指定spec.selector，需要手动补充信息在disk-provisioner.yaml
kubectl create -f ./deploy/disk/disk-plugin.yaml
kubectl create -f ./deploy/disk/disk-provisioner.yaml

# 检查
kubectl get sc
kubectl get CSIDriver

# 安装nas的插件安装
kubectl apply -f ./deploy/nas/

## 创建nas的StorageClass
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

## 创建pvc
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

## 启动nginx容器挂载
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

kubectl -f nginx-1.yaml -f pvc.yaml -f alicloud-nas-subpath.yaml
```
## 参考信息
- [阿里云Kubernetes CSI实践 - 部署详解](https://developer.aliyun.com/article/708649)
- [阿里云 CSI 插件介绍](https://developer.aliyun.com/article/745953)
- [云盘CSI插件安装-GitHub](https://github.com/kubernetes-sigs/alibaba-cloud-csi-driver/blob/master/docs/disk.md)
- [存储管理-CSI](https://help.aliyun.com/document_detail/134722.html?spm=a2c4g.11186623.6.793.71ac20dbkNyvCx)
