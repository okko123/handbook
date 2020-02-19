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