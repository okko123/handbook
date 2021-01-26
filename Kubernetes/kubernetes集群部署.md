# kubenetest集群部署
## 在CentOS7系统上，使用kubeadm安装k8s集群
1. 对所有节点的系统进行初始化，系统初始化脚本
   ```bash
   # 安装kubeadmin、kubectl、kubelete工具
   cat <<EOF > /etc/yum.repos.d/kubernetes.repo
   [kubernetes]
   name=Kubernetes
   baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
   enabled=1
   gpgcheck=1
   repo_gpgcheck=1
   gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
   exclude=kubelet kubeadm kubectl
   EOF
   
   VERSION="1.18.8"
   setenforce 0
   sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config
   yum install -y kubelet-${VERSION} kubeadm-${VERSION} kubectl-${VERSION} ipvsadm ipset --disableexcludes=kubernetes
   VERSION="19.03.12-3.el7"
   yum install -y docker-ce-$VERSION docker-ce-cli-$VERSION
   systemctl daemon-reload
   systemctl enable --now kubelet docker
   
   lsmod | grep br_netfilter
   if [ "$?" != "0" ];then
       modprobe br_netfilter
   fi
   cat <<EOF >  /etc/sysctl.d/k8s.conf
   net.bridge.bridge-nf-call-ip6tables = 1
   net.bridge.bridge-nf-call-iptables = 1
   EOF
   sysctl --system
   ```
2. 使用kubeadmin初始化集群，并启用ipvs
   ```bash
   #指定pod的cidr、service的cidr、启用ipvs
   CONFIG="/tmp/k8s.yaml"
   POD_CIDR="10.244.0.0/16"
   SVC_CIDR="10.96.0.0/12"
   MASTER_IP=`hostname -I | cut -d' ' -f 1`
   
   kubeadm config print init-defaults --component-configs KubeProxyConfiguration > /tmp/k8s.yaml
   sed -i "s|1.2.3.4|${MASTER_IP}|g" ${CONFIG}
   sed -i 's|mode: ""|mode: ipvs|g' ${CONFIG}
   sed -i "/serviceSubnet:/a\  podSubnet: ${POD_CIDR}" ${CONFIG}
   kubeadm init --config ${CONFIG}

   #复制kubectl的配置文件
   mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config

   wget https://docs.projectcalico.org/v3.11/manifests/calico.yaml
   sed -i 's|192.168.0.0/16|10.244.0.0/16|g' calico.yaml
   kubectl apply -f calico.yaml
   rm -f calico.yaml

   #检查kubernetes的集群状态
   kubectl get nodes
   NAME            STATUS   ROLES    AGE     VERSION
   k8s-master-1    Ready    master   1d      v1.17.4

   #在master上检查token是否有效，默认情况下，token会在24小时后失效，需要在master节点上重新创token
   kubeadm token list
   kubeadm token create 

   #获取ca的hash字符串
   openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2> /dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'
   
   #添加work节点，在work节点上执行
   kubeadm join MASTER_IP:6443 --token xxxxxx --discovery-token-ca-cert-hash sha256:<hash>

   #设置节点的标签
   kubectl label node k8s-node1 node-role.kubernetes.io/worker=
    ```
3. 移除节点
   ```bash
   kubectl drain <node name> --delete-local-data --force --ignore-daemonsets
   kubectl delete node <node name>
   
   #登录移除的节点上执行
   kubeadm reset
   iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
   ipvsadm -C
   ```
4. kubelet节点启用bootstrap TLS，在每个kubelet节点上执行：
   ```bash
   echo "serverTLSBootstrap: true" >> /var/lib/kubelet/config.yaml
   systemctl daemon-reload
   systemctl restart kubelet

   # 检查证书请求是否生效
   kubectl get csr
   # 手动审批 证书请求
   kubectl certificate approve csr-d6prp
   ```

### 官方文档
* [api版本为v1beta2](https://godoc.org/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta2)
* [kubeproxy的配置](https://godoc.org/k8s.io/kube-proxy/config/v1alpha1#KubeProxyConfiguration)
* [初始化启用ipvs的博客](https://sealyun.com/post/kubeadm/)