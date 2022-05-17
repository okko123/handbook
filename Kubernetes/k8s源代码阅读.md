## k8s 源代码阅读
### 说明
> 在阅读 kubernetes 的代码的时候会发现，对 kubernetes 项目代码的引用使用的都是 k8s.io：
  ```bash
  package proxy
  
  import (
  	"bytes"
  	"fmt"

  	"github.com/pkg/errors"
  	apps "k8s.io/api/apps/v1"
  	v1 "k8s.io/api/core/v1"
  	rbac "k8s.io/api/rbac/v1"
  	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
  	kuberuntime "k8s.io/apimachinery/pkg/runtime"
  	clientset "k8s.io/client-go/kubernetes"
  	clientsetscheme "k8s.io/client-go/kubernetes/scheme"
  	kubeadmapi "k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm"
  	"k8s.io/kubernetes/cmd/kubeadm/app/componentconfigs"
  	"k8s.io/kubernetes/cmd/kubeadm/app/constants"
  	"k8s.io/kubernetes/cmd/kubeadm/app/images"
  	kubeadmutil "k8s.io/kubernetes/cmd/kubeadm/app/util"
  	"k8s.io/kubernetes/cmd/kubeadm/app/util/apiclient"
  )
  ```
> 主项目代码：k8s.io/kubernetes
  - 第一种情况是对主项目代码的引用。k8s.io/kubernetes 就是主项目代码的 package name，在 go-modules 使用的 go.mod 文件中定义的：
> 单独发布的代码
  - 第二种情况是对位于主项目中但是独立发布的代码的引用。kubernetes 的一些代码以独立项目的方式发布的，譬如：kubernetes/api、kubernetes/client-go 等，这些项目的 package name 也用同样的方式在 go.mod 中定义：
    ```bash
    module k8s.io/api
    或者
    module k8s.io/client-go
    ```
  - 要注意的是，这些代码虽然以独立项目发布，但是都在 kubernetes 主项目中维护，位于目录 kubernetes/staging/ ，这里面的代码代码被定期同步到各个独立项目中。
  - 更需要注意的是，kubernetes 主项目引用这些独立发布的代码时，引用是位于主项目 staging 目录中的代码，而不是独立 repo 中的代码。这是因为主项目的 vendor 目录中设置了符号链接：
    ```bash
    $ ls -lh vendor/k8s.io/
    api -> ../../staging/src/k8s.io/api
    apiextensions-apiserver -> ../../staging/src/k8s.io/  apiextensions-apiserver
    apimachinery -> ../../staging/src/k8s.io/apimachinery
    apiserver -> ../../staging/src/k8s.io/apiserver
    client-go -> ../../staging/src/k8s.io/client-go
    cli-runtime -> ../../staging/src/k8s.io/cli-runtime
    cloud-provider -> ../../staging/src/k8s.io/cloud-provider
    cluster-bootstrap -> ../../staging/src/k8s.io/  cluster-bootstrap
    code-generator -> ../../staging/src/k8s.io/code-generator
    component-base -> ../../staging/src/k8s.io/component-base
    cri-api -> ../../staging/src/k8s.io/cri-api
    csi-translation-lib -> ../../staging/src/k8s.io/  csi-translation-lib
    gengo
    heapster
    klog
    kube-aggregator -> ../../staging/src/k8s.io/kube-aggregator
    kube-controller-manager -> ../../staging/src/k8s.io/  kube-controller-manager
    kubectl -> ../../staging/src/k8s.io/kubectl
    kubelet -> ../../staging/src/k8s.io/kubelet
    kube-openapi
    kube-proxy -> ../../staging/src/k8s.io/kube-proxy
    kube-scheduler -> ../../staging/src/k8s.io/kube-scheduler
    legacy-cloud-providers -> ../../staging/src/k8s.io/  legacy-cloud-providers
    metrics -> ../../staging/src/k8s.io/metrics
    repo-infra
    sample-apiserver -> ../../staging/src/k8s.io/  sample-apiserver
    sample-cli-plugin -> ../../staging/src/k8s.io/  sample-cli-plugin
    sample-controller -> ../../staging/src/k8s.io/  sample-controller
    system-validators
    utils
    ```
