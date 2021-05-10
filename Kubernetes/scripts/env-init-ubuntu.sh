
sed -i "s@http://.*archive.ubuntu.com@http://repo.huaweicloud.com@g" /etc/apt/sources.list
sed -i "s@http://.*security.ubuntu.com@http://repo.huaweicloud.com@g" /etc/apt/sources.list

apt-get remove docker docker-engine docker.io
apt-get install apt-transport-https ca-certificates curl gnupg2 software-properties-common
curl -fsSL https://repo.huaweicloud.com/docker-ce/linux/ubuntu/gpg |  apt-key add -
add-apt-repository "deb [arch=amd64] https://repo.huaweicloud.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
apt-get install -y docker-ce

curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add - 
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl