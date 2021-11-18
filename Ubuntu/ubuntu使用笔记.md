### ubuntu 使用笔记
- 设置时区：timedatectl set-timezone Asia/Shanghai
- 设置24小时的时间格式：localectl set-locale LC_TIME=C.UTF-8
- iso写入U盘：dd if=xxx.iso of=/dev/sda bs=4M。
方法2：dd工具可以响应USR1的信号，当收到此信号时，dd命令会向终端输出此时的进度信息。

当将dd开始运行后，再打开一个终端窗口，输入：

方法一：
watch -n 5 pkill -USR1 ^dd$
方法二：
watch -n 5 killall -USR1 dd
方法三：
while killall -USR1 dd; do sleep 5; done