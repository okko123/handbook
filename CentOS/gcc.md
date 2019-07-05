# 更新gcc
## 由于CentOS6自带的gcc版本未4.4.7。安装swoole要求gcc的版本>=4.8.0，因此需要升级gcc的版本才能进行编译安装。使用devtoolset安装新版gcc。
## 关于devtoolset的安装，Software Collections[官方指导](https://www.softwarecollections.org/en/scls/rhscl/devtoolset-3/)
```bash
wget http://people.centos.org/tru/devtools-2/devtools-2.repo -O /etc/yum.repos.d/devtoolset-2.repo
#安装devtoolset-2源中的gcc包
yum -y install devtoolset-2-gcc devtoolset-2-gcc-c++ devtoolset-2-binutils
#使用scl切换环境，
scl enable devtoolset-2 bash
gcc --version

gcc (GCC) 4.8.2 20140120 (Red Hat 4.8.2-15)
Copyright (C) 2013 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```

- [参考链接1](http://blog.fungo.me/2016/03/centos-development-env/)