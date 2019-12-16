* 开启NAT转发
firewall-cmd --permanent --zone=public --add-masquerade

* 端口转发SNAT
firewall-cmd  --zone=public --add-forward-port=port=80:proto=tcp:toaddr=192.168.0.101
