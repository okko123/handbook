### 修改kubelet的配置文件
```bash
cat >> config.yaml <<EOF
# 启用TLS
serverTLSBootstrap: true
# 修改systemd预留资源，默认是空
systemReserved: {
  cpu: 100m,
  memory: 100Mi
}
# 修改kube预留资源，默认是空
kubeReserved: {
  "cpu": "70m",
  "memory": "574Mi"
  }
# tls支持的最小版本
tlsMinVersion: VersionTLS12
# 修改tls协议套件
tlsCipherSuites: [
    "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256",
    "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
    "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305",
    "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
    "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305",
    "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384",
    "TLS_RSA_WITH_AES_256_GCM_SHA384",
    "TLS_RSA_WITH_AES_128_GCM_SHA256"
  ]
```
---
- [kubelet参数配置](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/)
- [Kubelet Configuration (v1)](https://kubernetes.io/docs/reference/config-api/kubelet-config.v1/)
- [Kubelet Configuration (v1beta1)](https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/)