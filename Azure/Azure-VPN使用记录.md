## AWS上使用windows机器与Azure内网进行打通
### AWS配置
- 在EC2上，创建Windows服务器
- 修改EC2实例上配置，禁止源/目标检查
- 在Windows上配置VPN
### Azure配置
- 配置虚拟网络网关
- 配置本地网络网关
- 创建连接

### 待测试，在linux上使用OpenSwan打通VPN
- 问题：配置文件配置

## 参考连接
* [官方配置教程](https://techcommunity.microsoft.com/t5/ITOps-Talk-Blog/Step-By-Step-Connect-your-AWS-and-Azure-environments-with-a-VPN/ba-p/339211)
* [VPN配置文件样例](https://github.com/Azure/Azure-vpn-config-samples/blob/master/Openswan/ipsec.conf)
* [Azure说明-1](https://docs.azure.cn/zh-cn/vpn-gateway/vpn-gateway-about-vpn-gateway-settings#vpntype)
* [Azure说明-2](https://docs.azure.cn/zh-cn/articles/azure-operations-guide/virtual-network/aog-virtual-network-howto-connect-routebased-vpn-and-policybased-vpn)