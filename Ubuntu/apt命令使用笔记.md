## apt命令使用笔记
- 查询软件包的版本
  ```bash
  apt-cache madison <<package name>>
  ```
- 安装指定版本的软件包
  ```bash
  apt-get install softname=version
  sudo apt-get install  openssh-client=1:6.6p1-2ubuntu1
  ```
- 24.04更新源
  - 在 Ubuntu 24.04 之前，Ubuntu 的软件源配置文件使用传统的 One-Line-Style，路径为 <code>/etc/apt/sources.list</code>; 从 Ubuntu 24.04 开始，Ubuntu 的软件源配置文件变更为 DEB822 格式，路径为 <code>/etc/apt/sources.list.d/ubuntu.sources</code>。
  - <strong>注意:</strong><font color="FF0000"> 24.04 源文件地址 已经更换为 <code>/etc/apt/sources.list.d/ubuntu.sources</code></font>
  - 以更换阿里源为例，打开终端，输入以下命令，备份当前的源列表
    ```bash
    sudo cp /etc/apt/sources.list.d/ubuntu.sources  /etc/apt/sources.list.d/ubuntu.sources.bak

    # 关闭官方源
    vim /etc/apt/sources.list.d/ubuntu.sources
    # 添加Enabled: no
    ```
  - 打开文本编辑器，输入以下命令:
    ```bash
    sudo vim /etc/apt/sources.list.d/third-party.sources
    ```
  - 在文本编辑器中粘贴以下内容:
    ```bash
    # 阿里云
    Enabled: yes
    Types: deb
    URIs: http://mirrors.aliyun.com/ubuntu/
    Suites: noble noble-updates noble-security
    Components: main restricted universe multiverse
    Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

    # 网易云
    Enabled: yes
    Types: deb
    URIs: http://mirrors.163.com/ubuntu/
    Suites: noble noble-updates noble-security
    Components: main restricted universe multiverse
    Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

    # 清华源
    Enabled: yes
    Types: deb
    URIs: http://mirrors.tuna.tsinghua.edu.cn/ubuntu/
    Suites: noble noble-updates noble-security
    Components: main restricted universe multiverse
    Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

    # 中科大源
    Enabled: yes
    Types: deb
    URIs: http://mirrors.ustc.edu.cn/ubuntu/
    Suites: noble noble-updates noble-security
    Components: main restricted universe multiverse
    Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
    ```
---
### 参考连接
- [Ubuntu24.04更换源地址（新版源更换方式）](https://www.imlhx.com/posts/7930.html)