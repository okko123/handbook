## 阿里云OSS工具使用
### ossutil工具
- 列出桶 / 目录的文件夹：ossutil ls oss://bucket-name/ -d
- 统计某个目录的大小：ossutil du  oss://bucket-name/doc1/ --all-versions --block-size GB
- 获取桶的生命周期配置：ossutil lifecycle --method get oss://bucket-name
---
## 参考信息
- [lifecycle（生命周期）](https://help.aliyun.com/document_detail/122574.html)