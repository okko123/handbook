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
  EOF
  ```
