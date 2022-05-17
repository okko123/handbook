## ceph手工部署指北
---
> 系统使用Ubuntu 20.04，安装Octopus（v15.2.16）版本的ceph
> 集群信息

|IP|主机名|角色|
|-|-|-|
|192.168.0.1|ceph01|mon|
|192.168.0.2|ceph02|mon|
|192.168.0.3|ceph03|mon|
|192.168.0.4|ceph04|osd|
|192.168.0.5|ceph05|osd|
|192.168.0.6|ceph06|osd|

### 对系统进行初始化，并安装软件
```bash
timedatectl set-timezone Asia/Shanghai
sed -i "s@http://.*archive.ubuntu.com@http://repo.huaweicloud.com@g" /etc/apt/sources.list
sed -i "s@http://.*security.ubuntu.com@http://repo.huaweicloud.com@g" /etc/apt/sources.list
wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -

# 对于 Octopus 和更高版本，您还可以为特定版本 x.y.z 配置存储库。
echo deb http://mirrors.ustc.edu.cn/ceph/debian-octopus/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list
apt update
apt-get install ca-certificates -y
apt install ceph ceph-mds
```
### 初始化monitor
```bash
touch /etc/ceph/ceph.conf
cat >> /etc/ceph/ceph.conf <<EOF
[global]
fsid = `uuidgen`
public network = 192.168.0.0/24

auth cluster required = cephx
auth service required = cephx
auth client required = cephx
osd journal size = 1024
osd pool default size = 3
osd pool default min size = 2
osd pool default pg num = 333
osd pool default pgp num = 333
osd crush chooseleaf type = 1

[mon]
mon initial members = ceph01
mon host = ceph01,ceph02,ceph03
mon addr = 192.168.0.1,192.168.0.2,192.168.0.3

[mon.ceph01]
host = ceph01
mon addr = 192.168.0.1
EOF

# 创建密钥
sudo ceph-authtool --create-keyring /tmp/ceph.mon.keyring --gen-key -n mon. --cap mon 'allow *'

sudo ceph-authtool --create-keyring /etc/ceph/ceph.client.admin.keyring --gen-key -n client.admin --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow *' --cap mgr 'allow *'

sudo ceph-authtool --create-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring --gen-key -n client.bootstrap-osd --cap mon 'profile bootstrap-osd' --cap mgr 'allow r'

sudo ceph-authtool /tmp/ceph.mon.keyring --import-keyring /etc/ceph/ceph.client.admin.keyring
sudo ceph-authtool /tmp/ceph.mon.keyring --import-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring

sudo chown ceph:ceph /tmp/ceph.mon.keyring

# 使用主机名、主机 IP 地址和 FSID 生成监视器映射。 将其保存为 /tmp/monmap
# monmaptool --create --add {hostname} {ip-address} --fsid {uuid} /tmp/monmap
sudo monmaptool --create --add ceph01 192.168.0.1 --fsid a7f64266-0894-4f1e-a635-d0aeaca0e993 /tmp/monmap

# 在monitor主机上创建一个默认数据目录（或多个目录）。
# sudo mkdir /var/lib/ceph/mon/{cluster-name}-{hostname}
sudo -u ceph mkdir /var/lib/ceph/mon/ceph-ceph01

# 使用monitor map和monitor key初始化monitor
# sudo -u ceph ceph-mon [--cluster {cluster-name}] --mkfs -i {hostname} --monmap /tmp/monmap --keyring /tmp/ceph.mon.keyring

sudo -u ceph ceph-mon --mkfs -i node1 --monmap /tmp/monmap --keyring /tmp/ceph.mon.keyring

# 启动monitor
sudo systemctl start ceph-mon@ceph01

# 验证monitor的运行情况
ceph -s
```
### 添加monitor节点 
> 将ceph01节点上/etc/ceph目录下的ceph.conf和ceph.client.admin.keyring文件，复制到ceph02、ceph03的节点，
```bash
ssh {node}
sudo -u ceph mkdir -p /var/lib/ceph/mon/ceph-ceph02 /tmp/ceph02
cat >> /etc/ceph/ceph.conf <<EOF
[mon.ceph02]
mon_addr = 192.168.0.2:6789
host = ceph02
EOF

# 从ceph集群中提取密钥环信息
ceph auth get mon. -o /tmp/ceph02/monkeyring
# 从ceph集群中获取monitor map信息
ceph mon getmap -o /tmp/ceph02/monmap

# 使用密钥和已有的monmap，构建一个新的monitor
sudo -u ceph ceph-mon --mkfs -i node1 --monmap /tmp/monmap --keyring /tmp/ceph.mon.keyring

# 添加新的monitor到集群中
ceph mon add ceph02 192.168.0.2:6789

# 启动服务
systemctl start ceph-mon@ceph02

# 验证monitor的运行情况
ceph -s
```
---
### 添加mgr
```bash
name="foo"
sudo -u ceph mkdir -p /var/lib/ceph/mgr/ceph-foo
ceph auth get-or-create mgr.$name mon 'allow profile mgr' osd 'allow *' mds 'allow *' > /var/lib/ceph/mgr/ceph-foo/keyring
chown -R ceph.ceph /var/lib/ceph/
ceph-mgr -i $name
```
---
### 创建osd
> 将ceph01节点上的/etc/ceph/ceph.conf、/var/lib/ceph/bootstrap-osd/ceph.keyring的配置文件，复制到当前的osd的节点上
```bash
sudo ceph-volume lvm create --data /dev/hdd1

# 检查osd的状态
ceph -s
ceph osd tree
ceph osd df
```
---
### 开启ceph-mgr-dashboard
```bash
ceph mgr module enable dashboard
ceph config set mgr mgr/dashboard/ssl false
ceph config set mgr mgr/dashboard/server_addr 0.0.0.0
ceph mgr services
```
## 设置用户与密码
echo 123@456Admin > pass.txt
ceph dashboard ac-user-create admin -i pass.txt administrator
---
### 清理磁盘信息
dd if=/dev/zero of=/dev/sdb bs=512K count=1
reboot
wipefs -a /dev/sdb

---
- [apt install ceph](https://docs.ceph.com/en/quincy/install/get-packages/)
- [CEPH RELEASES (INDEX)](https://docs.ceph.com/en/quincy/releases/index.html)
- [CEPH DASHBOARD](https://docs.ceph.com/en/octopus/mgr/dashboard/)
- [CEPH-MGR ADMINISTRATOR’S GUIDE](https://docs.ceph.com/en/octopus/mgr/administrator/#mgr-administrator-guide)
- [How to test RBD and CephFS plugins with Kubernetes 1.14+](https://github.com/ceph/ceph-csi/tree/release-v3.6/examples)