基于CentOS Linux release 7.4.1708 (Core) 的环境下，使用dnsmasq构建PXE安装环境
===
<!-- TOC -->
- [准备工作](#准备工作)
- [部署dnsmasq](#部署dnsmasq)
- [为使用BIOS的客户端配置PXE启动文件](#为使用BIOS的客户端配置PXE启动文件)
- [为使用EFI的客户端配置PXE启动文件](为使用EFI的客户端配置PXE启动文件)
- [配置ks自动安装脚本](配置ks自动安装脚本)

<!-- /TOC -->

## 准备工作
```bash
yum install dnsmasq system-config-kickstart syslinux -y
```
- system-config-kickstart #图形化界面下调整ks的配置文件
- syslinux #获取pxelinux.0引导文件
- dnsmasq #dhcp、tftp服务
- CentOS7 ISO文件

## 部署dnsmasq
```bash
#修改dnsmasq的配置文件
cat > /etc/dnsmasq.conf <<'EOF'
port=0
interface=enp0s3
bind-interfaces
dhcp-range=10.10.0.100,10.10.0.150,12h
dhcp-host=52:54:00:6b:88:a0,10.10.0.50,infinite,svr1

pxe-prompt="Press F8 or Enter key for menu.", 60

dhcp-match=set:Intel_x86PC,option:client-arch,0
dhcp-boot=tag:Intel_x86PC,pxelinux.0

dhcp-match=set:EFI_BC,option:client-arch,7
dhcp-boot=tag:EFI_BC,uefi/BOOTX64.EFI

enable-tftp
tftp-root=/var/lib/tftpboot
conf-dir=/etc/dnsmasq.d,.rpmnew,.rpmsave,.rpmorig
EOF

#启动dnsmasq
systemctl start dnsmasq
#通过日志检查dnsmasq的启动情况
journalctl -xe
```

## 为使用BIOS的客户端配置PXE启动文件
- 创建目录
```bash
mkdir -p /var/lib/tftpboot/{OS7,KS,pxelinux.cfg}
```
- 复制引导文件
```bash
cp /path/to/x86_64/os/images/pxeboot/{vmlinuz,initrd.img} /var/lib/tftpboot/OS7
cp /usr/share/syslinux/pxelinux.0 /var/lib/tftpboot/
cp /usr/share/syslinux/vesamenu.c32 /var/lib/tftpboot/
```
- 添加引导文件
```bash
#inst.repo= Anaconda 选项指定安装程序映象及安装源。没有这个选项安装程序就无法引导。
cat > /var/lib/tftpboot/pxelinux.cfg/default <<'EOF'
default vesamenu.c32
timeout 100 #时间单位为1/10秒
label linux
    menu label ^Install system
    menu default
    kernel vmlinuz
    append initrd=initrd.img ip=dhcp inst.repo=http://10.10.0.50
label vesa
    menu label Install system with ^basic video driver
    kernel vmlinuz
    append initrd=initrd.img ip=dhcp inst.xdriver=vesa nomodeset inst.repo=http://10.10.0.50/OS7
label vesa
    menu label Install system with ^basic video driver
    kernel vmlinuz
    append initrd=initrd.img ip=dhcp inst.xdriver=vesa nomodeset inst.repo=http://10.10.0.50/OS7 inst.ks=http://10.10.0.50/KS/ks.cfg
label rescue
    menu label ^Rescue installed system
    kernel vmlinuz
    append initrd=initrd.img rescue
label local
    menu label Boot from ^local drive
    localboot 0xffff
EOF
```
## 为使用EFI的客户端配置PXE启动文件
- 创建目录
```bash
mkdir -p /var/lib/tftpboot/{uefi}
```
- 复制引导文件
```bash
#现在您需要 shim 软件包中的 shim.efi 文件，以及 ISO 映像文件中 grub2-efi 软件包的 grubx64.efi 文件
rpm2cpio shim-version-architecture.rpm | cpio -dimv
rpm2cpio grub2-efi-version-architecture.rpm | cpio -dimv
cp publicly_available_directory/boot/efi/EFI/redhat/shim.efi /var/lib/tftpboot/uefi/
cp publicly_available_directory/boot/efi/EFI/redhat/grubx64.efi /var/lib/tftpboot/uefi/
cp /path/to/x86_64/os/images/pxeboot/{vmlinuz,initrd.img} /var/lib/tftpboot/uefi
```
- 添加引导文件
```bash
cat > /var/lib/tftpboot/grub.cfg <<'EOF'
set timeout=10
menuentry 'CentOS 7' {
    linuxefi uefi/vmlinuz ip=em1:dhcp inst.xdriver=vesa nomodeset inst.repo=http://10.10.0.50/OS7 inst.ks=http://10.10.0.50/KS/ks-efi.cfg
    initrdefi uefi/initrd.img
}
EOF
```
## 配置ks自动安装脚本
- 在安装图形界面的环境下，执行system-config-kickstart,配置ks文件
- 当package selection显示«Package selection is disabled due to problems downloading package information.
```bash
修改/usr/share/system-config-kickstart/packages.py，约161行
repoorder = ["rawhide", "development", "fedora"]修改为
repoorder = ["rawhide", "development", "fedora", "base"]
再启动system-config-kickstart
```

## 参考文章
- [PXE引导选项](https://access.redhat.com/documentation/zh-cn/red_hat_enterprise_linux/7/html/installation_guide/chap-anaconda-boot-options#sect-boot-options-installer)
- [PXE引导文件配置](https://access.redhat.com/documentation/zh-cn/red_hat_enterprise_linux/7/html/installation_guide/chap-installation-server-setup)
- [DNSMASQ PXE with BIOS and UEFI 1](https://serverfault.com/questions/829068/trouble-with-dnsmasq-dhcp-proxy-pxe-for-uefi-clients)
- [DNSMASQ PXE with BIOS and UEFI 2](https://wiki.fogproject.org/wiki/index.php?title=ProxyDHCP_with_dnsmasq#Install_dnsmasq_on_CentOS_7)
