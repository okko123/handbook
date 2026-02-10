### Debian 13 安装使用
1. debian-13.3.0-amd64-DVD-1.iso安装系统。
   * 安装组件：SSH Server、standard system utilities
2. 配置网络
   1. 配置静态IP、DNS
      ```bash
      # 在 Debian 13 中，dns-nameservers 配置不生效通常是因为系统默认使用了 systemd-resolved 或者没有安装 resolvconf 软件包。

      # 在现代 Debian 版本中，/etc/network/interfaces 里的 dns-* 参数并不会直接修改 /etc/resolv.conf，除非系统中有“中间人”插件来负责传递这些参数。

      # 如果你希望 /etc/network/interfaces 中的 dns-nameservers 行生效，你需要安装 resolvconf。它是连接网络配置和 DNS 配置的桥梁。
      apt install -y resolvconf
      systemctl restart resolvconf

      # 使用编辑器修改
      vim /etc/network/interfaces

      # 修改以下内容，按照实际修改网卡的名称
      allow-hotplug ens192
      iface ens192 inet static
              address 192.168.1.10/24
              gateway 192.168.1.254
              # dns-* options are implemented by the resolvconf package, if installed
              dns-nameservers 223.5.5.5 223.6.6.6

      # 重启服务
      systemctl restart networking
      ```
   2. 配置网络源，使用 DEB822 格式（新格式，Debian 12 及以上支持）
      ```bash
      cat > /etc/apt/sources.list.d/debian.sources <<'EOF'
      Types: deb deb-src
      URIs: https://mirrors.tuna.tsinghua.edu.cn/debian
      Suites: trixie trixie-updates trixie-backports
      Components: main contrib non-free non-free-firmware
      Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

      Types: deb deb-src
      URIs: https://mirrors.tuna.tsinghua.edu.cn/debian-security
      Suites: trixie-security
      Components: main contrib non-free non-free-firmware
      Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
      EOF

      # 禁用传统的 sources.list 文件
      mv /etc/apt/sources.list /etc/apt/sources.list.disabled

      # 添加docker-ce源
      install -m 0755 -d /etc/apt/keyrings
      curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      chmod a+r /etc/apt/keyrings/docker.gpg

      cat > /etc/apt/sources.list.d/docker.sources <<EOF
      Types: deb
      URIs: https://mirrors.aliyun.com/docker-ce/linux/debian
      Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
      Components: stable
      Signed-By: /etc/apt/keyrings/docker.gpg
      EOF

      apt update
      ```
3. 安装基础软件包
   ```bash
   apt install -y vim sudo network-manager curl wget gpg
   ```
4. 修改Debian默认nano编辑器为VIM
   ```bash
   update-alternatives --config editor
   ```
5. 修改shell
   ```bash
   cat > /etc/profile.d/custom-path.sh <<'EOF'
   export PATH="$PATH:/usr/sbin"

   export LS_OPTIONS='--color=auto'

   alias ls='ls $LS_OPTIONS'
   alias ll='ls $LS_OPTIONS -l'
   alias l='ls $LS_OPTIONS -lA'

   alias rm='rm -i'
   alias cp='cp -i'
   alias mv='mv -i'
   EOF
   ```