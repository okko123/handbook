# 编译安装python出现问题
* OS: CentOS 7
* Python: 3.8.1
* gcc: 4.8.2
1. 编译出现ImportError: No module named '_ctypes'；
   * 由于系统缺少libffi-devel包导致。
   * 使用yum install libffi-devel -y，然后执行make clean清理编译文件，重新编译即可解决
2. 编译出现：
   ```bash
   Could not import runpy module
   Traceback (most recent call last):
     File "/root/Python-3.8.1/Lib/runpy.py", line 15, in <module>
       import importlib.util
     File "/root/Python-3.8.1/Lib/importlib/util.py", line 14, in    <module>
       from contextlib import contextmanager
     File "/root/Python-3.8.1/Lib/contextlib.py", line 4, in    <module>
       import _collections_abc
   SystemError: <built-in function compile> returned NULL without    setting an error
   generate-posix-vars failed
   make[1]: *** [pybuilddir.txt] Error 1
   make[1]: Leaving directory `/root/Python-3.8.1'
   make: *** [profile-opt] Error 2
   ```
   * 由于在低版本的gcc编译器，编译参数中添加--enable-optimizations引起。
   * 解决的方法，升级gcc的版本（>8.0）或者编译python时禁用--enable-optimizations
---
* 安装pyenv工具，管理多个版本的python
```bash
yum install -y openssl-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel libffi-devel xz-devel
git clone https://gitee.com/mirrors/pyenv.git ~/.pyenv

# 配置环境变量
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

# 验证安装成功
pyenv --version
pyenv 2.6.17-16-g48743aa8

# 安装python
# 1. 查询可以安装的python版本
pyenv install -l | grep -E '^[^a-zA-Z]+$'

# 2. 安装Python。本文将以安装Python 3.8.10和Python 3.12.1为示例，具体可安装的版本以实际情况为准。
pyenv install 3.8.10
pyenv install 3.12.1

# 3. 查看所有可用版本。
pyenv versions

# 4. 设置全局默认版本。
pyenv global 3.8.10

# 5. 查看当前版本
pyenv version
```
---
#### 参考连接
- [安装Python](https://help.aliyun.com/zh/sdk/developer-reference/installing-python?spm=a2c4g.11186623.help-menu-262060.d_1_6_0_0.574f3e97h0ZGKl&scm=20140722.H_2787113._.OR_help-T_cn~zh-V_1)