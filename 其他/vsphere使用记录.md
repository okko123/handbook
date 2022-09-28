## vsphere使用记录
### 更新nvme驱动
- 在6.7U2更新时，由于ESXi遵照了NVMe 1.3 规范去识别和支持设备，某些消费级别的NVMe因为不支持该规范而无法被ESXi识别并使用。可以通过nvme驱动降级的方法，让ESXI重新识别nvme硬盘
  1. 下载ESXi 6.5U2 的ISO镜像，将根目录下的NVME.V00复制出来
  2. 将NVME.V00重命名为NVME_PCI.V00
  3. 将NVME_PCI.V00复制到ESXi 7.0.3的ISO中
  4. 将ISO写入U盘
- 视频参考信息: [ESXI7.0以上版本不识别老协议NMVE固态的解决方法](https://www.youtube.com/watch?v=17Z17fdyy6c)
---
### 安装vcsa
- 使用cli方式安装vcsa（版本为7.0.3）
  1. 下载vcsa的iso；体积约8G；VMware-VCSA-all-7.0.3-20395099.iso
  2. 在linux系统（ubuntu-22.04）下，启动安装
```bash
mount VMware-VCSA-all-7.0.3-20395099.iso /mnt
cd /mnt/vcsa-cli-installer/templates/install
cp embedded_vCSA_on_ESXi.json /tmp/embedded_vCSA_on_ESXi.json

# 修改esxi配置（hostname、password、datastore）、修改network配置（ip、prefix、gateway、dns_servers）、修改OS配置、修改sso配置
vim /tmp/embedded_vCSA_on_ESXi.json

cd /mnt/vcsa-cli-installer/lin64

# 仅执行基本模板验证和 OVF Tool 参数验证。不部署设备。
./vcsa-deploy install --accept-eula --acknowledge-ceip --precheck-only /tmp/embedded_vCSA_on_ESXi.json

# 安装
./vcsa-deploy install --accept-eula --acknowledge-ceip /tmp/embedded_vCSA_on_ESXi.json
```

- [vCenter Server Appliance 的 CLI 部署](https://docs.vmware.com/cn/VMware-vSphere/7.0/com.vmware.vcenter.install.doc/GUID-C17AFF44-22DE-41F4-B85D-19B7A995E144.html)
- [CLI 部署命令的语法](https://docs.vmware.com/cn/VMware-vSphere/7.0/com.vmware.vcenter.install.doc/GUID-15F4F48B-44D9-4E3C-B9CF-5FFC71515F71.html)
---
### vsphere / vcsa(vcenter)的许可
```bash
# VMware vCenter 7.0 Standard
104HH-D4343-07879-MV08K-2D2H2
410NA-DW28H-H74K1-ZK882-948L4
406DK-FWHEH-075K8-XAC06-0JH08

# VMware vSphere ESXi 7.0 Enterprise Plus
JJ2WR-25L9P-H71A8-6J20P-C0K3F
HN2X0-0DH5M-M78Q1-780HH-CN214
JH09A-2YL84-M7EC8-FL0K2-3N2J2
JA0W8-AX216-08E19-A995H-1PHH2
JU45H-6PHD4-481T1-5C37P-1FKQ2
1U25H-DV05N-H81Y8-7LA7P-8P0N4
HV49K-8G013-H8528-P09X6-A220A
1G6DU-4LJ1K-48451-3T0X6-3G2MD
5U4TK-DML1M-M8550-XK1QP-1A052
```