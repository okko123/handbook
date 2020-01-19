## Megacli软件官方下载地址
* http://docs.avagotech.com/docs/12351587?_ga=2.108700289.2001341485.1575862683-2077409313.1575862683

## MegaCLI命令列表
* https://www.broadcom.com/support/knowledgebase/1211161499760/lsi-command-line-interface-cross-reference-megacli-vs-twcli-vs-s
* https://www.alteeve.com/w/MegaCli64_Cheat_Sheet
* MegaCli是lsi磁盘阵列控制器的管理工具，MegaCli不支持SAS5、SAS6的raid卡，需要使用lsiutil.x86_64

## MegaCLI常用命令
---
### 查看控制卡的日志信息
* MegaCli64 -FwTermLog -Dsply -aALL
### 查看物理磁盘的信息
* MegaCli64 -PDList -aALL
### 查看虚拟磁盘的信息
* MegaCli64 -LDInfo -LALL -aALL
### 查看控制卡的信息
* MegaCli64 -AdpAllInfo -aALL
### 查看控制卡的BBU信息
* MegaCli64 -AdpBbuCmd -aALL
### 显示指定磁盘rebuild信息
* Megacli64 -pdrbld -progdsply -physdrv[E:S] -aALL
### 阵列一致性检查
* Megacli64 -ldcc -start -lall -aall
### Dell获取raid信息脚本
```bash
#!/bin/sh

################################################################################
#
# Copyright Li, Desheng of Dell.
#
# This script is just collect log.
#
# Author(s):
#   Li, Desheng from Technical Support Level2 Team of Dell.
#
################################################################################

echo -e "\033[40;31;5m WARNING!!!!!! \033[0m"
echo -e "\033[40;31;1m TTY Log collecting, Please wait a moment! Thanks!\033[0m"

#/usr/bin/clear

/bin/rpm -U Lib_Utils-1.00-09.noarch.rpm 2>/dev/null
/bin/rpm -U MegaCli-8.02.21-1.noarch.rpm 2>/dev/null

/bin/rm -f PERCLINUX.tgz


## Gets the hostname ##
echo " " > PERCLINUX.log
echo "Hostname:  `/bin/hostname`" >> PERCLINUX.log
#hostname >> PERCLINUX.log


## Get the Service Tag ##
echo " " >> PERCLINUX.log
echo "Service Tag: `/usr/sbin/dmidecode | grep "Serial Number" | head -n 1 | awk -F': ' '{print $2}'`" >> PERCLINUX.log
#dmidecode | grep "Serial Number" | head -n 1 | awk -F": " '{print $2}' >> PERCLINUX.log


## Gets the Version of OS ##
echo " " >> PERCLINUX.log
echo "OS bit: `/usr/bin/file /bin/ls | awk '{print $3}'`" >> PERCLINUX.log
OSBIT=`/usr/bin/file /bin/ls | awk '{print $3}'`
if [ "$OSBIT" == "64-bit" ]
then
   MegaCommand='/opt/MegaRAID/MegaCli/MegaCli64'
elif [ "$OSBIT" == "32-bit" ]
then
   MegaCommand='/opt/MegaRAID/MegaCli/MegaCli'
else
   echo "This TTY script can not support your OS!!!"
fi

## Get the Version of kernel ###


## Check Version of Operating system ##



echo "###############   TTY-log Tools for Linux   ###############" >> PERCLINUX.log

echo " " >> PERCLINUX.log

echo "------------------------   adpCount begin   ------------------------" >> PERCLINUX.log
$MegaCommand -adpCount >> PERCLINUX.log
echo "------------------------   adpCount End   ------------------------" >> PERCLINUX.log

echo " " >> PERCLINUX.log

echo "------------------------   AdpAllInfo begin   ------------------------" >> PERCLINUX.log
$MegaCommand -AdpAllInfo -aALL >> PERCLINUX.log
echo "------------------------   AdpAllInfo End   ------------------------" >> PERCLINUX.log

echo " " >> PERCLINUX.log

echo "------------------------   FwTermLog begin   ------------------------" >> PERCLINUX.log
$MegaCommand -FwTermLog -Dsply -aALL >> PERCLINUX.log
echo "------------------------   FwTermLog End   ------------------------" >> PERCLINUX.log

echo " " >> PERCLINUX.log

echo "------------------------   PDList begin   ------------------------" >> PERCLINUX.log
$MegaCommand -PDList -aALL >> PERCLINUX.log
echo "------------------------   PDList End   ------------------------" >> PERCLINUX.log

echo " " >> PERCLINUX.log

echo "------------------------   PDGetNum begin   ------------------------" >> PERCLINUX.log
$MegaCommand -PDGetNum -aALL >> PERCLINUX.log
echo "------------------------   PDGetNum End   ------------------------" >> PERCLINUX.log

echo " " >> PERCLINUX.log

echo "------------------------   EncInfo begin   ------------------------" >> PERCLINUX.log
$MegaCommand -EncInfo -aALL >> PERCLINUX.log
echo "------------------------   EncInfo End   ------------------------" >> PERCLINUX.log

echo " " >> PERCLINUX.log

echo "------------------------   LDInfo begin   ------------------------" >> PERCLINUX.log
$MegaCommand -LDInfo -Lall -aALL >> PERCLINUX.log
echo "------------------------   LDInfo End   ------------------------" >> PERCLINUX.log

echo " " >> PERCLINUX.log

echo "------------------------   LdPdInfo begin   ------------------------" >> PERCLINUX.log
$MegaCommand -LdPdInfo -aALL >> PERCLINUX.log
echo "------------------------   LdPdInfo End   ------------------------" >> PERCLINUX.log

echo " " >> PERCLINUX.log

echo "------------------------   LDGetNum begin   ------------------------" >> PERCLINUX.log
$MegaCommand -LDGetNum -aALL >> PERCLINUX.log
echo "------------------------   LDGetNum End   ------------------------" >> PERCLINUX.log

echo " " >> PERCLINUX.log

echo "------------------------   CfgDsply begin   ------------------------" >> PERCLINUX.log
$MegaCommand -CfgDsply -aALL >> PERCLINUX.log
echo "------------------------   CfgDsply End   ------------------------" >> PERCLINUX.log

echo " " >> PERCLINUX.log

echo "------------------------   CfgFreeSpaceinfo begin   ------------------------" >> PERCLINUX.log
$MegaCommand -CfgFreeSpaceinfo -aALL >> PERCLINUX.log
echo "------------------------   CfgFreeSpaceinfo End   ------------------------" >> PERCLINUX.log

echo " " >> PERCLINUX.log

echo "------------------------   EventLogInfo begin   ------------------------" >> PERCLINUX.log
$MegaCommand -AdpEventLog -GetEventLogInfo -aALL >> PERCLINUX.log
echo "------------------------   EventLogInfo End   ------------------------" >> PERCLINUX.log

echo " " >> PERCLINUX.log

echo "------------------------   Events begin   ------------------------" >> PERCLINUX.log
$MegaCommand -AdpEventLog -GetEvents -f events.log -aALL
cat events.log >> PERCLINUX.log
rm -f events.log
echo "------------------------   Events End   ------------------------" >> PERCLINUX.log

echo " " >> PERCLINUX.log

echo "------------------------   Since Shutdown begin   ------------------------" >> PERCLINUX.log
$MegaCommand -AdpEventLog -GetSinceShutdown -f sindown.log -aALL
cat sindown.log >> PERCLINUX.log
rm -f sindown.log
echo "------------------------   Since Shutdown End   ------------------------" >> PERCLINUX.log

echo " " >> PERCLINUX.log

echo "------------------------   Since Reboot begin   ------------------------" >> PERCLINUX.log
$MegaCommand -AdpEventLog -GetSinceReboot -f sinboot.log -aALL
cat sinboot.log >> PERCLINUX.log
rm -f sinboot.log
echo "------------------------   Since Reboot End   ------------------------" >> PERCLINUX.log

echo " " >> PERCLINUX.log

echo "------------------------   Include Deleted begin   ------------------------" >> PERCLINUX.log
$MegaCommand -AdpEventLog -IncludeDeleted -f deleted.log -aALL
cat deleted.log >> PERCLINUX.log
rm -f deleted.log
echo "------------------------   Include Deleted End   ------------------------" >> PERCLINUX.log

echo " " >> PERCLINUX.log

echo "########################   TTY-log End   ########################" >> PERCLINUX.log


echo "###############   Linux Operating System log   ###############" >> PERCLINUX.log

/sbin/fdisk -l > FdiskLINUX.log
echo "About fdisk output, Please read the FdiskLINUX.log."  >> PERCLINUX.log
/bin/cat /etc/fstab > FstabLinux.log
echo "About fstab output, Please read the FstabLinux.log."  >> PERCLINUX.log

/sbin/ifconfig -a > IfconfigLINUX.log
echo "About ficonfig output, Please read the FstabLinux.log."  >> PERCLINUX.log
/sbin/ip link > IPlinkLINUX.log
echo "About MAC address of NIC output, Please read the IPlinkLINUX.log."  >> PERCLINUX.log


echo "########################   Linux Operating System log   ########################" >> PERCLINUX.log

tar -czf PERCLINUX.tgz *LINUX.log /var/log/*mes* 2>/dev/null
rm -f PERCLINUX.log
rm -f CtDbg.log
rm -f CmdTool.log
rm -f FdiskLINUX.log
rm -f FstabLinux.log
rm -f IfconfigLINUX.log
rm -f IPlinkLINUX.log
rm -f MegaSAS.log

/bin/rpm -e MegaCli-8.02.21-1.noarch 2>/dev/null
/bin/rpm -e Lib_Utils-1.00-09.noarch 2>/dev/null

clear

echo " "
echo -e "\033[40;33;0m FINISH...... \033[0m"
echo -e "\033[40;32;1m PERC TTY-log Tools for Linux had collected the logs to PERCLINUX.tgz \033[0m"
echo -e "\033[40;32;1m Please send the PERCLINUX.tgz file to DELL support, thanks! \033[0m"
echo " "
```