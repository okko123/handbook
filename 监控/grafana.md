# zabbix使用grafana展示图形
* 安装Zabbix插件；
```bash
grafana-cli plugins install alexanderzobnin-zabbix-app
service grafana-server restart
```
* 登陆web界面；访问Configuration - Plugins - Zabbix - enabled
* 配置Data Source；访问Configuration - Data Sources - Zabbix - Settings，配置以下选项后，点击Save & Test测试保存
  * zabbix 的api接口
  * zabbix的版本
  * 直连zabbix数据库（需要在grafana的Data Sources中配置MySQL数据源连接zabbix-DB）
* 配置Zabbix的Dashboards；访问Configuration - Data Sources - Zabbix - Dashboards。点击import。


## 出现Panel plugin not found: grafana-piechart-panel
- 执行grafana-cli plugins install grafana-piechart-panel，安装插件
- 重启grafana，kubectl -n monitoring rollout restart deploy grafana
[参考连接]
https://cloud.tencent.com/developer/article/1027332
https://github.com/yangcvo/Grafana
http://docs.grafana.org/features/panels/singlestat/
