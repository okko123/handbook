## kubectl工具使用
* 创建资源：kubectl create
  * configmap
  * deployment
  * namespace
  * service
  * secret
* 获取信息：kubectl get;列出受支持的资源类型(kubectl api-resources)
  * all
  * configmaps (aka 'cm')
  * deployments (aka 'deploy')
  * endpoints (aka 'ep')
  * ingresses (aka 'ing')
  * jobs
  * namespaces (aka 'ns')
  * nodes (aka 'no')
  * persistentvolumeclaims (aka 'pvc')
  * persistentvolumes (aka 'pv')
  * pods (aka 'po')
  * secrets
  * services (aka 'svc')
  * certificatesigningrequests (aka 'csr')
* 获取yaml配置文件帮助：kubectl explain
* 删除资源：kubectl delete
  * pods
  * deployment
* 获取集群pod、service的CIDR记录
  * kubectl cluster-info dump | grep -m 1 service-cluster-ip-range
  * kubectl cluster-info dump | grep -m 1 cluster-cidr
* 修改deployment的副本数量
  * kubectl scale deployment.v1.apps/deployment-name --replicas=1 -n namespace
## kubernetes 污点使用
* kubectl taint node [node] key=value[effect]   
  * 其中[effect] 可取值: [ NoSchedule | PreferNoSchedule | NoExecute ]
  * NoSchedule: 一定不能被调度
  * PreferNoSchedule: 尽量不要调度
  * NoExecute: 不仅不会调度, 还会驱逐Node上已有的Pod
  ```bash
  ## master节点设置taint
  kubectl taint nodes master1 node-role.kubernetes.io/master=:NoSchedule
  ## 所有节点删除taint
  kubectl taint nodes --all node-role.kubernetes.io/master-
  ```
## 切换集群上下文和命名空间
- 实际上，我们也可以不使用额外的工具来切换上下文和命名空间，因为 kubectl 也提供了切换操作的命令，kubectl config命令就提供了用于编辑 kubeconfig 文件的功能，下面是一些基本用法：
  > kubectl config get-contexts: 列出所有的 context
  
  > kubectl config current-context: 获取当前的 context
  
  > kubectl config use-context: 更改当前 context
  
  > kubectl config set-context: 修改 context 的元素
## 查看deployment更新
```bash
kubectl rollout status -n namespace deployment test-deployment
# 正常更新的结果为
deployment "test-deployment" successfully rolled out

# 有异常的结果为
error: deployment "test-deployment" exceeded its progress deadline

kubectl get -n namespace deployement test-deployment -o yaml
# 在status字段中，提示更新失败的原因
- [查看 Deployment 的状态](https://kuboard.cn/learning/k8s-intermediate/workload/wl-deployment/status.html)
```
## kubernetes pv和pvc使用记录
* https://kubernetes.io/zh/docs/concepts/storage/volumes/#hostpath
## alphine系统使用笔记
* 安装telnet：apk add busybox-extras
## docker使用命令
* 运行alphine系统，并进入命令行：docker run -it alphine:lastest
---
## 参考链接
* http://docs.kubernetes.org.cn/537.html
* https://kubernetes.io/docs/concepts/services-networking/ingress/
---
### 通过shell执行kubectl exec并在对应pod容器内执行shell命令
   ```bash
   # 需要注意的是：shell命令前，要加 -- 号，不然shell命令中的参数，不能识别
   kubectl exec -it <podName> -c <containerName> -n <namespace> -- shell comand

   # 创建文件
   kubectl exec -it <podname> -c <container name> -n <namespace> -- touch /usr/local/testfile

   kubectl create secret generic regcred --from-file=.dockerconfigjson=/root/.docker/config.json --type=kubernetes.io/dockerconfigjson -n test

   kubectl create configmap b2b-web-config --from-file=b2b-web.conf -n test
   ```
### 获取指定namespace中，deployment的镜像版本
   ```bash
   for i in `kubectl get deployment -n namespace --no-headers|awk '{print $1}'`
   do
       kubectl get deployment -n namespace $i -o jsonpath='{.spec.template.spec.containers   [0].image}'
       echo " "
   done
   ```
### 更新指定namespace中，deployment的镜像版本
   ```bash
   #需要先把镜像版本导入到images.txt的文件中
    
   cat > images.txt<<EOF
   www.baidu.com:9091/springcloud/abc-service:qa-merge-35
   www.baidu.com:9091/springcloud/bcd-service:qa-gray-112
   www.baidu.com:9091/springcloud/web:qa-gray-76
   EOF
    
   for i in `kubectl get deployment -n namespace --no-headers|awk '{print $1}'`
   do
       VERSION=`grep $i images.txt`
       echo $VERSION || echo "no version"
       kubectl set image -n namespace deployment/${i} ${i}=${VERSION}
   done
   ```
### 更新指定namespace中，deployment的副本数量
   ```bash
   for job in `kubectl get deployment -n namespace --no-headers|awk '{print $1}'`;
   do
       kubectl scale deployment.v1.apps/$job --replicas=0 -n namespace
   done
   ```
### 重启指定deployment下的容器
   ```bash
   for job in `kubectl get deployment -n namespace --no-headers|awk '{print $1}'`;
   do
       kubectl -n namespace rollout restart deploy $job
   done
   ```
### 查看deployment版本
- kubectl rollout history deployment.v1.apps/nginx-deployment -n namespace

### 修改terminationGracePeriodSeconds
  ```bash
  cat > patch.yaml <<EOF
  spec:
    template:
      spec:
        terminationGracePeriodSeconds: 45
  EOF
  kubectl patch deployment deploymentname -n namespace --patch "$(cat patch.yaml)"
  ```

### 端口映射
```bash
kubectl port-forward --namespace=ingress-nginx service/ingress-nginx-controller 8080:80
```

### 创建deployment、ingress、svc
```bash
kubectl create deployment echo --image=e2eteam/echoserver:2.2 --port=8080
kubectl expose deployment echo
kubectl create ingress echo --class=kong --rule="echo.qdama.test/*=echo:8080"
```