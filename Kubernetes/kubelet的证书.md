# kubernetes的证书
使用kubeadmin创建的证书只有一年有效期，检查所有证书的过期时间： 
* 使用kubeadmin创建集群的检查方法：kubeadm alpha certs check-expiration
* 其他集群的检查方法：
  ```bash
  CERT_DIR=${CERT_DIR:-/etc/kubernetes/pki}
  for i in $(find $CERT_DIR -name '*.crt' -o -name '*.pem');
  do
      echo $i
      openssl x509 -enddate -in $i -noout
  done

  for f in $(ls /etc/kubernetes/{admin,controller-manager,scheduler}.conf);
  do
      echo $f
      kubectl --kubeconfig $f config view --raw -o jsonpath='{range .users[*]}{.user.client-certificate-data}{end}' | base64 -d | openssl x509 -enddate -noout
  done
  ```
## master节点
* 证书存储的位置/etc/kubernetes/pki/
* etcd使用证书的存储位置/etc/kubernetes/pki/etcd
* 使用kubeadm更新所有证书：kubeadm alpha certs renew all

## 使用启动引导令牌（Bootstrap Tokens）认证
* TLS启动过程
  ![](img/bootstrap-process.png)
---
## kubelet自动生成的证书
- 证书保存在/var/lib/kubelet/pki/目录中
  - token.csv
     > 该文件为一个用户的描述文件，基本格式为 Token,用户名,UID,用户组；这个文件在 apiserver 启动时被 apiserver 加载，然后就相当于在集群内创建了一个这个用户；接下来就可以用 RBAC 给他授权；持有这个用户 Token 的组件访问 apiserver 的时候，apiserver 根据 RBAC 定义的该用户应当具有的权限来处理相应请求

  - bootstarp.kubeconfig
    > 该文件中内置了 token.csv 中用户的 Token，以及 apiserver CA 证书；kubelet 首次启动会加载此文件，使用 apiserver CA 证书建立与 apiserver 的 TLS 通讯，使用其中的用户 Token 作为身份标识像 apiserver 发起 CSR 请求

  - kubelet-client.crt
    > 该文件在 kubelet 完成 TLS bootstrapping 后生成，此证书是由 controller manager 签署的，此后 kubelet 将会加载该证书，用于与 apiserver 建立 TLS 通讯，同时使用该证书的 CN 字段作为用户名，O 字段作为用户组向 apiserver 发起其他请求

  - kubelet.crt
    > 该文件在 kubelet 完成 TLS bootstrapping 后并且没有配置 --feature-gates=RotateKubeletServerCertificate=true 时才会生成；这种情况下该文件为一个独立于 apiserver CA 的自签 CA 证书，有效期为 1 年；被用作 kubelet 10250 api 端口

  - kubelet-server.crt
    > 该文件在 kubelet 完成 TLS bootstrapping 后并且配置了 --feature-gates=RotateKubeletServerCertificate=true 时才会生成；这种情况下该证书由 apiserver CA 签署，默认有效期同样是 1 年，被用作 kubelet 10250 api 端口鉴权

  - kubelet-client-current.pem
    > 这是一个软连接文件，当 kubelet 配置了 --feature-gates=RotateKubeletClientCertificate=true选项后，会在证书总有效期的 70%~90% 的时间内发起续期请求，请求被批准后会生成一个 kubelet-client-时间戳.pem；kubelet-client-current.pem 文件则始终软连接到最新的真实证书文件，除首次启动外，kubelet 一直会使用这个证书同 apiserver 通讯

  - kubelet-server-current.pem
    > 同样是一个软连接文件，当 kubelet 配置了 --feature-gates=RotateKubeletServerCertificate=true 选项后，会在证书总有效期的 70%~90% 的时间内发起续期请求，请求被批准后会生成一个 kubelet-server-时间戳.pem；kubelet-server-current.pem 文件则始终软连接到最新的真实证书文件，该文件将会一直被用于 kubelet 10250 api 端口鉴权
### 更新kubelet使用的证书
- 修改kubelet配置文件：/var/lib/kubelet/config.yaml
  > 添加内容：serverTLSBootstrap: true
- 重启kubelet
  > systemctl restart kubelet
- kubectl检查证书请求
  > kubectl get csr -A
- 通过证书请求
  > kubectl certificate approve csr-xxxxx
- 检查kubelet证书是否更新
  > echo |openssl s_client -connect 192.168.1.1:10250 2>/dev/null |openssl x509 -noout -dates
---
## 生成启动引导令牌与bootstrap-kubeconfig文件
每个合法的令牌背后对应着 kube-system 命名空间中的bootstrap-token-<token-id> Secret 对象。
* 使用工具生成token：kubeadm token create --ttl 2h
* 手动生成
  ```bash
  # 生成token-id、token-secret，注意token定义有expiration字段，说明token是有有效时间
  TOKENID=`head -c 6 /dev/urandom | md5sum | head -c 6`
  TOKENSECRET=`head -c 16 /dev/urandom | md5sum | head -c 16`
  TIME=`date -d "+6 hour" +%Y-%m-%dT%H:00:00%:z`
  KUBE_APISERVER="https://192.168.1.1:6443"
  
  cat <<EOF | kubectl apply -f -
  apiVersion: v1
  kind: Secret
  metadata:
    name: bootstrap-token-${TOKENID}
    namespace: kube-system
  type: bootstrap.kubernetes.io/token
  stringData:
    description: "The bootstrap token for testing."
    token-id: ${TOKENID}
    token-secret: ${TOKENSECRET}
    expiration: ${TIME}
    usage-bootstrap-authentication: "true"
    usage-bootstrap-signing: "true"
    auth-extra-groups: system:bootstrappers:kubeadm:default-node-token
  EOF

  BOOTSTRAP_TOKEN="$TOKENID.$TOKENSECRET"
  cd /etc/kubernetes
  
  # 设置集群参数
  kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/pki/ca.crt \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=bootstrap.kubeconfig
  
  # 设置客户端认证参数
  kubectl config set-credentials kubelet-bootstrap \
  --token=${BOOTSTRAP_TOKEN} \
  --kubeconfig=bootstrap.kubeconfig
  
  # 设置上下文参数
  kubectl config set-context default \
  --cluster=kubernetes \
  --user=kubelet-bootstrap \
  --kubeconfig=bootstrap.kubeconfig
  
  # 设置默认上下文
  kubectl config use-context default --kubeconfig=bootstrap.kubeconfig
  
  mv bootstrap.kubeconfig /etc/kubernetes/bootstrap-kubelet.conf
  ```
  ## 参考信息
* [Kubernetes 集群 TLS 证书管理最佳实践](https://zhuanlan.zhihu.com/p/133828552)
* [api信息查询](https://kubernetes.io/docs/reference/kubernetes-api/api-index/)
* [官方bootstrap的文档](https://kubernetes.io/zh/docs/reference/access-authn-authz/bootstrap-tokens/)
* [官方证书更新](https://kubernetes.io/zh-cn/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/)
* [kubelet配置文件介绍](https://kubernetes.io/zh/docs/reference/config-api/kubelet-config.v1beta1/)