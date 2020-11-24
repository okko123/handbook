## prometheus 基于文件的服务发现
1. 修改prometheus的配置文件
   ```bash
   cat > /etc/prometheus.yaml <<EOF
   global:
     scrape_interval: 15s
     scrape_timeout: 10s
     evaluation_interval: 15s
   scrape_configs:
   - job_name: 'file_ds'
     file_sd_configs:
     - files:
       - targets.json
   EOF
   ```
2. 通过JSON或者YAML格式的文件，定义所有的监控目标。例如，在下面的JSON文件中分别定义了3个采集任务，以及每个任务对应的Target列表：
   ```bash
   [
     {
       "targets": [ "localhost:8080"],
       "labels": {
         "env": "localhost",
         "job": "cadvisor"
       }
     },
     {
       "targets": [ "localhost:9104" ],
       "labels": {
         "env": "prod",
         "job": "mysqld"
       }
     },
     {
       "targets": [ "localhost:9100"],
       "labels": {
         "env": "prod",
         "job": "node"
       }
     }
   ]
   ```
## Prometheus Operator数据持久化
1. 查看pods的挂载情况，可以看到 Prometheus 的数据目录 /prometheus 实际上是通过 emptyDir 进行挂载的。
   ```yaml
   kubectl get pods prometheus-k8s-0 -n monitoring -o yaml
   ......
       volumeMounts:
       - mountPath: /etc/prometheus/config_out
         name: config-out
         readOnly: true
       - mountPath: /prometheus
         name: prometheus-k8s-db
   ......
     volumes:
   ......
     - emptyDir: {}
       name: prometheus-k8s-db
   ......
   ```
2. 需要通过 storageclass 来做数据持久化，首先创建一个 StorageClass 对象
   ```bash
   cat > sc.yaml <<EOF
   apiVersion: storage.k8s.io/v1
   kind: StorageClass
   metadata:
     name: prometheus-data-db
   provisioner: fuseim.pri/ifs
   EOF

   kubectl apply -f prometheus-storageclass.yaml
   ```
3. 在 prometheus 的 CRD 资源对象中添加如下配置：
   ```bash
   kubectl edit prometheus k8s -n monitoring -o yaml
   storage:
     volumeClaimTemplate:
       spec:
         storageClassName: prometheus-data-db
         resources:
           requests:
             storage: 10Gi
   ```
4. 注意这里的 storageClassName 名字为上面我们创建的 StorageClass 对象名称，然后更新 prometheus 这个 CRD 资源。更新完成后会自动生成两个 PVC 和 PV 资源对象：
   ```bash
   $ kubectl get pvc -n monitoring
   NAME                                 STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS            AGE
   prometheus-k8s-db-prometheus-k8s-0   Bound     pvc-0cc03d41-047a-11e9-a777-525400db4df7   10Gi       RWO            prometheus-data-db      8m
   prometheus-k8s-db-prometheus-k8s-1   Bound     pvc-1938de6b-047b-11e9-a777-525400db4df7   10Gi       RWO            prometheus-data-db      1m

   $ kubectl get pv
   NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                                           STORAGECLASS         REASON    AGE
   pvc-0cc03d41-047a-11e9-a777-525400db4df7   10Gi       RWO            Delete           Bound       monitoring/prometheus-k8s-db-prometheus-k8s-0   prometheus-data-db             2m
   pvc-1938de6b-047b-11e9-a777-525400db4df7   10Gi       RWO            Delete           Bound       monitoring/prometheus-k8s-db-prometheus-k8s-1   prometheus-data-db             1m
   ```

## 参考信息
- [Prometheus Operator 高级配置](https://www.qikqiak.com/post/prometheus-operator-advance/)
- [基于文件的服务发现](https://yunlzheng.gitbook.io/prometheus-book/part-ii-prometheus-jin-jie/sd/service-discovery-with-file)