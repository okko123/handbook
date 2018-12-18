ovirt安装记录

The oVirt platform consists of at least one node and an oVirt Engine which may be deployed in a virtual machine as Self-Hosted Engine (See the Self-Hosted Engine guide for more infromation).

部署ovirt-engine
yum install http://resources.ovirt.org/pub/yum-repo/ovirt-release42.rpm
yum -y install ovirt-engine

配置orirt-engine
engine-setup
