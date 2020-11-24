# kubernetes版本升级
## 使用kubeadm进行集群升级
- 检查k8s集群当前版本
  ```bash
  kubeadm version
  kubeadm version: &version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.3", GitCommit:"2e7996e3e2712684bc73f0dec0200d64eec7fe40", GitTreeState:"clean", BuildDate:"2020-05-20T12:49:29Z", GoVersion:"go1.13.9", Compiler:"gc", Platform:"linux/amd64"}

  kubectl version
  Client Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.3", GitCommit:"2e7996e3e2712684bc73f0dec0200d64eec7fe40", GitTreeState:"clean", BuildDate:"2020-05-20T12:52:00Z", GoVersion:"go1.13.9", Compiler:"gc", Platform:"linux/amd64"}
  Server Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.3", GitCommit:"2e7996e3e2712684bc73f0dec0200d64eec7fe40", GitTreeState:"clean", BuildDate:"2020-05-20T12:43:34Z", GoVersion:"go1.13.9", Compiler:"gc", Platform:"linux/amd64"}
  ```
- 检查哪些版本可用于升级并验证当前群集是否可升级
  ```bash
  kubeadm upgrade plan
  [upgrade/config] Making sure the configuration is correct:
  [upgrade/config] Reading configuration from the cluster...
  [upgrade/config] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
  [preflight] Running pre-flight checks.
  [upgrade] Running cluster health checks
  [upgrade] Fetching available versions to upgrade to
  [upgrade/versions] Cluster version: v1.18.3
  [upgrade/versions] kubeadm version: v1.18.3
  I1117 18:29:30.217183    1422 version.go:252] remote version is much newer: v1.19.4; falling back to: stable-1.18
  [upgrade/versions] Latest stable version: v1.18.12
  [upgrade/versions] Latest stable version: v1.18.12
  [upgrade/versions] Latest version in the v1.18 series: v1.18.12
  [upgrade/versions] Latest version in the v1.18 series: v1.18.12
  
  Components that must be upgraded manually after you have upgraded the control plane with 'kubeadm upgrade apply':
  COMPONENT   CURRENT       AVAILABLE
  Kubelet     4 x v1.18.3   v1.18.12
  
  Upgrade to the latest version in the v1.18 series:
  
  COMPONENT            CURRENT   AVAILABLE
  API Server           v1.18.3   v1.18.12
  Controller Manager   v1.18.3   v1.18.12
  Scheduler            v1.18.3   v1.18.12
  Kube Proxy           v1.18.3   v1.18.12
  CoreDNS              1.6.7     1.6.7
  Etcd                 3.4.3     3.4.3-0
  
  You can now apply the upgrade by executing the following command:
  
          kubeadm upgrade apply v1.18.12
  
  Note: Before you can perform this upgrade, you have to update kubeadm to v1.18.12.
  
  _____________________________________________________________________
  ```
- 升级集群，在控制节点上执行
  ```bash
  kubeadm upgrade apply v1.18.6
  ```

---
## 参考信息
- [Kubernetes 版本升级](https://www.jianshu.com/p/e4c14880a9ba)
  