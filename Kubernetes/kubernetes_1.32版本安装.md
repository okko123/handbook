## k8s 1.32版本安装
- 系统：Alibaba Cloud Linux 3
- 要求内核版本大于5，或者4.19 LTS版本
- 容器运行时，containerd 版本要求大于1.6
1. 调整系统配置
   ```bash
   cat > /etc/sysctl.d/98-k8s.conf <<EOF
   net.ipv4.ip_forward = 1
   EOF
   ```
2. 安装docker、containerd；docker用于镜像构建
   ```bash
   yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
   
   yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
   
   systemctl enable containerd && systemctl start containerd
   ```
3. 调整containerd，添加镜像加速地址，修改镜像保存路径
   ```bash
   mkdir -p /etc/containerd/certs.d/docker.io /data/containerd
   containerd config default | sudo tee /etc/containerd/config.toml

   cat > /etc/containerd/certs.d/docker.io/hosts.toml <<EOF
   [host."https://docker.1ms.run"]
     capabilities = ["pull", "resolve"]
     skip_verify = true
   EOF

   sed -i 's|      config_path = ""|      config_path = "/etc/containerd/certs.d"|g' /etc/containerd/config.toml
   sed -i 's|root = "/var/lib/containerd"|root = "/data/containerd"|g' /etc/containerd/config.toml
   sed -i "s|k8s.gcr.io|registry.cn-hangzhou.aliyuncs.com/google_containers|g"  /etc/containerd/config.toml
   sed -i "s|registry.k8s.io|registry.cn-hangzhou.aliyuncs.com/google_containers|g"  /etc/containerd/config.toml
   sed -i 's|SystemdCgroup = false|SystemdCgroup = true|g' /etc/containerd/config.toml

   systemctl daemon-reload
   systemctl enable containerd && systemctl restart containerd
   ```
4. 安装k8s组件，1.32
   ```bash
   cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
   [kubernetes]
   name=Kubernetes
   baseurl=http://mirrors.cloud.aliyuncs.com/kubernetes-new/core/stable/v1.32/rpm/
   enabled=1
   gpgcheck=1
   gpgkey=http://mirrors.cloud.aliyuncs.com/kubernetes-new/core/stable/v1.32/rpm/repodata/repomd.xml.key
   EOF
   setenforce 0

   cat > /etc/sysconfig/kubelet <<EOF
   KUBELET_EXTRA_ARGS="--root-dir=/data/kubelet --enable-controller-attach-detach=true"
   EOF

   mkdir /data/kubelet
   yum install -y kubelet kubeadm kubectl
   systemctl enable kubelet && systemctl start kubelet

   kubeadm config images pull --image-repository registry.cn-hangzhou.aliyuncs.com/google_containers --kubernetes-version 1.32.12
   ```
5. 安装calico 3.30。官方在k8s 1.31 - 1.35上验证测试
   ```bash
   # 集群节点少于50个
   curl https://raw.githubusercontent.com/projectcalico/calico/v3.30.7/manifests/calico.yaml -O
   kubectl apply -f calico.yaml
   ```
6. 安装kube-prometheus，release-0.16可以在1.31 - 1.34上使用
   ```bash
   wget https://github.com/prometheus-operator/kube-prometheus/archive/refs/tags/v0.16.0.tar.gz
   tar xf v0.16.0.tar.gz
   cd kube-prometheus-0.16.0
   kubectl apply --server-side -f manifests/setup
   kubectl wait \
       --for condition=Established \
       --all CustomResourceDefinition \
       --namespace=monitoring
   kubectl apply -f manifests/
   ```