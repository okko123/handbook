## AWS上使用windows机器与Azure内网进行打通
### AWS配置
- 在EC2上，创建Windows服务器
- 修改EC2实例上配置，禁止源/目标检查
- 在Windows上配置VPN
### Azure配置
- 配置虚拟网络网关
- 配置本地网络网关
- 创建连接

### libreswan与Azure托管VPN构建site2site模式的VPN连接
* 操作系统: CentOS Linux release 7.6.1810
* libreswan: 3.15-7.3.9
---
```bash
#使用yum安装libreswan
yum install libreswan -y

#修改系统参数，执行systctl -p使其生效，rp_filter需要根据实际网卡命名调整
cat >> /etc/sysctl.conf <<'EOF'
net.ipv4.ip_forward = 1
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.eth0.rp_filter = 0
net.ipv4.conf.lo.rp_filter = 0
EOF
sysctl -p

#添加连接配置
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

#修改ipsec的PSK
cat > /etc/ipsec.d/site2site.secrets <<'EOF'
%any 0.0.0.0: PSK "azure2gcp"
EOF

#启动/停止/查看ipsec
systemctl start/stop/status ipsec

#验证ipsec的配置
ipsed verify

#删除/增加/启动/停止连接
ipsec auto --add/delete/up/down connect
```
## 参考连接
* [官方配置教程](https://techcommunity.microsoft.com/t5/ITOps-Talk-Blog/Step-By-Step-Connect-your-AWS-and-Azure-environments-with-a-VPN/ba-p/339211)
* [VPN配置文件样例](https://github.com/Azure/Azure-vpn-config-samples/blob/master/Openswan/ipsec.conf)
* [Azure说明-1](https://docs.azure.cn/zh-cn/vpn-gateway/vpn-gateway-about-vpn-gateway-settings#vpntype)
* [Azure说明-2](https://docs.azure.cn/zh-cn/articles/azure-operations-guide/virtual-network/aog-virtual-network-howto-connect-routebased-vpn-and-policybased-vpn)
* [libreswan](https://libreswan.org/wiki/Microsoft_Azure_configuration)
* [libreswan密钥文件配置](https://libreswan.org/man/ipsec.secrets.5.html)
* [微软官方ipsec配置要求](https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-about-vpn-devices)
* [redhat7官方文档](https://access.redhat.com/documentation/zh-cn/red_hat_enterprise_linux/7/html/security_guide/sec-Securing_Virtual_Private_Networks#sec-Host-To-Host_VPN_Using_Libreswan)