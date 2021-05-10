## yum 命令记录
### 使用yum下载rpm包，以下载wget的rpm包为例子，系统为CentOS7；要使用--downloadonly选项，需要先安装yum-plugin-downloadonly，不安装该包的话，会报下面的错误信息：Command line error: no such option: --downloadonly
```bash
   yum install --downloadonly wget
   wget的rpm包下载目录为：/var/cache/yum/x86_64/7/base/packages/
```


### 查找版本
yum list docker-ce.x86_64 --showduplicates | sort -r
- 安装指定版本，例如docker-ce.x86_64   3:19.03.15-3.el7 
  ```bash
  yum install docker-ce-19.03.15-3.el7 
  ```
