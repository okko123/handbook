## coredns
### 添加静态host绑定

- coredns的配置文件，添加hosts。fallthrough表示：本区域没有查询结果，则将请求传递给下一个插件
  ```bash
  .:53 {
      errors
      health {
          lameduck 5s
      }
      hosts {
          192.168.1.1 api.abc.cn
          192.168.1.1 ui.abc.cn
          192.168.1.1 uc.abc.cn
          fallthrough
      }
      log
      forward . /etc/resolv.conf {
          max_concurrent 1000
      }
      cache 30
      loop
      reload
      loadbalance
  }
  ```
### 添加指定域名转发
- 编辑configmap，添加以下内容：kubectl edit configmap coredns -n kube-system
  ```bash
  +   consul {
  +     errors
  +     cache 30
  +     forward . <consul-dns-service-cluster-ip>
  +   }
  ```
- 编辑完成后，重启coredns服务
kubectl rollout restart -n kube-system deployment/coredns

- 检查
dig @coredns-ip consul.service.consul SRV

### 参考连接
---
- https://www.consul.io/docs/k8s/dns
- https://coredns.io/plugins/forward/