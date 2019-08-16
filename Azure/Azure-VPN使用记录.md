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

### 部署libreswan
* 环境设定，实验的操作系统CentOS Linux release 7.6.1810
```bash
yum install libreswan -y
cat > /etc/ipsec.d/site2site.conf <<'EOF'
conn conn2Azure
        authby=secret
        auto=start
        dpdaction=restart
        dpddelay=30
        dpdtimeout=120
        ike=aes256-sha256;MODP1024
        ikelifetime=10800s
        ikev2=yes
        keyingtries=3
        left=%defaultroute
        leftid=<MY PUBLIC IP>
        leftsubnets=<Azure Local Network Gateway Subnets>
        pfs=yes
        #phase2alg=aes128-sha1
        right=<Azure Route Based GW IP>
        rightid=<Azure Route Based GW IP>
        rightsubnets=<vNet Subnet>
        salifetime=3600s
        type=tunnel
EOF
cat > /etc/ipsec.d/site2site.secrets <<'EOF'
%any 0.0.0.0: PSK "azure2gcp"
EOF
```
## 参考连接
* [官方配置教程](https://techcommunity.microsoft.com/t5/ITOps-Talk-Blog/Step-By-Step-Connect-your-AWS-and-Azure-environments-with-a-VPN/ba-p/339211)
* [VPN配置文件样例](https://github.com/Azure/Azure-vpn-config-samples/blob/master/Openswan/ipsec.conf)
* [Azure说明-1](https://docs.azure.cn/zh-cn/vpn-gateway/vpn-gateway-about-vpn-gateway-settings#vpntype)
* [Azure说明-2](https://docs.azure.cn/zh-cn/articles/azure-operations-guide/virtual-network/aog-virtual-network-howto-connect-routebased-vpn-and-policybased-vpn)
* [libreswan](https://libreswan.org/wiki/Microsoft_Azure_configuration)
* [微软官方ipsec配置要求](https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-about-vpn-devices)