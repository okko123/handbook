## lvm 扩容
- LV(逻辑卷) -> VG(卷组) -> PV(物理卷)
  - 扩容物理卷；例子：/dev/sda由20G扩容至40G，需要执行pvresize /dev/sda，对PV进行扩容
  - 扩容逻辑卷；执行lvdisplay查询信息
    - LV Path：逻辑卷路径，例如/dev/vg_01/lv01。
    - LV Name：逻辑卷名称，例如lv01。
    - VG Name：逻辑卷所属的卷组名称，例如vg_01。
    - LV Size：逻辑卷的大小，图示信息为59 GiB。
  - 运行以下命令，扩容逻辑卷
    ```bash
    sudo lvextend -L <增/减逻辑卷容量> <逻辑卷路径>
    # 为逻辑卷（路径为/dev/vg_01/lv01）新增10 GiB容量
    sudo lvextend -L +10G /dev/vg_01/lv01
    ```
  - 扩容逻辑卷文件系统
    ```bash
    # ext4 文件系统
    sudo resize2fs <逻辑卷路径>

    # 以扩容逻辑卷lv01（路径为/dev/vg_01/lv01）为例
    sudo resize2fs /dev/vg_01/lv01

    # xfs文件系统
    sudo xfs_growfs <逻辑卷挂载点>

    # 以扩容逻辑卷lv01（挂载点为/media/lv01）为例，则命令为：
    sudo xfs_growfs /media/lv01
    ```
---
### 参考信息
- [扩容逻辑卷](https://help.aliyun.com/zh/ecs/use-cases/extend-an-lv-by-using-lvm#d97cb1c01am8j)