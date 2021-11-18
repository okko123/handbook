## 配置服务器远程管理卡console输出
### 戴尔服务器的idrac卡，使用 IPMI SOL 与 iDRAC 进行通信
- 针对串行连接配置 BIOS
  > 注: 这仅适用于机架和塔式服务器中的 iDRAC。
  1. 开启或重新启动系统。
  2. 按 F2。
  3. 转到 System BIOS Settings（系统 BIOS 设置） > Serial Communication（串行通信）。
  4. 指定以下值：
     - Serial Communication（串行通信）— On With Console Redirection
     - Serial Port Address（串行端口地址）— COM2。
     - 注: 如果串行端口地址字段中的串行设备 2 也设置为 com1， 么可以将串行通信字段设置为开启，通过 com1 进行串行重定向。
     - External serial connector（外部串行连接器）-- Serial device 2（串行设备 2）
     - Failsafe Baud Rate（故障保护波特率）— 115200
     - Remote Terminal Type（远程终端类型）— VT100/VT220
     - Redirection After Boot（引导后重定向）– Enabled（启用）
  5. 单击 Back（下一步），然后单击 Finish（完成）。
  6. 单击 Yes（是）以保存更改。
  7. 按 <Esc> 键退出 System Setup（系统设置）。
     - 注: BIOS 屏幕以 25 x 80 的格式发送串行数据。用于调用 console com2 命令的 SSH 窗口必须设置为 25 x 80。然后，重定向  - 的屏幕将可以正确显示。
     - 注: 如果引导加载程序或操作系统提供串行重定向（例如 GRUB 或 Linux），则 BIOS Redirection After Boot（引导后重定  - 向）设置必须禁用。这可以避免多个组件访问串行端口时潜在的争用情况。
- 配置 iDRAC 以使用 SOL；使用 iDRAC Web 界面配置 iDRAC 以使用 SOL
  - 配置 IPMI LAN 上串行 (SOL)：
  1. 在 iDRAC Web 界面中，转至 iDRAC Settings（iDRAC 设置） > Connectivity（连接） > Serial Over LAN（LAN 上串行）。随即会显示 Serial Over LAN（LAN 上串行）页面。
  2. 启用 SOL，指定各值，然后单击 Apply（应用）。IPMI SOL 设置即配置完成。
  3. 要设置字符积累间隔时间和字符发送阈值，请选择 Advanced Settings（高级设置）。随即会显示 Serial Over LAN Advanced Settings（LAN 上串行高级设置）页面。
  4. 指定各属性的值并单击 Apply（应用）。IPMI SOL 高级设置即配置完成。这些值有助于提升性能。
- 使用 IPMI 协议的 SOL
  > 基于 IPMI 的 SOL 公用程序和使用 RMCP+ 的 IPMItool 通过 UDP 数据报传输到端口 623。使用 IPMI 2.0 时，RMCP+ 提供改进的身份验证、数据完整性检查、加密以及承载多种有效载荷类型的功能。有关更多信息，请参阅 http://ipmitool.sourceforge.net/manpage.html。

  > RMCP+ 使用 40 个字符的十六进制字符串（字符 0-9、a-f 和 A-F）加密密钥进行身份验证。默认值为 40 个零组成的字符串。

  > 必须使用加密密钥（密钥生成器密钥）对 RMCP+ 与 iDRAC 的连接进行加密。您可以使用 iDRAC Web 界面或 iDRAC 设置公用程序配置加密密钥。

  > 要从 Management Station 使用 IPMItool 启动 SOL 会话：
  - 注: 如有必要，您可以通过 iDRAC 设置 > 服务更改 SOL 超时。
  1. 从 Dell Systems Management Tools and Documentation DVD 安装 IPMITool。
     > 有关安装说明，请参阅《软件快速安装指南》。
  2. 在命令提示符窗口中（Windows 或 Linux），运行以下命令以从 iDRAC 开始 SOL：
     > ipmitool -H <iDRAC-ip-address> -I lanplus -U <login name> -P <login password> sol activate
     > 该命令会将 Management Station 连接到受管系统的串行端口。
  3. 要从 IPMItool 退出 SOL 会话，按下 ~，然后按下 .（句号）。
     - 注: 如果 SOL 会话未终止，请重设 iDRAC 并等待两分钟以便完成引导。
     - 注: 从运行的 Windows 操作系统的客户端将大型输入文本复制到运行 Linux 操作系统的主机时，IPMI SOL 会话可能会终止。要避免会话突然终止，请将任何大型文本转换为基于 UNIX 的行末端。
     - 注: 如果存在使用 RACADM 工具创建的 SOL 会话，则使用 IPMI 工具启动另一个 SOL 会话时将不会显示有关现有会话的任何通知或错误。
---
用ajaxterm实现web页面查看任意服务器远程管理卡console输出
作者： siyu |   4,261 浏览  |  2013/08/27   11:23 上午

鉴于近期咨询小米如何在web端实现服务器远程管理卡console的朋友比较多。简单的写出个大概避免重复多次的介绍。
首先，你需要有基本的linux、控制卡知识
我们用到的主要工具有：ajaxterm、ipmitool、代理服务器
ajaxterm是一个web端的终端+服务器端相应的程序，简单的将他启动，默认可以将服务器的ssh连接控制台打到web的ajax控件上，这样可以满足的是用户通过web连接ssh的需求。如下图：
scr

但是这个默认的配置只打开了一个监听端口对本机（127.0.0.1开放），这时候你就需要 配置代理服务器。

以apache为例

Listen 9002

ProxyRequests off

Order allow,deny
Allow from all ProxyPass / http://localhost:8022/
ProxyPassReverse / http://localhost:8022/

这样你就可以通过远程访问来获取部署了ajaxterm和代理服务器设备的的ssh terminal。
然后，我们想将服务器的控制卡console输出打到这个ajaxterm上，该怎么做 ？
ajaxterm通过命令行启动的时候可以指定通过web访问时执行的脚本，如下
#python ajaxterm.py -c /home/shell/ipmiconsole.sh -d
我们指定运行了ipmiconsole.sh脚本，这个脚本很简单内容如下
ipmitool -U USERNAME -I lanplus -H iLOip -P Password -e ^ sol activate

这样每次你通过web访问ajaxterm的时候，ajaxterm就会运行这个脚本并将运行内容通过ajax等技术打到web页面上。当你同时打开多个web界面时，ajaxterm也会同时会多次运行这个脚本
如果你想通过多次打开web端来获得不同的服务器的控制卡console，你可以想办法在点击打开ajaxterm的同事更改ipmiconsole.sh中的iLOip
看看我们最终实现的效果
QQ图片20130827111057

ajaxterm官网：http://antony.lesuisse.org/software/ajaxterm/
---
- [idrac9 用户手册](https://www.dell.com/support/manuals/zh-cn/idrac9-lifecycle-controller-v3.3-series/idrac_3.31.31.31_ug/%E6%A6%82%E8%A7%88?guid=guid-a03c2558-4f39-40c8-88b8-38835d0e9003&lang=zh-cn)
- [用ajaxterm实现web页面查看任意服务器远程管理卡console输出](http://noops.me/?p=841)