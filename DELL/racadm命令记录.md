## RACADM命令使用
### 修改BIOS
* 使用UEFI模式、开启内存测试、关闭NUMA；修改完BIOS参数后需要添加作业队列
    ```bash
    racadm set BIOS.BiosBootSettings.BootMode Uefi
    racadm set BIOS.MemSettings.MemTest Enabled
    racadm set BIOS.MemSettings.NodeInterleave Disabled
    racadm set BIOS.SysSecurity.AcPwrRcvry On
    racadm set BIOS.SysProfileSettings.SysProfile PerfOptimized

    racadm jobqueue create BIOS.Setup.1-1
    racadm serveraction powercycle
    ```

### 修改raid
* 删除raid
    ```bash
    racadm raid get status
    racadm raid deletevd:Disk.Virtual.0:RAID.Integrated.1-1

    racadm  jobqueue create RAID.Integrated.1-1
    racadm serveraction powerup
    ```
* 创建raid
  ```bash
  racadm raid get pdisks

  racadm raid createvd:RAID.Integrated.1-1 -rl r0 -wp wt -rp nra -name raid_0 -pdkey:Disk.Bay.0:Enclosure.Internal.0-1:RAID.Integrated.1-1,Disk.Bay.1:Enclosure.Internal.0-1:RAID.Integrated.1-1,Disk.Bay.2:Enclosure.Internal.0-1:RAID.Integrated.1-1,Disk.Bay.3:Enclosure.Internal.0-1:RAID.Integrated.1-1,Disk.Bay.4:Enclosure.Internal.0-1:RAID.Integrated.1-1,Disk.Bay.5:Enclosure.Internal.0-1:RAID.Integrated.1-1
  
  racadm  jobqueue create RAID.Integrated.1-1
  racadm serveraction hardreset
  ```
* 初始化raid
  ```bash
  racadm raid init:Disk.Virtual.0:RAID.Integrated.1-1 
  ```
### 修改启动配置
* 修改下次启动设备为PXE
    ```bash
    racadm set iDRAC.ServerBoot.BootOnce enabled
    racadm set iDRAC.ServerBoot.FirstBootDevice pxe
    ```
### 其他参数
```bash
#开启iDRAC的IPMI功能
racadm set iDRAC.IPMILan.Enable Enabled

#重启idrac，添加-f为强制
racadm racreset soft
racadm recreset hard

#设置failover为0，即设置failover网卡为none
racadm set iDRAC.NIC.Failover 0

#get service tag
racadm getsvctag

#get system information
racadm getsysinfo

#清理作业队列
racadm jobqueue delete -i JID_CLEARALL_FORCE
```