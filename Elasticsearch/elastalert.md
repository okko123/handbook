# elastalert安装使用
## ElastAlert是一个简单的框架，用于警告Elasticsearch中的数据中的异常，尖峰或其他的规则。文档使用的版本为v0.1.39(github Tags)
- 安装ElastAlert的要求
  - Elasticsearch
  - Python 2.7
  - pip
- 安装ElastAlert
```bash
git clone https://github.com/Yelp/elastalert.git
cd elastalert
pip install "setuptools>=11.3"
pip install -r requirements.txt
python setup.py install

#如果你使用的Elasticsearch 5.0+
pip install "elasticsearch>=5.0.0"

#如果你使用的Elasticsearch 2.X
pip install "elasticsearch<3.0.0"
```
- 手动生成config.yaml配置文件，配置样板参考仓库中的config.yaml.example文件
```bash
es_host: vpc-xxxxxx.us-west-1.es.amazonaws.com
es_port: 443
rules_folder: rules
run_every:
  seconds: 30
buffer_time:
  minutes: 1
use_ssl: True
writeback_index: elastalert_status
alert_time_limit:
  days: 2
  ```
- 创建索引
```bash
$ elastalert-create-index
New index name (Default elastalert_status)
Name of existing index to copy (Default None)
New index elastalert_status created
Done!
```
- 创建告警规则，以example_rules/example_frequency.yaml文件作为模板，
```bash
# From example_rules/example_frequency.yaml
es_host: elasticsearch.example.com
es_port: 14900
name: Example rule
type: frequency
index: logstash-*
num_events: 50
timeframe:
    hours: 4
filter:
- term:
    some_field: "some_value"
alert:
- "email"
email:
- "elastalert@example.com"

#当使用邮件的方式发送告警，需要开启smtp_ssl，
#腾讯企业邮箱的smtp协议，465端口默认开启ssl，因此需要开启，否则提示“SMTP host: Connection unexpectedly closed”的错误
smtp_ssl: true
```
- 测试配置的规则
```bash
$ elastalert-test-rule example_rules/example_frequency.yaml
```
- 成功完成上述步骤后，启动ElastAlert
```bash
$ python -m elastalert.elastalert --verbose --rule example_frequency.yaml  # or use the entry point: elastalert --verbose --rule ...
No handlers could be found for logger "Elasticsearch"
INFO:root:Queried rule Example rule from 1-15 14:22 PST to 1-15 15:07 PST: 5 hits
INFO:Elasticsearch:POST http://elasticsearch.example.com:14900/elastalert_status/elastalert_status?op_type=create [status:201 request:0.025s]
INFO:root:Ran Example rule from 1-15 14:22 PST to 1-15 15:07 PST: 5 query hits (0 already seen), 0 matches, 0 alerts sent
INFO:root:Sleeping for 297 seconds
```

## 第三方工具和插件，实现在kibana的web ui下修改elastalert的配置规则
 - 安装kibana插件，要求kibana的版本为6.3.1 或者更高。文档中kibana的版本为6.7.0，因此使用的插件版本为1.0.3。每个elastalert的版本分别对应不同版本的kibana，因此需要依据实际版选择安装，必须做到版本号一一对应。
```bash
./bin/kibana-plugin install https://github.com/bitsensor/elastalert-kibana-plugin/releases/download/1.0.3/elastalert-kibana-plugin-1.0.3-6.7.0.zip
```
 - 使用docker启动ElastAlert，文档中使用的镜像版本为1.0.0。使用nodejs进行一次封装
   - config.json作为nodejs的配置文件，需要修改配置内容。主要修改ES的host和端口
   - elastalert.yaml作为elastalert-server的配置文件，需要修改配置内容。主要修改ES的host和端口
 ```bash
git clone https://github.com/bitsensor/elastalert.git; cd elastalert
docker run -d -p 3030:3030 \
    -v `pwd`/config/elastalert.yaml:/opt/elastalert/config.yaml \
    -v `pwd`/config/config.json:/opt/elastalert-server/config/config.json \
    -v `pwd`/rules:/opt/elastalert/rules \
    -v `pwd`/rule_templates:/opt/elastalert/rule_templates \
    --net="host" \
    --name elastalert bitsensor/elastalert:1.0.0
```


[官方文档1](https://elastalert.readthedocs.io/en/latest/running_elastalert.html#requirements)