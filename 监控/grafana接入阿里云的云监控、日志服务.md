grafana 接入阿里云的云监控、日志服务

### grafana安装阿里云插件
- 云监控
- 日志服务
  - 下载插件包：wget https://github.com/aliyun/aliyun-log-grafana-datasource-plugin/archive/refs/heads/master.zip
  - 将master.zip 解压至grafana的插件目录下：cd /var/lib/grafana/plugins/ && unzip -qq ~/master.zip
  - 修改grafana配置文件：vim /etc/grafana/grafana.ini
  - 在plugins中设置allow_loading_unsigned_plugins参数。
    ```bash
    allow_loading_unsigned_plugins = aliyun-log-service-datasource,grafana-log-service-datasource
    ```
---
- [对接Grafana](https://help.aliyun.com/document_detail/109434.html?spm=5176.22414175.sslink.1.648f403fbxKBx8)
- [日志服务对接Grafana](https://help.aliyun.com/document_detail/60952.html)
- [通过Grafana插件查看监控数据](https://www.alibabacloud.com/help/zh/cloudmonitor/latest/use-grafana-to-view-the-monitoring-data)
- [云监控的指标](https://www.alibabacloud.com/help/zh/cloudmonitor/latest/appendix-1-metrics)