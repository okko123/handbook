# EC2实例
- 当IOPS的超过80000，需要使用nvme的SSD实例。EC2实例单实例限制80000iops。假设使用2块64000 iops的EBS盘组Raid0后挂上EC2实例，EC2实例实际上只能使用到80000 iops。[参考连接](https://docs.aws.amazon.com/zh_cn/AWSEC2/latest/UserGuide/EBSVolumeTypes.html)
- i系列，存储型。当主机关机或终结后nvme的SSD上保存的数据就会被抹除
- 每个类型的EC2服务器，每个区域都有购买数量的限制。可以通过提交工单的方式提高限制的数量。详细请查阅文档。

# VPC
- DNS限制；每个Amazon EC2实例可以向Amazon提供的DNS服务器发送的数据包数量限制为：每个网络接口每秒最多 1024 个数据包。不能提高此限制。由Amazon提供的DNS服务器支持的每秒DNS查询数量因查询类型、响应大小和所用协议而异。有关可扩展 DNS 架构的更多信息和建议，请参阅 Amazon VPC的混合云DNS解决方案白皮书。[参考连接](https://docs.aws.amazon.com/zh_cn/vpc/latest/userguide/vpc-dns.html#vpc-dns-limits)

# S3对象存储服务
- 需要为S3桶添加桶策略。默认的下，S3不允许其他应用写入。需要修改桶策略

# cloudfront
- 使用cloudfront访问S3桶资源的时候，需要在cloudfront的源配置中修改，Restrict Bucket Access (限制存储桶访问) ，然后再更新桶策略。[参考连接](https://docs.aws.amazon.com/zh_cn/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html)
