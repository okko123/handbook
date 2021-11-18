# ulimit问题
## 问题表现
* 在系统CentOS6。故障表现：在/etc/rc.local，配置开机启动DBPROXY。重启服务器后，DBPROXY实例的max open files限制为1024，并没有加载系统修改后的ulimit值。
## 排除过程
* 检查进程id 为 1 的ulimit值，发现dbproxy进程的limit值是由进程id 为 1 来继承
  ```bash
  cat /proc/1/limits
  Limit                     Soft Limit           Hard Limit           Units     
  Max open files            1024                 4096                 files     
  ```
* 使用ssh登录后，重启dbproxy进程。dbproxy就会继承当前session的ulimit的设置。检查dbproxy进程的limit
  ```bash
  cat /proc/PID/limits
  Limit                     Soft Limit           Hard Limit           Units      
  Max processes             65536                65536                processes  
  ```
## 分析
* 在命令行由用户启动的进程，他会继承当前shell环境的ulimit。当前的ulimit值会覆盖父进程的ulimit值。
* 在systemd、/etc/rc.local启动，他会继承systemd配置的ulimit值，没有配置的情况下，使用默认配置soft 1024 / hard 4096
* 如果发现有其他进程的limits配置不对，那么首先查看一下这个进程是如何被启动的，向上追述。 通常，通过任何手段登陆进系统之后手动启动的进程，都会应用pam_limits.so （至少Debian/Ubuntu默认配置如此）， 如果没有被应用，那么检查/etc/pam.d/中的配置。 对于非手动启动的进程，那么通常会使用某种init system （最常见的是upstart、sysvinit、systemd）启动，参考相应工具的文档即可。
* 每个进程的 limit 初始值来源，要么来自它的父进程，要么是来自 PAM，其中 PAM 的优先级更高，只要抓住这两点，问题都不复杂。

## 持久化 max open file 配置
* 用户级配置，操作系统中，提供了一套用来配置各用户(组)的资源限制的方式，配置文件在：
  ```bash
  /etc/security/limits.conf
  /etc/security/limits.d/*
  ```
* 进程级配置，对于那些直接运行在主用户或 root 用户下的进程，直接修改对应用户的配置也是可以的，不过算不上优雅。同时，在自己封装一些服务的安装包或者安装脚本的时候，必须考虑各种可能的运行环境，还必须尽量少的影响用户自己的环境设置，这就必须考虑做进程级的资源限制配置了。
  * 使用systemd启动进程的修改方法：
    ```bash
    /etc/systemd/system.conf
    /etc/systemd/user.conf
    /etc/systemd/<systemd_unit>/override.conf
    ```
  * 使用sysvinit启动进程的修改方法：
    ```bash
    cat > /etc/initscript <<EOF
    ulimit -Hn 65536
    ulimit -Sn 65536
    ulimit -Hu 65536
    ulimit -Su 65536
    EOF
    ```
  * 使用upstart启动进程的修改方式：
    ```bash
    cat > /etc/init/rc.override <<EOF
    limit nporc 65536 65536
    limit nofile 65536 65536
    EOF
    ```
## 补充知识
---
* 如何确认一个应用有没有使用了 PAM 。 检查 /etc/pam.d/ 下面的文件，有没有对应的应用配置
* 如何确认当前系统是 SysVinit 还是 Systemd
  ```bash
  #systemd
  [root@hostname ~]# stat --printf '%N\n' /proc/1/exe
  '/proc/1/exe' -> '/usr/lib/systemd/systemd'

  #upstart
  [root@hostname ~]# stat --printf '%N\n' /proc/1/exe
  '/proc/1/exe' -> '/sbin/init'
  [root@hostname ~]# /sbin/init --version
  init (upstart 0.6.5)
  Copyright (C) 2010 Canonical Ltd.

  This is free software; see the source for copying conditions.  There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR
  PURPOSE.

  #sysvinit
  ```
* 如何在线修改一个进程的 limit 值，例如当我们发现 sshd 的 max open file 配置有问题，但我们又不想重启该服务，可以使用 prlimit 命令来在线调整
  ```bash
  #当前 ssh  登录后的 max open file
  root@mbp:~$ ssh myhost
  root@hostname:~$ ulimit -n -S
  1024
  root@hostname:~$ ulimit -n -H
  1024
  root@hostname:~$ grep 'Max open files' /proc/`pgrep -f '/usr/sbin/sshd'`/limits
  Max open files            1024                 1024                 files
  #在线调整 max open file
  root@hostname:~# pgrep -f '/usr/sbin/sshd'
  523
  root@hostname:~# prlimit --pid=523 --nofile=1000000
  #重新登录检查
  root@mbp:~$ ssh myhost
  root@hostname:~# ulimit -n -S
  1000000
  root@hostname:~# ulimit -n -H
  1000000
  root@hostname:~# pgrep -f '/usr/sbin/sshd'
  523
  root@hostname:~# prlimit --pid=523 | grep NOFILE
  NOFILE     max number of open files             1000000   1000000
  ```
* /etc/security/limits.conf、/etc/security/limits.d/*.conf 是 pam_limits.so 的配置文件，一般只有在“登录”的时候才执行，用于从(login/sshd)+pam_limits.so 的 root 身份降级到普通用户之前，设置好 rlimits。而从/etc/rc.local启动应用，根本就没有登录这个动作。导致引用启动使用默认的限制。解决建议修改/etc/  initscript文件，在/etc/initscript中添加
  ```bash
  cat >> /etc/initscript<<EOF
  ulimit -SHn 65536
  ulimit -SHu 65536
  EOF
  ```
* ulimit -n控制进程级别能够打开的文件句柄的数量, 而max-file表示系统级别的能够打开的文件句柄的数量。file-nr中的三个值表示已分配文件句柄的数量，已分配但未使用的文件句柄的数量以及最大文件句柄数。 Linux 2.6总是报告0作为空闲文件句柄的数量 - 这不是错误，它只是意味着分配的文件句柄数与使用的文件句柄数完全匹配。
  ```bash
  cat /proc/sys/fs/file-max  
  397697
  cat /proc/sys/fs/file-nr       
  6880	0	397697  
  cat /proc/sys/fs/nr_open
  1048576
  ```

## file-max, nr_open, nofile之间的关系
* file-max: 所有进程打开的文件描述符数，使用/proc/sys/fs/file-nr检查当前分配的文件句柄数
* nr_open: 单个进程可分配的最大文件数，默认值为1024*1024(1048576)
* nofile: 限制登录用户的资源限制

## 调整最大进程数
* 使用cat /proc/sys/kernel/pid_max来查看系统中可创建的进程数实际值

## 参考连接
---
* [参考链接1](https://linux.die.net/man/5/initscript)
* [limit说明](https://onebitbug.me/2014/06/23/setting-limit-in-linux/)
* [ubuntu说明](http://upstart.ubuntu.com/wiki/Stanzas#limit)
* [管理好你的资源，ulimit 疑难杂症详解](https://mp.weixin.qq.com/s?__biz=MzA4Nzg5Nzc5OA==&mid=2651683275&idx=1&sn=914d588fee463edde4b939a5eed8a130&chksm=8bcbba62bcbc3374a3d3b236265d6399fbb18731fa67360561d0df9eeb79e28df9e3260a852d&scene=126&sessionid=1587350271&key=c90959eb7434e3d3b5b2abd54c66d476d7b6717440c1e7520f836bfece69ee2dbb2a736a5bc0904cc8fd4d290fedf1285632d0be8d63b29fed43763f9caf43755369b8f44224ff233e7bf27aba912a3f&ascene=1&uin=MTA4OTc2MDM4MQ%3D%3D&devicetype=Windows+10&version=62080074&lang=zh_CN&exportkey=A4QyUooKXh8sCJlu9Phj4fI%3D&pass_ticket=jbZ87C5qTEpp1lSMDfG8LK%2BMOs0YERnMTA%2FYBZ6zfjyKLDwHscRxRrjP8FhrT2s6)
* [资源限制(RLIMIT_NOFILE)的调整细节及内部实现](https://wweir.cc/post/%E8%B5%84%E6%BA%90%E9%99%90%E5%88%B6rlimit_nofile%E7%9A%84%E8%B0%83%E6%95%B4%E7%BB%86%E8%8A%82%E5%8F%8A%E5%86%85%E9%83%A8%E5%AE%9E%E7%8E%B0/)