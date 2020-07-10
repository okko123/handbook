## calico问题记录
- calico节点无法正常运行
  - kubectl get nodes -n kube-system中显示calico节点的状态为0/1，说明calico的pod没有正常启动
  - kubectl logs pod calico-node-2pk5f -n kube-system -f;输出的内容
    ```bash
    :Readiness probe failed: caliconode is not ready: BIRD is not ready: BGP not established with 192.18.0.1
    ```
  - calicoctl node status，检查结果如下：
    ```bash
    #执行calicoctl前的准备工作
    export DATASTORE_TYPE=kubernetes
    export KUBECONFIG=~/.kube/config
    calicoctl node status
    ---
    Calico process is running.

    IPv4 BGP status
    +--------------+-------------------+-------+------------+-------------+
    | PEER ADDRESS |     PEER TYPE     | STATE |   SINCE    |    INFO     |
    +--------------+-------------------+-------+------------+-------------+
    | 192.16.1.2   | node-to-node mesh | up    | 2020-07-02 | Established |
    | 192.16.1.3   | node-to-node mesh | up    | 2020-07-02 | Established |
    | 192.16.1.4   | node-to-node mesh | up    | 2020-07-02 | Established |
    | 192.18.0.1   | node-to-node mesh | start | 2020-07-02 | Passive     |
    +--------------+-------------------+-------+------------+-------------+
    ```
    - 登录node节点上检查，发现其中一台机器因为安装openvpn，导致出现tun0、tun1的网卡。

- 问题处理
  - 调整 calicao 网络插件的网卡发现机制，修改 IP_AUTODETECTION_METHOD 对应的value值。官方提供的yaml文件中，ip识别策略（IPDETECTMETHOD）没有配置，即默认为first-found，这会导致一个网络异常的ip作为nodeIP被注册，从而影响node-to-node mesh。我们可以修改成 can-reach 或者interface 的策略，尝试连接某一个Ready的node的IP，以此选择出正确的IP。
  ```bash
  #请按照实际网卡名进行修改
  kubectl set env daemonset/calico-node -n kube-system IP_AUTODETECTION_METHOD=interface=eth.*
  ```

## 参考链接
- [calico官方文档，改变自动检测方式](https://docs.projectcalico.org/networking/ip-autodetection#change-the-autodetection-method)