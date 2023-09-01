## etcd使用笔记
- 查询成员
  ```bash
  ETCDCTL_API=3 etcdctl --endpoints 127.0.0.1:2379 \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  member list
  ```
- 删除成员
  ```bash
  ETCDCTL_API=3 etcdctl --endpoints 127.0.0.1:2379 \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  member remove 3f24efb55330441d
  ```
- 增加成员
  ```bash
  ETCDCTL_API=3 etcdctl --endpoints 127.0.0.1:2379 \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  member add cnhqvztpre01 --peer-urls=http://10.111.105.121:2380
  ```
- etcd制作快照
  ```bash
  ETCDCTL_API=3 etcdctl --endpoints 127.0.0.1:2379 snapshot save snapshotdb
  ```
---
### 创建etcd集群
- 基本信息
  |名字|IP地址|主机名|
  |-|-|-|
  |etcd-1|172.16.81.161|etcd-1|
  |etcd-2|172.16.81.162|etcd-2|
  |etcd-3|172.16.81.163|etcd-3|
- 使用cfssl工具，创建自签证书
  ```bash
  # 在github上下载cfssl工具
  wget https://github.com/cloudflare/cfssl/releases/download/v1.6.4/cfssl-certinfo_1.6.4_linux_amd64
  wget https://github.com/cloudflare/cfssl/releases/download/v1.6.4/cfssljson_1.6.4_linux_amd64
  wget https://github.com/cloudflare/cfssl/releases/download/v1.6.4/cfssl_1.6.4_linux_amd64
  chmod +x cfssl*

  mv cfssl_1.6.4_linux_amd64 /usr/local/bin/cfssl
  mv cfssljson_1.6.4_linux_amd64 /usr/local/bin/cfssljson
  mv cfssl-certinfo_1.6.4_linux_amd64 /usr/local/bin/cfssl-certinfo

  # 生成ca证书
  cat > ca-csr.json <<EOF
  {
    "CN": "etcd-ca",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
      {
        "C": "CN",
        "ST": "Beijing",
        "L": "Beijing",
        "O": "etcd-ca",
        "OU": "etcd-ca"
      }
    ],
    "ca": {
            "expiry": "87600h"
    }
  }
  EOF

  # 会生成：ca-key.pem, ca.csr, ca.pem
  cfssl gencert -initca ca-csr.json | cfssljson -bare ca

  #  配置 ca 证书策略
  cat > ca-config.json <<EOF
  {
    "signing": {
        "default": {
            "expiry": "87600h"
          },
        "profiles": {
            "etcd-ca": {
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth",
                    "client auth"
                ],
                "expiry": "87600h"
            }
        }
    }
  }
  EOF

  # 配置 etcd 请求 csr
  cat > etcd-csr.json <<EOF
  {
    "CN": "etcd",
    "hosts": [
      "127.0.0.1",
      "172.16.81.161",
      "172.16.81.162",
      "172.16.81.163"
    ],
    "key": {
      "algo": "rsa",
      "size": 2048
    },
    "names": [{
      "C": "CN",
      "ST": "Beijing",
      "L": "Beijing",
      "O": "etcd",
      "OU": "etcd"
    }]
  }
  EOF

  # 生成 etcd 证书；会生成：etcd-key.pem, etcd.csr, etcd.pem
  cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=etcd-ca etcd-csr.json | cfssljson  -bare etcd
  ```
- 启动etcd
```bash
cat > etcd-start.sh <<EOF
export ETCDCTL_API=3
/home/nuc/etcd-v3.4.27-linux-amd64/etcd \
--name etcd-1 \
--initial-advertise-peer-urls https://172.16.81.161:2380 \
--listen-peer-urls https://172.16.81.161:2380 \
--listen-client-urls https://172.16.81.161:2379,https://127.0.0.1:2379 \
--advertise-client-urls https://172.16.81.161:2379 \
--initial-cluster-token etcd-cluster-1 \
--initial-cluster etcd-1=https://172.16.81.161:2380,etcd-2=https://172.16.81.162:2380,etcd-3=https://172.16.81.163:2380 \
--initial-cluster-state new \
--client-cert-auth \
--trusted-ca-file=/home/nuc/etcd-v3.4.27-linux-amd64/ca.pem \
--cert-file=/home/nuc/etcd-v3.4.27-linux-amd64/etcd.pem \
--key-file=/home/nuc/etcd-v3.4.27-linux-amd64/etcd-key.pem \
--peer-client-cert-auth \
--peer-trusted-ca-file=/home/nuc/etcd-v3.4.27-linux-amd64/ca.pem \
--peer-cert-file=/home/nuc/etcd-v3.4.27-linux-amd64/etcd.pem \
--peer-key-file=/home/nuc/etcd-v3.4.27-linux-amd64/etcd-key.pem
EOF
```
- etcdctl检查集群状态
  ```bash
  ./etcdctl  endpoint health -w table  --cacert=ca.pem --cert=etcd.pem --key=etcd-key.pem    --endpoints=https://172.16.81.150:2379
  ```
---
### 参考信息
- [搭建 etcd 集群](https://doczhcn.gitbook.io/etcd/index/index-1/clustering)
- [K8s 系列(三) - 如何配置 etcd https 证书？](https://zhuanlan.zhihu.com/p/403724708)
- [etcd](http://timd.cn/etcd/)