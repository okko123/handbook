#配置容器运行时，安装、配置 containerd
cat <<EOF | tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# 设置必需的 sysctl 参数，这些参数在重新启动后仍然存在。
cat <<EOF | tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

# 应用 sysctl 参数而无需重新启动
sysctl --system

# 给换apt源，使用华为云镜像源
sed -i "s@http://.*archive.ubuntu.com@http://repo.huaweicloud.com@g" /etc/apt/sources.list
sed -i "s@http://.*security.ubuntu.com@http://repo.huaweicloud.com@g" /etc/apt/sources.list

# DEB822 配置方法
cat > /etc/apt/sources.list.d/aliyun.sources <<'EOF'
Types: deb
URIs: https://mirrors.aliyun.com/ubuntu
Suites: noble noble-updates noble-backports
Components: main universe restricted multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: https://mirrors.aliyun.com/ubuntu
Suites: noble-security
Components: main universe restricted multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF

# 安装
apt install -y containerd
mkdir -p /etc/containerd /etc/containerd/certs.d/docker.io/
containerd config default | tee /etc/containerd/config.toml
cat > /etc/containerd/certs.d/docker.io/hosts.toml <<EOF
[host."https://docker.1ms.run"]
  capabilities = ["pull", "resolve"]
  skip_verify = true
EOF

# 修改配置
sed -i 's|      config_path = ""|      config_path = "/etc/containerd/certs.d"|g' /etc/containerd/config.toml
sed -i "s#k8s.gcr.io#registry.cn-hangzhou.aliyuncs.com/google_containers#g"  /etc/containerd/config.toml
sed -i "s#registry.k8s.io#registry.cn-hangzhou.aliyuncs.com/google_containers#g"  /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# 重启containerd
systemctl daemon-reload
systemctl restart containerd --now
systemctl enable containerd

cat > /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

apt-get remove docker docker-engine docker.io
apt-get install apt-transport-https ca-certificates curl gnupg2 software-properties-common

#安装k8s组件，1.28版本
apt-get update && apt-get install -y apt-transport-https
curl -fsSL https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.32/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.32/deb/ /" |
    tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl

# 1.24版本以前
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add - 
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl