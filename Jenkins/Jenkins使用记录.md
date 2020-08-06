## Jenkins使用记录
### 批量修改任务的配置文件
- 在Jenkins的工作目录下，假设工作目录为/data/jenkins。任务配置文件的路径为/data/jenkins/joub_name/config.xml
- 修改完成后，需要在Jenkins的web界面上操作：【系统管理】-> 【读取设置】或重启jenkins重新读取配置文件。默认情况下，Jenkins会将配置加载奥内存中

### 参数化构建选择tag
- 需要安装插件Git Parameter
- 在任务配置中，添加参数化构建过程