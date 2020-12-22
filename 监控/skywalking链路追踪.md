## skywalking部署
### 过滤endpoint
Endpoint过滤即url忽略，有时可能希望忽略部分特殊 URL 的追踪，例如说，健康检查的 HTTP API及其他我们不需要关注的url如/eureka/**,/consul/**等等。为此SkyWalking 提供 trace-ignore-plugin 插件，可以实现忽略部分 URL 的追踪，具体步骤如下，进入skywalking的目录下：
1. 引入忽略插件：apm-trace-ignore-plugin-8.2.0.jar。进入agent目录，复制optional-plugins/apm-trace-ignore-plugin-8.2.0.jar文件至plugins目录下。agent目录结构如下：
   ```bash
   ├── activations
   │   ├── apm-toolkit-kafka-activation-8.2.0.jar
   │   └── apm-toolkit-trace-activation-8.2.0.jar
   ├── bootstrap-plugins
   │   ├── apm-jdk-http-plugin-8.2.0.jar
   │   └── apm-jdk-threading-plugin-8.2.0.jar
   ├── config
   │   └── agent.config
   ├── logs
   │   └── skywalking-api.log
   ├── optional-plugins
   │   ├── apm-spring-tx-plugin-8.2.0.jar
   │   ├── apm-spring-webflux-5.x-plugin-8.2.0.jar
   │   ├── apm-trace-ignore-plugin-8.2.0.jar
   │   └── apm-zookeeper-3.4.x-plugin-8.2.0.jar
   ├── optional-reporter-plugins
   │   └── kafka-reporter-plugin-8.2.0.jar
   ├── plugins
   │   ├── apm-activemq-5.x-plugin-8.2.0.jar
   │   ├── apm-armeria-0.84.x-plugin-8.2.0.jar
   │   ├── apm-struts2-2.x-plugin-8.2.0.jar
   │   ├── apm-trace-ignore-plugin-8.2.0.jar
   │   └── tomcat-7.x-8.x-plugin-8.2.0.jar
   └── skywalking-agent.jar
   ```
2. 添加配置，有2种可选方式：
   1. 在config目录下新增apm-trace-ignore-plugin.config文件，配置trace.ignore_path=${SW_AGENT_TRACE_IGNORE_PATH:/eureka/**}
   2. 增加启动参数-Dskywalking.trace.ignore_path=/eureka/**，重启应用，SkyWalking将不在采集指定路径的数据。
   3. 路径配置方式：
      - /path/?: 匹配单个字符
      - /path/*: 匹配多个字符
      - /path/**: 匹配多个字符并且支持多级目录
      - 如果有多个需要忽略，使用英文逗号（,）分隔，如：trace.ignore_path=/eureka/**,/consul/**
3. agent.config配置指定忽略后缀
在agent.config中存在如下配置，如果trace的第一个span的操作名称以html后缀结尾，则忽略这些trace
agent.ignore_suffix=${SW_AGENT_IGNORE_SUFFIX:.html}

---
# 参考信息
- [github skywalking](https://github.com/apache/skywalking/blob/v8.2.0/docs/en/setup/service-agent/java-agent/README.md#optional-plugins)
- [Skywalking-使用可选插件 apm-trace-ignore-plugin](https://blog.csdn.net/u013095337/article/details/80452088)