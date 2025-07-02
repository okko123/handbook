## parted 分区工具使用记录
```bash
parted /dev/sdb

# 创建mbr分区表
parted -s /dev/sdb mklabel msdos
# 创建gpt分区表
parted -s /dev/sdb mklabel gpt

# 创建分区
parted -s /dev/sdb mkpart primary xfs 0% 100%
```