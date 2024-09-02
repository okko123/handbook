## AWS上对EBS进行扩容
分为以下三个步骤：

1. 扩容使用中的 EBS 卷，使用lsblk检查EBS卷是否扩容成功
   ![](img/ebs-1.png)
2. 扩容分区
   ```bash
   # 格式：growpart diskname part
   growpart /dev/xvda 1
   ```
   ![](img/ebs-2.png)
3. 扩容文件系统
   ```bash
   resize2fs /dev/xvda1

   # xfs
   xfs_growfs /mnt
   ```
   ![](img/ebs-3.png)
## 参考信息
- [Amazon EBS弹性卷修改实践](https://aws.amazon.com/cn/blogs/china/amazon-ebs-elastic-volumes/)
- [扩容分区和文件系统（Linux）](https://help.aliyun.com/zh/ecs/user-guide/extend-the-partitions-and-file-systems-of-disks-on-a-linux-instance?spm=a2c4g.11186623.0.0.b50f714aToPqbW#50557f971a1aj)