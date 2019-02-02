## CloudWatch的单位换算
- 默认的情况下，cloudwatch网络监控使用流量单位bps，非带宽单位bit/s，因此需要自行进行转换。
- 假设10:00的数据点主机的NetworkOut为1Gbytes，监控周期为5分钟
  - 在cloudwatch的控制台上，数据统计设置为average，Metric显示的值为5个数据值之和，再除以5；换算为流量单位位应该用1*1024*8/60=136.53Mbps。当数据统计设置为sum，Metric显示的值为5个数据值之和；换算为流量单位应该用1*1024*8/(5*60)=27.3Mbps
- 假设10:00主机A的NetworkOut数据点为1Gbytes，监控周期为1分钟
  - 此时换算都为1*1024*8/60=136.53Mbps

## IOPS换算
- 假设10:00的主机A的NetworkOut数据点为1000，监控周期为5分钟
  - cloudwatch agent收集的diskio_read、diskio_write为磁盘读、写取操作数（累计值），换算iops应使用1000/300=3.3 IOPS
