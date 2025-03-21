### containerd镜像配置
containerd config default | sudo tee /etc/containerd/config.toml
- 修改config_path的配置
```bash
config_path = /etc/containerd/certs.d

mkdir -p /etc/containerd/certs.d/docker.io
cat > /etc/containerd/certs.d/docker.io/hosts.toml <<EOF
[host."https://docker.1ms.run"]
  capabilities = ["pull", "resolve"]
  skip_verify = true
EOF

systemctl daemon-reload
systemctl restart containerd
```
