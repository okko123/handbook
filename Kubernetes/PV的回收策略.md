## PersistentVolume的回收策略
PersistentVolumes 可以有多种回收策略，包括 “Retain”、”Recycle” 和 “Delete”。对于动态配置的 PersistentVolumes 来说，默认回收策略为 “Delete”。这表示当用户删除对应的 PersistentVolumeClaim 时，动态配置的 volume 将被自动删除。如果 volume 包含重要数据时，这种自动行为可能是不合适的。那种情况下，更适合使用 “Retain” 策略。使用 “Retain” 时，如果用户删除 PersistentVolumeClaim，对应的 PersistentVolume 不会被删除。相反，它将变为 Released 状态，表示所有的数据可以被手动恢复。

kubectl get pv
kubectl patch pv <your-pv-name> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'