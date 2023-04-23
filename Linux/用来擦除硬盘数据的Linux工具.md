== 用来擦除硬盘数据的Linux工具
=== shred 命令
```bash
Shred 有许多选项：

-n - 覆盖的次数。默认是三次。
-u - 覆盖并删除。
-s - 要粉碎的字节数。
-v - 显示扩展信息。
-f - 必要时强制改变权限以允许写入。
-z - 最后用 0 覆盖来隐藏粉碎。

sudo shred -vfz /dev/sdX
```
=== dd 命令
```bash
## 如果你想在整个目标磁盘上写零，执行以下命令。这可能需要一个整个通宵。
## 警告：请确保你知道你在系统中的位置，并以正确的驱动器为目标，这样你就不会意外地删除自己的数据。
sudo dd if=/dev/urandom of=/dev/sdX bs=10M
```
=== Nvme-cli
```bash
## 如果你的计算机包含一个较新的 NVMe 驱动器，你可以安装 nvme-cli 程序，并使用 sanitize 选项来清除你的驱动器。
nvme sanitize help 命令提供了选项列表：

--no-dealloc、-d - 净化后不解除分配。
--oipbp、-i - 每次覆写后反转模式。
--owpass=、-n - 覆写次数。
--ause、-u - 允许无限制净化退出。
--sanact=、-a - 净化动作。
--ovrpat=、-p - 覆写模式。

## 这里的警告与格式化过程相同：首先备份重要的数据，因为这个命令会擦除这些数据！
sudo nvme sanitize /dev/nvme0nX
```