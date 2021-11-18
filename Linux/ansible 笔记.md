## ansible 笔记
- 获取主机信息，以及ansible可以使用的变量：ansible -m setup 1.2.3.4
- 条件判断
  ```bash
  在when后面使用表达式，当表达式结果为True则执行
  案例：
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
  ---
  ### 参考连接
  [第四节：Ansible系列之条件判断](https://www.kancloud.cn/louis1986/ansible/561541)