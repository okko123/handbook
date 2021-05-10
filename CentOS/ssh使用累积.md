## ssh命令proxycommand，用于解决使用跳板机访问内网机器的问题。server b为跳板机、server c为内网机器。正常情况下需要登陆B，再通过B登陆C

* 背景介绍:</br>
有一台机器A，欲与机器C建立SSH连接，但由于隔离限制（比如“存在防火墙”）该SSH连接不能直接建立。只能先登录B，在B上登陆C
  ```bash
  +-----+     +----------+
  | you | --> | server-A |
  +-----+     +----------+

  +----------+     +----------+
  | server-A | --> | server-B |
  +----------+     +----------+
  ```

* 通过使用ssh的proxycommand实现A直接登陆C，实际上ssh自动完成与A的连接，然后在A上与B再建立新的ssh连接
  ```bash
  +-----+     +----------+     +----------+
  | you | --> | server-A | --> | server-B |
  |     |   ===ssh-tunnel===   |          |
  +-----+     +----------+     +----------+

  ```

* 修改本机~/.ssh/config配置文件，文件的mode为600
  ```bash
  cat > ~/.ssh/config <<EOF
  Host server-A
      HostName 192.168.0.10
      User root
      Port 22
      IdentityFile ~/.ssh/id_rsa

  Host server-B
      HostName 192.168.0.11
      User root
      Port 22
      IdentityFile ~/.ssh/id_rsa
      ProxyCommand ssh -W %h:%p server-b

  Host bastion
      User                   ec2-user
      HostName               ###.###.###.###
      ProxyCommand           none
      IdentityFile           /path/to/ssh/key.pem
      BatchMode              yes
      PasswordAuthentication no
  
  Host *
      ServerAliveInterval    60
      TCPKeepAlive           yes
      ProxyCommand           ssh -q -A ec2-user@###.###.###.### nc %h %p
      ControlMaster          auto
      ControlPath            ~/.ssh/mux-%r@%h:%p
      ControlPersist         8h
      User                   ansible
      IdentityFile           /path/to/ssh/key.pem
  EOF
  ```
## 使用ssh建立隧道
* ssh使用的参数说明
  ```bash
    -C  压缩数据传输
    -f  后台登录用户名密码
    -N  不执行shell[与 -g 合用]
    -g  允许打开的端口让远程主机访问
    -L  本地端口转发
    -R  远程端口转发
    -p  ssh 端口
  ```
* 本地端口转发：有时，绑定本地端口还不够，还必须指定数据传送的目标主机，从而形成点对点的"端口转发"。为了区别后文的"远程端口转发"，我们把这种情况称为"本地端口转发"（Local forwarding）。 假定host1是本地主机，host2是远程主机。由于种种原因，这两台主机之间无法连通。但是，另外还有一台host3，可以同时连通前面两台主机。因此，很自然的想法就是，通过host3，将host1连上host2。 我们在host1执行下面的命令
  ```bash
  ssh -CfNgL host1:port:host2:port host3
  ssh -CfNgL 1.2.3.4:8888:192.168.0.120:443 root@192.168.0.50 -p 22
  ```
  命令中的L参数一共接受三个值，分别是"本地端口:目标主机:目标主机端口"，它们之间用冒号分隔。这条命令的意思，就是指定SSH绑定本地端口8888，然后指定host3将所有的数据，转发到目标主机host2的443端口（假定host2运行WEB，默认端口为443）。 这样一来，我们只要连接host1的8888端口，就等于连上了host2的443端口。

  ## 如何保持持久的SSH链接
  用ssh链接服务端，一段时间不操作或屏幕没输出（比如复制文件）的时候，会自动断开 解决：（2种办法）
  1. 在客户端配置
     ```bash

     ```
  2. 在服务端配置