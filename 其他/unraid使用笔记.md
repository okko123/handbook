## unraid使用笔记
### 使用开（po）心（jie）版
1. 下载USB Creator和unraid的压缩包（zip格式）。本次使用的版本为6.10.2
   ```bash
   wget https://craftassets.unraid.net/uploads/downloads/Unraid.USB.Creator.Win32-2.0.exe
   wget https://unraid-dl.sfo2.cdn.digitaloceanspaces.com/stable/unRAIDServer-6.10.2-x86_64.zip

   cat > unraid.md5 <<EOF
   1d76ae6d2f57447d8314606fdfbe95d5 unRAIDServer-6.10.2-x86_64.zip
   EOF

   md5sum -c unraid.md5
   ```
2. 使用USB Creator将压缩包写入U盘，并记录USB Creator中显示U盘的GUID，GUID格式为xxxx-xxxx-xxxx-xxxxxxxxx。然后运行U盘中的make_bootable.bat，写入引导启动信息
3. 使得unraid开心
```bash
# 在linux环境下，使用gcc编译开心文件
git clone https://github.com/mysll/unraid_test.git
cd unraid_test
gcc -fPIC -shared unraid.c -o BTRS.key

# 复制BTRS.key 至u盘的config目录

# 修改config/go文件，内容为
# 其中UNRAID_NAME可以随便填，UNRAID_DATE指的是注册时间，用到UNIX时间戳，不改没事，要改的话去网上找个转换的就行。注意：UNRAID_GUID、UNRAID_NAME、UNRAID_DATE 对应的就是U盘GUID、授权给谁、授权时间。后面在Unraid中能查找到相应信息。
cat > go <<EOF
export UNRAID_GUID=usb flash GUID
export UNRAID_NAME=your name
export UNRAID_DATE=unix timestamp
export UNRAID_VERSION=Pro
LD_PRELOAD=/boot/config/BTRS.key /usr/local/sbin/emhttp &
EOF
```
4. 将U盘插入的NAS服务器启动，登录后在bashboard页面看到registration为UNRAID OS Pro。说明激活成功
---
### 常用插件安装
- NerdPack: 用于安装perl工具
- Dynamix System Temperature: 显示CPU，主板温度；风扇转速
- unBALANCE: 数据迁移工具
- transmission: 下载工具
- Disk Location: 硬盘位置
---
### 参考信息
- [手动升级Unraid到最新6.10.3版本方法总结](https://post.smzdm.com/p/am8nvwed/)
- [unraid_test](https://github.com/mysll/unraid_test)
- [NAS最强攻略：使用UNRAID系统，搭建ALL IN ONE全过程！超万字教程，绝对干货！](https://zhuanlan.zhihu.com/p/152203435)