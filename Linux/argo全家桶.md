## argo全家桶

### argo workflow使用笔记
- Argo Workflows 的快速部署方式非常简单，下面两行命令即可：
```bash
$ kubectl create namespace argo
namespace/argo created
$ kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/download/v3.6.10/install.yaml
...
priorityclass.scheduling.k8s.io/workflow-controller created
deployment.apps/argo-server created
deployment.apps/workflow-controller created

# 安装CLI工具
# Detect OS
ARGO_OS="darwin"
if [[ uname -s != "Darwin" ]]; then
  ARGO_OS="linux"
fi

# Download the binary
curl -sLO "https://github.com/argoproj/argo-workflows/releases/download/v3.6.10/argo-$ARGO_OS-amd64.gz"

# Unzip
gunzip "argo-$ARGO_OS-amd64.gz"

# Make binary executable
chmod +x "argo-$ARGO_OS-amd64"

# Move binary to path
mv "./argo-$ARGO_OS-amd64" /usr/local/bin/argo

# Test installation
argo version
```
- 默认的认证方式需要使用 Service Account，并且需要进行较多的 RBAC 配置，有些复杂，所以这里改成了服务侧自行认证。
```bash
$ kubectl patch deployment \
  argo-server \
  --namespace argo \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": [
  "server",
  "--auth-mode=server"
]}]'
```
- 然后把服务改成 NodePort：
```bash
$ kubectl patch svc argo-server -n argo -p '{"spec": {"type": "NodePort"}}'
service/argo-server patched
```