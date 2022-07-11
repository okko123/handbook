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
  ### ansible 的任务委派功能
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