# zabbix item遇到的问题
* OS: CentOS 7
* zabbix: 4.4.3

使用模板Template OS Linux by Zabbix agent，在item中有一项Number of CPUs，用于监控CPU的数量。在此item配置项中，有Preprocessing的标签也，里面配置当数据没有变化的情况下，监控的数据是不会写进数据库中，导致主机的System load监控图中，Number of CPUs断图。每天只写入一次。这样做的原因是减轻数据库的压力。