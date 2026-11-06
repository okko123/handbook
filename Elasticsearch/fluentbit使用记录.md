### fluentbit使用记录
- 系统: ubuntu 22.04
- 依赖包: flex bison cmake pkg-config libyaml-dev
```bash
apt update
apt install flex bison cmake pkg-config libyaml-dev -y
```
- 编译安装
```bash
wget https://github.com/fluent/fluent-bit/archive/refs/tags/v5.1.1.zip
unzip v5.1.1.zip
cd v5.1.1/build
cmake ../
```
- 配置
```bash
cat > fluent-bit.yaml <<EOF
service:
  flush: 1
  log_level: info
  # 导入预设的解析器
  parsers_file: parsers.conf

pipeline:
  inputs:
    - name: tail
      tag: example
      path: /tmp/example.log
      # 核心配置：指定偏移量持久化数据库路径
      db: /tmp/fluentbit/flb_tail.db
      # 第一次遇到新文件时，从文件开头读取
      read_from_head: on
      # 核心配置：在写入 Kafka 的数据体中，增加一个名为 path 的 key，值为文件路径
      path_key: path

    - name: tail
      tag: runjson
      path: /tmp/runjson.log
      db: /tmp/fluentbit/flb_tail.db
      read_from_head: on
      path_key: path
      parser: json


  outputs:
    - name: kafka
      match: example
      brokers: 172.16.81.202:9092
      topics: test2
EOF

cat > parsers.conf <<EOF
[PARSER]
    Name   json
    Format json
    Time_Key time
    Time_Format %d/%b/%Y:%H:%M:%S 

[PARSER]
    Name   logfmt
    Format logfmt
EOF
```
- 启动
```bash
# 开启热重载
bin/fluent-bit -c fluent-bit.yaml --enable-hot-reload
```