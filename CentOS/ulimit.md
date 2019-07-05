# ulimit问题
## 系统CentOS6。故障表现：在/etc/rc.local，配置开机启动DBPROXY。重启服务器后，DBPROXY实例的max open files限制为1024，并没有加载系统修改后的ulimit值
```bash
cat /proc/pid/limits
Limit                     Soft Limit           Hard Limit           Units       
Max open files            1024                 65536                files       
```
## 从搜索引擎查找到答案：/etc/security/limits.conf 是 pam_limits.so 的配置文件，一般只有在“登录”的时候才执行，用于从(login/sshd)+pam_limits.so 的 root 身份降级到普通用户之前，设置好 rlimits。而从/etc/rc.local启动应用，根本就没有登录这个动作。导致引用启动使用默认的限制

# 补充知识
## ulimit -n控制进程级别能够打开的文件句柄的数量, 而max-file表示系统级别的能够打开的文件句柄的数量。file-nr中的三个值表示已分配文件句柄的数量，已分配但未使用的文件句柄的数量以及最大文件句柄数。 Linux 2.6总是报告0作为空闲文件句柄的数量 - 这不是错误，它只是意味着分配的文件句柄数与使用的文件句柄数完全匹配。
```bash
# cat /proc/sys/fs/file-max  
397697
# cat /proc/sys/fs/file-nr       
6880	0	397697  
# lsof | wc -l
```