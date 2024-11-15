#!/bin/bash
set -uexo pipefail

yum makecache -y
yum install wget vim -y

swapoff -a
rm -f /swapfile
sed -i "/swap/d" /etc/fstab

cat > /etc/security/limits.d/20-nofile.conf << EOF
* soft  nofile  65536
* hard  nofile  65536
EOF

cat > /etc/security/limits.d/20-nproc.conf << EOF
* soft  nproc 65536
* hard  nproc 65536
EOF

cat > /usr/lib/sysctl.d/00-system.conf << EOF
vm.swappiness = 0

kernel.sysrq = 0
kernel.core_uses_pid = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296

net.ipv4.ip_forward = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 16384 4194304
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

net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144

net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1

user.max_user_namespaces=28633
EOF

cat << EOF > /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

# install containerd
yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum clean all
yum makecache
yum install -y containerd.io

containerd config default | sudo tee /etc/containerd/config.toml
sed -i "s#k8s.gcr.io#registry.cn-hangzhou.aliyuncs.com/google_containers#g"  /etc/containerd/config.toml
sed -i "s#registry.k8s.io#registry.cn-hangzhou.aliyuncs.com/google_containers#g"  /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
# add mirrors
sed -i  '/registry.mirrors/a\        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]\n\          endpoint = ["https://docker.fxxk.dedyn.io", "https://dockerhub.icu", "https://dockerpull.com", "https://dockerproxy.cn", "https://docker.registry.cyou", "https://docker-cf.registry.cyou", "https://hub.uuuadc.top", "https://docker.ckyl.me"]' /etc/containerd/config.toml

systemctl daemon-reload
systemctl restart containerd --now

# 注意，需要修改baseurl和gpgkey的版本号，当前版版本为1.30
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.30/rpm/repodata/repomd.xml.key
EOF

yum install -y kubelet-1.30.6 kubectl-1.30.6 kubeadm-1.30.6
systemctl enable kubelet && systemctl start kubelet

kubeadm config images pull --image-repository registry.cn-hangzhou.aliyuncs.com/google_containers --kubernetes-version 1.30.6