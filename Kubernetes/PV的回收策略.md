# PV PVC卷使用
## PersistentVolume的回收策略
PersistentVolumes 可以有多种回收策略，包括 “Retain”、”Recycle” 和 “Delete”。对于动态配置的 PersistentVolumes 来说，默认回收策略为 “Delete”。这表示当用户删除对应的 PersistentVolumeClaim 时，动态配置的 volume 将被自动删除。如果 volume 包含重要数据时，这种自动行为可能是不合适的。那种情况下，更适合使用 “Retain” 策略。使用 “Retain” 时，如果用户删除 PersistentVolumeClaim，对应的 PersistentVolume 不会被删除。相反，它将变为 Released 状态，表示所有的数据可以被手动恢复。
* 修改pv卷的回收模式
  ```bash
  kubectl patch pv <your-pv-name> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}
  ```

## 访问模式，只有NFS（AWS的EFS也支持，使用efs-provider）、CephFS、AzureFile支持ReadWriteMany的访问模式
* ReadWriteOnce – the volume can be mounted as read-write by a single node
* ReadOnlyMany – the volume can be mounted read-only by many nodes
* ReadWriteMany – the volume can be mounted as read-write by many nodes
* [Types of Persistent Volumes(PV支持的类型)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)'

## 本例为单节点的K8S，使用hostpath方式提供pv
1. 创建pv的yaml
   ```bash
   cat > /tmp/pv-volume.yaml <<EOF
   apiVersion: v1
   kind: PersistentVolume
   metadata:
     name: task-pv-volume
     labels:
       type: local
   spec:
     storageClassName: manual
     persistentVolumeReclaimPolicy: Retain
     capacity:
       storage: 10Gi
     accessModes:
       - ReadWriteOnce
     hostPath:
       path: "/mnt/data"
   EOF
   
   kubectl apply -f /tmp/pv-volume.yaml
   
   #检查PV是否正常建立
   kubectl get pv task-pv-volume

   NAME             CAPACITY   ACCESSMODES   RECLAIMPOLICY   STATUS      CLAIM     STORAGECLASS   REASON    AGE
   task-pv-volume   10Gi       RWO           Retain          Available             manual                   4s
   ```
2. 创建PVC，显式声明关联的PV。
   ```bash
   cat > /tmp/pvc-volume.yaml <<EOF
   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata:
     name: task-pv-claim
     namespace: test
   spec:
     volumeMode: Filesystem
     volumeName: task-pv-volume
     storageClassName: manual
     accessModes:
       - ReadWriteOnce
     resources:
       requests:
         storage: 3Gi
   EOF

   kubectl apply -f /tmp/pvc-volume.yaml
   ```
3. 创建pod，挂载pvc
   ```bash
   cat > /tmp/pod.yaml<<EOF
   apiVersion: v1
   kind: Pod
   metadata:
     name: task-pv-pod
     namespace: test
   spec:
     volumes:
       - name: task-pv-storage
         persistentVolumeClaim:
           claimName: task-pv-claim
     containers:
       - name: task-pv-container
         image: nginx
         ports:
           - containerPort: 80
             name: "http-server"
         volumeMounts:
           - mountPath: "/usr/share/nginx/html"
             name: task-pv-storage
   EOF
   
   kubectl apply -f /tmp/pod.yaml
   ```