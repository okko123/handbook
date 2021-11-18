* 开启NAT转发
firewall-cmd --permanent --zone=public --add-masquerade

* 端口转发SNAT
firewall-cmd  --zone=public --add-forward-port=port=80:proto=tcp:toaddr=192.168.0.101

* 配置代理
1. Change zones for interfaces.
   ```bash
   # show current setting
   [root@dlp ~]# firewall-cmd --get-active-zone
   public
     interfaces: eth0 eth1

   # change zone
   [root@dlp ~]# nmcli c mod eth0 connection.zone internal
   [root@dlp ~]# nmcli c mod eth1 connection.zone external
   [root@dlp ~]# firewall-cmd --get-active-zone
   internal
     interfaces: eth0
   external
     interfaces: eth1
   ```
2. Set IP Masquerading on External zone.
   ```bash
   # set IP Masquerading
   [root@dlp ~]# firewall-cmd --zone=external --add-masquerade --permanent
   success
   [root@dlp ~]# firewall-cmd --reload
   success
   # show setting
   [root@dlp ~]# firewall-cmd --zone=external --query-masquerade
   yes
   # ip_forward is enabled automatically if masquerading is enabled.
   [root@dlp ~]# cat /proc/sys/net/ipv4/ip_forward
   1
   ```
3. For exmaple, Configure that outgoing packets through the Server from Internal network(10.0.0.0/24) are allowed and forwarded to External side.
   ```bash
   # set masquerading to internal zone
   [root@dlp ~]# firewall-cmd --zone=internal --add-masquerade --permanent
   success
   [root@dlp ~]# firewall-cmd --reload
   success
   [root@dlp ~]# firewall-cmd --direct --add-rule ipv4 nat POSTROUTING 0 -o eth1 -j    MASQUERADE
   [root@dlp ~]# firewall-cmd --direct --add-rule ipv4 filter FORWARD 0 -i eth0 -o    eth1 -j ACCEPT
   [root@dlp ~]# firewall-cmd --direct --add-rule ipv4 filter FORWARD 0 -i eth1 -o    eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
   ```