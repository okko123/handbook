## kubernetes亲和与反亲和
---
- 使用nodeSelector，将pod调度到指定的node节点上
  ```yaml
  # 先在指定的node节点上打上label
  kubectl label nodes node-name source=busybox
  
  cat > busybox.yaml <<EOF
  apiVersion: v1
  kind: Pod
  metadata:
    labels:
      app: busybox-pod
    name: test-busybox
  spec:
    containers:
    - command:
      - sleep
      - "3600"
      image: busybox
      imagePullPolicy: Always
      name: test-busybox
    nodeSelector:
      source: busybox
  EOF
  
  kubectl apply -f busybox.yaml
  ```
- 使用nodeAffinity节点亲和，将pod调度到指定的node节点上
  > 下面这个 POD 首先是要求 POD 不能运行在140和161两个节点上，如果有个节点满足source=qikqiak的话就优先调度到这个节点上，同样的我们可以使用descirbe命令查看具体的调度情况是否满足我们的要求。这里的匹配逻辑是 label 的值在某个列表中，现在Kubernetes提供的操作符有下面的几种：
    - In：label 的值在某个列表中
    - NotIn：label 的值不在某个列表中
    - Gt：label 的值大于某个值
    - Lt：label 的值小于某个值
    - Exists：某个 label 存在
    - DoesNotExist：某个 label 不存在
  ```yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: with-node-affinity
    labels:
      app: node-affinity-pod
  spec:
    containers:
    - name: with-node-affinity
      image: nginx
    affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: kubernetes.io/hostname
              operator: NotIn
              values:
              - 192.168.1.140
              - 192.168.1.161
        preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 1
          preference:
            matchExpressions:
            - key: source
              operator: In
              values:
              - qikqiak
  ```
---
- nodeSelector / nodeAffinity 两种方式都是让 POD 去选择节点的，有的时候我们也希望能够根据 POD 之间的关系进行调度，Kubernetes在1.4版本引入的podAffinity概念就可以实现我们这个需求。
  > 和nodeAffinity类似，podAffinity也有requiredDuringSchedulingIgnoredDuringExecution和 preferredDuringSchedulingIgnoredDuringExecution两种调度策略，唯一不同的是如果要使用互斥性，我们需要使用podAntiAffinity字段。 如下例子，我们希望with-pod-affinity和busybox-pod能够就近部署，而不希望和node-affinity-pod部署在同一个拓扑域下面：
  ```yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: with-pod-affinity
    labels:
      app: pod-affinity-pod
  spec:
    containers:
    - name: with-pod-affinity
      image: nginx
    affinity:
      podAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchExpressions:
            - key: app
              operator: In
              values:
              - busybox-pod
          topologyKey: kubernetes.io/hostname
      podAntiAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 1
          podAffinityTerm:
            labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - node-affinity-pod
            topologyKey: kubernetes.io/hostname
  ```
- 调试pod亲和的例子
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: busybox
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/hostname
            operator: In
            values:
            - k8sw01
      preferredDuringSchedulingIgnoredDuringExecution:
  containers:
  - name: busybox
    image: busybox
    args:
    - /bin/sh
    - -c
    - sleep 100000
```
---
## 污点（Taints）与容忍（tolerations）
- 对于nodeAffinity无论是硬策略还是软策略方式，都是调度 POD 到预期节点上，而Taints恰好与之相反，如果一个节点标记为 Taints ，除非 POD 也被标识为可以容忍污点节点，否则该 Taints 节点不会被调度pod。

  > 比如用户希望把 Master 节点保留给 Kubernetes 系统组件使用，或者把一组具有特殊资源预留给某些 POD，则污点就很有用了，POD 不会再被调度到 taint 标记过的节点。taint 标记节点举例如下：
```yaml
$ kubectl taint nodes 192.168.1.40 key=value:NoSchedule
node "192.168.1.40" tainted
```
- 如果仍然希望某个 POD 调度到 taint 节点上，则必须在 Spec 中做出Toleration定义，才能调度到该节点，举例如下：
```yaml
tolerations:
- key: "key"
operator: "Equal"
value: "value"
effect: "NoSchedule"
```
> effect 共有三个可选项，可按实际需求进行设置：
  - NoSchedule：POD 不会被调度到标记为 taints 节点。
  - PreferNoSchedule：NoSchedule 的软策略版本。
  - NoExecute：该选项意味着一旦 Taint 生效，如该节点内正在运行的 POD 没有对应 Tolerate 设置，会直接被逐出。

---
- 要配置"反亲和策略"，确保被驱逐的pod被调度到不同的Node节点上
  ```yaml
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - web
        topologyKey: kubernetes.io/hostname
  ```
  ---
  ## 参考资料
  - [理解 Kubernetes 的亲和性调度](https://www.qikqiak.com/post/understand-kubernetes-affinity/)
  - [Assigning Pods to Nodes](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)