## sudo使用记录
sudo 指定用户执行命令sudo -u username CMD
sudo -E 用户可以在sudo执行时保留当前用户已存在的环境变量，不会被sudo重置。另外，如果用户对于指定的环境变量没有权限，则会报错。