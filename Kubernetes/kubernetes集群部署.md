# kubenetest集群部署
## 直接在CentOS系统上进行部署
* https://www.kubernetes.org.cn/doc-16
## 使用kubeadm安装k8s集群
* 使用CentOS7系统
1. 对所有节点的系统进行初始
   ```bash
     #!/bin/bash
     set -uexo pipefail
     
     yum makecache -y
     swapoff -a
     rm -f /swapfile
     sed -i "/swap/d" /etc/fstab
     
     cat > /etc/security/limits.d/20-nofile.conf << EOF
     * soft  nofile  1024000
     * hard  nofile  1024000
     EOF
     
     cat > /etc/security/limits.d/20-nproc.conf << EOF
     * soft  nproc 1024000
     * hard  nproc 1024000
     EOF
     
     cat > /usr/lib/sysctl.d/00-system.conf << EOF
     vm.swappiness = 0
     net.ipv4.ip_forward = 1
     net.ipv4.icmp_echo_ignore_broadcasts = 1
     net.ipv4.icmp_ignore_bogus_error_responses = 1
     net.ipv4.conf.all.rp_filter = 1
     net.ipv4.conf.default.rp_filter = 1
     net.ipv4.conf.all.accept_source_route = 0
     net.ipv4.conf.default.accept_source_route = 0
     net.ipv4.tcp_syncookies = 1
     kernel.sysrq = 0
     kernel.core_uses_pid = 1
     kernel.msgmnb = 65536
     kernel.msgmax = 65536
     kernel.shmmax = 68719476736
     kernel.shmall = 4294967296
     net.ipv4.tcp_max_tw_buckets = 6000
     net.ipv4.tcp_sack = 1
     net.ipv4.tcp_window_scaling = 1
     net.ipv4.tcp_rmem = 4096 87380 4194304
     net.ipv4.tcp_wmem = 4096 16384 4194304
     net.core.wmem_default = 8388608
     net.core.rmem_default = 8388608
     net.core.rmem_max = 16777216
     net.core.wmem_max = 16777216
     net.core.netdev_max_backlog = 262144
     net.ipv4.tcp_max_orphans = 3276800
     net.ipv4.tcp_max_syn_backlog = 262144
     net.ipv4.tcp_synack_retries = 1
     net.ipv4.tcp_syn_retries = 1
     net.ipv4.tcp_mem = 94500000 915000000 927000000
     net.ipv4.tcp_fin_timeout = 1
     net.ipv4.tcp_keepalive_time = 30
     net.ipv4.ip_local_port_range = 1024 65000
     net.netfilter.nf_conntrack_max=655350
     net.netfilter.nf_conntrack_tcp_timeout_established=1200
     EOF
     
     yum install -y docker
     systemctl daemon-reload
     systemctl enable --now docker
     
     # install k8s
     function K8S {
     cat <<EOF > /etc/yum.repos.d/kubernetes.repo
     [kubernetes]
     name=Kubernetes
     baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
     enabled=1
     gpgcheck=1
     repo_gpgcheck=1
     gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
     EOF
     
     setenforce 0
     sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config
     yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
     systemctl enable --now kubelet
     
     lsmod | grep br_netfilter
     if [ "$?" != "0" ];then
         modprobe br_netfilter
     fi
     cat <<EOF >  /etc/sysctl.d/k8s.conf
     net.bridge.bridge-nf-call-ip6tables = 1
     net.bridge.bridge-nf-call-iptables = 1
     EOF
     sysctl --system
     }
     
     # 安装kubeadmin、kubectl、kubelete工具
     cat <<EOF > /etc/yum.repos.d/kubernetes.repo
     [kubernetes]
     name=Kubernetes
     baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
     enabled=1
     gpgcheck=1
     repo_gpgcheck=1
     gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https:/packages.       cloud.google.com/yum/doc/rpm-package-key.gpg
     EOF
     
     setenforce 0
     sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config
     yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
     systemctl enable --now kubelet
     
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
2. 使用kubeadmin初始化集群
   ```bash
       #指定pod的cidr、service的cidr
       kubeadm init --pod-network-cidr 10.244.0.0/16 --service-cidr 10.96.0.0/12

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

       #在master上检查token是否有效，默认情况下，token会在24小时后失效，需要在master节点上重新创建token
       kubeadm token list
       kubeadm token create 

       #获取ca的hash字符串
       openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | \
       openssl dgst -sha256 -hex | sed 's/^.* //'
       
       #添加work节点，在work节点上执行
       kubeadm join MASTER_IP:6443 --token xxxxxx --discovery-token-ca-cert-hash sha256:<hash>

       #设置节点的标签
       kubectl label node k8s-node1 node-role.kubernetes.io/worker=worker
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