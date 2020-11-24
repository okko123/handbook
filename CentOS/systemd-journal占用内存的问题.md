# systemd-journal占用内存的问题
## 某天开发说k8s集群不能访问，全down掉了。分别登陆到节点上进行检查，发现主节点上，
```bash
top - 10:18:04 up 121 days, 16:34,  2 users,  load average: 0.59, 0.55, 0.50
Tasks: 874 total,   2 running, 598 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.8 us,  0.4 sy,  0.0 ni, 98.7 id,  0.0 wa,  0.0 hi,  0.1 si,  0.0 st
KiB Mem : 98893936 total,  3509732 free, 77104016 used, 18280192 buff/cache
KiB Swap:        0 total,        0 free,        0 used. 15497552 avail Mem 
  PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND                                                            
 3817 root      20   0   46.3g  46.3g  21188 S   0.3 49.1   2329:35 systemd-journal                                                    
43283 ceph      20   0   12.5g   5.7g  29888 S   0.3  6.1  25448:03 java
```
## 重启systemd-journald，修改配置文件限制使用的内存量
修改配置文件/etc/systemd/journald.conf，
查看配置文件参数man 5 journald.conf
修改RuntimeMaxUse、RuntimeMaxFileSize、Storage


检查当前journal使用磁盘量

journalctl --disk-usage
清理方法可以采用按照日期清理，或者按照允许保留的容量清理

journalctl --vacuum-time=2d
journalctl --vacuum-size=500M


systemctl restart systemd-journald

- [参考链接](https://blog.steamedfish.org/posts/2019/06/systemd-journal-%E5%8D%A0%E7%94%A8%E5%86%85%E5%AD%98%E7%9A%84%E9%97%AE%E9%A2%98/)