## ansible 笔记
---
- 获取主机信息，以及ansible可以使用的变量
  ```bash
  ansible -m setup 1.2.3.4
  ```
- 条件判断1
  ```yaml
  # 在when后面使用表达式，当表达式结果为True则执行
  # 案例：
  tasks:
    - name: "shut down Debian flavored systems"
      command: /sbin/shutdown -t now
      when: ansible_os_family == "Debian"
  （当操作系统为debian时就执行关机操作）

  ---
  - hosts: webserver
    user: admin
    become: yes
    vars:
      - username: user01
    tasks:
      - name: create {{ username }} user
        user: name={{ username }}
        when: ansible_fqdn == "node2.51yuki.cn"
    （当主机名为node2.51yuki.cn就在该机器上创建用户user01）
  ```
- 条件判断2:
  ```yaml
  # 在nginx_test任务执行失败后，执行配置文件回滚操作
  # 使用ignore_errors，绕过失败任务，继续执行后面的任务操作
  - name: Nginx test
    tags: nginx_test
    command: /usr/local/nginx/sbin/nginx -t
    register: nginx_test
    ignore_errors: yes
  
  - name: Nginx conf rollback
    command: cp /tmp/backup/{{ item }} /usr/local/nginx/conf/vhosts/{{ item }}
    when:
      nginx_test.failed == true
    with_items:
      - server1.conf
      - server2.conf
  ```
- ansible首次连接host服务器需要验证问题。原因：当ansible首次去进行ssh连接一个服务器的时候，由于在本机的~/.ssh/known_hosts文件中并有fingerprint key串，ssh第一次连接的时候一般会提示输入yes进行确认为将key字符串加入到~/.ssh/known_hosts文件中。故回报如上错误。
  ```bash
  vim /etc/ansible/ansible.cfg
  host_key_checking = False
  ```
---
## ansible 模板
```shell
# 文件目录
├── templates
│   └── nginx.conf.j2
└── template.yml

# 先创建模板文件nginx.conf.j2
cat > nginx.conf.j2 <<EOF
listen {{ http_port }};
server example.com;
EOF

cat > template.yml <<EOF
---
- hosts: 1.2.3.4
  remote_user: root

  tasks:
    - name: template copy
      template: src=nginx.conf.j2 dest=/etc/nginx/nginx.conf
EOF

ansible-playbook template.yml -e "http_port=80;"

# for循环
cat > nginx.conf.j2 <<EOF
{% for port in ports %}
listen {{ port }}
{% endfor %}
server example.com;
EOF

ansible-playbook template.yml -e '{"ports": ["http_port=80;", "http_port=90;", "http_port=95;"]}'
```
---
## ansible 的任务委派功能
- Ansible默认在配置的机器上执行任务，当你有一大票机器需要配置或则每个设备都可达的情况下很有用。但是，当你需要在另外一个Ansible控制机器上运行任务的时候，就需要用到任务委派了。使用delegate_to关键字就可以委派任务到其他机器上运行，同时可用的fact也会使用委派机器上的值。
  ```bash
  tasks:
    - name: "shut down Debian flavored systems"
      command: /sbin/shutdown -t now
      delegate_to: localhost
  ```
---
### 参考连接
- [第四节：Ansible系列之条件判断](https://www.kancloud.cn/louis1986/ansible/561541)
- [ansible 的任务委派功能](https://blog.51cto.com/simpledevops/1653191)
- [ansible之when条件语法、处理任务失败、jinja2模板和项目管理](https://blog.csdn.net/Fran_klin__/article/details/126231558)
- [ansible中template简单使用](https://www.cnblogs.com/lvzhenjiang/p/14199384.html)