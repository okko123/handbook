## 查询后端服务器
select * from backends;

## 查询用户名、密码
SELECT * FROM pwds;

## 添加master、slave
ADD MASTER 10.14.1.28:3306;
ADD SLAVE 10.14.1.29:3306;

## 保存配置
SAVE CONFIG;

## 修改monitor的用户名密码
set backend-monitor-pwds=dbproxymonitor:Password;