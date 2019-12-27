elasticsearch 启动流程

<!-- TOC -->
- [启动脚本执行](#启动脚本执行)
- [解析配置](#解析配置)
- [启动keepalive线程](启动keepalive线程)
<!-- /TOC -->
## 启动脚本执行
org.elasticsearch.bootstrap.Elasticsearch start
如果有-d参数，添加： <&- & 关闭标准输入并后台运行。
主线程执行的启动流程大概做了三部分工作：加载配置、检查外部环境和内部环境、初始化内部资源。最后启动各个子模块和keepalive线程

## 解析配置
包括命令行参数、主配置文件，log配置文件

## 启动keepalive线程

## 启动流程图
```flow
st=>start: Start
e=>end: 启动系统

op1=>operation: 解析配置|past
op2=>operation: 启动用户线程|current
op3=>operation: 初始化运行环境|current
op4=>operation: JVM client模式检测|current
op5=>operation: JVM版本检查|current
op6=>operation: 是否进入安全模式
op7=>operation: 是否启用mlockall
op7=>operation: 初始化Probes
op8=>operation: Add shutdown hook
op9=>operation: jar hell检测
op10=>operation: 根据设置构建node
op16=>operation: 失败退出|current

cond1=>condition: JVM版本检查
cond2=>condition: 是否root权限启动

st->op1->op2->op3->op4->cond1
cond1(yes)->cond2
cond1(no)->op16
cond2(yes)->op6->op7->op8->op9->op10
cond2(no)->op16
op10->e
```