## calico笔记
- calico在k8s集群中安装
  - 在initContainers阶段，
    1. 执行calico-ipam进行更新，
    2. 使用/opt/cni/bin/install安装calico、插件和calico配置。且将系统的/opt/cni/bin、/etc/cni/net.d挂载到容器中。复制插件与配置文件。使用镜像：docker.io/calico/cni:v3.26.1
    3. 使用calico-init进行初始化，使用镜像：docker.io/calico/node:v3.26.1
- bgp peer参数配置说明：
  |参数|描述|
  |---|---|
  |node|指定BGP Peer应用在哪个node上。如果指定此字段，则为node级别，否则为global级别。|
  |peerIP|指定远端的Peer地址，可以是IP加端口的形式，端口可选。支持IPV4和IPV6。|
  |asNumber|远端Peer的AS号。|
  |nodeSelector|用于通过标签来选择一组node，作为BGP Peer应用的节点，注意这里的node为Calico中的node，而非K8s中的node。如果指定了此字段，则node应该为空。|
  |peerSelector|用于通过标签来选择一组node（同样为Calico中的node），作为远端Peer的节点。如果指定了此字段，则peerIP和asNumber都应该为空。|
  |keepOriginalNextHop|对于EBGP，保持并转发原始的next hop，不将自身加入到Path中。|
  |password|BGP会话的身份验证。|
  > 在过去的版本，Calico中包含了BGP Peer对象和Global BGP Peer对象，目前已统一为BGP Peer对象，根据是指定node参数还是nodeSelector参数来区分。
- BGP Configuration
  > 除了BGP Peer外，Calico通过BGP Configuration对象来控制全局的BGP行为。主要参数包括：

  |参数|描述|默认值|
  |---|---|---|
  |nodeToNodeMeshEnabled|开启Calico节点之间的node-to-node mesh。|true|
  |asNumber|Calico node默认的节点AS。|64512|
  |serviceClusterIPs|Calico需要对外BGP的service ClusterIP地址段。||
  |serviceExternalIPs|Calico需要对外BGP的service ExternalIPs地址段。||
  |communities|用于定义BGP community，由name和value组成，value支持标准community以及large community。||
  |prefixAdvertisements|指定网段与community的隶属关系，可以通过communities中的name指定，也可以通过community value直接指定。||
  > 默认情况下，Calico所有节点通过IBGP来交换各个节点的workload（容器）路由信息，由于从IBGP Peer中学习到的路由不会被再次转发，因此需要使用node-to-node mesh的方式两两互连。

  > serviceClusterIPs和serviceExternalIPs字段的功能类似于MetalLB的BGP模式，可以将K8s Service的访问地址（ClusterIP和ExternalIP）BGP到集群外的设备（例如TOR）。结合ECMP，可以将外部访问K8s Service的流量负载到K8s节点上，由Kube-proxy转发到真正的容器后端。

  > communities与prefixAdvertisements可以控制Calico BGP路由的community字段，支持RFC 1997中的well-known communities。使用样例如下：