# Gitlab配置LDAP
- 修改gitlab配置文件，启用LDAP：/etc/gitlab/gitlab.rb
- 重新加载配置：gitlab-ctl reconfigure
- 查康是否能正常获取用户列表：gitlab-rake gitlab:ldap:check
---
[官方文档配置LDAP认证](https://docs.gitlab.com/11.11/ee/administration/auth/ldap.html)