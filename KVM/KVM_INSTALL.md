基于CentOS Linux release 7.4.1708 (Core) 的环境下，使用命令行方式安装KVM
目录
===
<!-- TOC -->
- [检测是否支持KVM](#检测是否支持kvm)
- [安装 KVM 环境](#安装-kvm-环境)
- [配置KVM网络](#配置KVM网络)
<!-- /TOC -->

## 检测是否支持KVM
KVM 是基于 x86 虚拟化扩展(Intel VT 或者 AMD-V) 技术的虚拟机软件，所以查看 CPU 是否支持 VT 技术，就可以判断是否支持KVM。有返回结果，如果结果中有vmx（Intel）或svm(AMD)字样，就说明CPU的支持的。

```bash
cat /proc/cpuinfo | egrep 'vmx|svm'

flags   : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf eagerfpu pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 fma cx16 xtpr pdcm pcid dca sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm arat epb pln pts dtherm tpr_shadow vnmi flexpriority ept vpid fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid cqm xsaveopt cqm_llc cqm_occup_llc
```

关闭SELinux，将 /etc/sysconfig/selinux 中的 `SELinux=enforcing` 修改为 `SELinux=disabled`

```bash
sed -i "s|=enforcing|=disabled|g" /etc/sysconfig/selinux
```

## 安装 KVM 环境

通过 [yum](https://jaywcjlove.github.io/linux-command/c/yum.html) 安装 kvm 基础包和管理工具

kvm相关安装包及其作用:
- `qemu-kvm` 主要的KVM程序包
- `python-virtinst` 创建虚拟机所需要的命令行工具和程序库
- `virt-manager` GUI虚拟机管理工具
- `virt-top` 虚拟机统计命令
- `virt-viewer` GUI连接程序，连接到已配置好的虚拟机
- `libvirt` C语言工具包，提供libvirt服务
- `libvirt-client` 为虚拟客户机提供的C语言工具包
- `virt-install` 基于libvirt服务的虚拟机创建命令
- `bridge-utils` 创建和管理桥接设备的工具

```bash
# 安装kvm和工具包
# ------------------------
# yum -y install qemu-kvm python-virtinst libvirt libvirt-python virt-manager libguestfs-tools bridge-utils virt-install

yum -y install qemu-kvm libvirt virt-install bridge-utils

# 重启宿主机，以便加载 kvm 模块
# ------------------------
reboot

# 查看KVM模块是否被正确加载
# ------------------------
lsmod | grep kvm

kvm_intel             162153  0
kvm                   525259  1 kvm_intel

```

开启kvm服务，并且设置其开机自动启动

```bash
systemctl start libvirtd
systemctl enable libvirtd
```

查看状态操作结果，如`Active: active (running)`，说明运行情况良好

```bash
systemctl status libvirtd
systemctl is-enabled libvirtd

● libvirtd.service - Virtualization daemon
   Loaded: loaded (/usr/lib/systemd/system/libvirtd.service; enabled; vendor preset: enabled)
   Active: active (running) since 二 2001-01-02 11:29:53 CST; 1h 41min ago
     Docs: man:libvirtd(8)
           http://libvirt.org
```

# 配置KVM网络
- 配置桥接网卡，[官方教程](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/networking_guide/ch-configure_network_bridging)

```bash
nmtui
systemctl restart network

#检查配置是否生效
ip addr show


brctl show

bridge name	bridge id		STP enabled	interfaces
br0		8000.92d7de4eea27	yes		em1

```

- kvm虚拟化环境安装好后，ifconfig会发现多了一个虚拟网卡virbr0。这是由于安装和启用了libvirt服务后生成的，libvirt在服务器（host）上生成一个 virtual network switch (virbr0)，host上所有的虚拟机（guests）通过这个 virbr0 连起来。默认情况下 virbr0 使用的是 NAT 模式（采用 IP Masquerade），所以这种情况下 guest 通过 host 才能访问外部。

```bash
#使用brctl检查桥接网卡
brctl show

#virsh检查网络配置
virsh net-list

 Name                 State      Autostart     Persistent
----------------------------------------------------------
 default              active     yes           yes

#关闭virbr0网卡
#net-destroy
virsh net-destroy default

#net-undefine
virsh net-undefine default

#执行virsh net-list显示如下结果，即为成功：
 Name                 State      Autostart     Persistent
----------------------------------------------------------

#重启libvirtd让设置生效
systemctl restart libvirtd
```
