## 重置用户状态，运行Rails console:
```bash
gitlab-rails console production
user =User.find_by(email: 'xxx')
user.state = "active"
user.save
```

## 重置管理员密码，运行Rails console:
```bash
gitlab-rails console production
user =User.find_by(email: 'xxx')
user.password = "password"
user.save
```

## gitlab仓库备份与恢复
### 备份
```bash
#默认保存的路径为/var/opt/gitlab/backups，可以修改一下文件修改文件的保存路径。/var/opt/gitlab/gitlab-rails/etc/gitlab.yml文件的Backup Settings节进行修改。
#文件名：[Timestamp]_gitlab_backup.tar
gitlab-rake gitlab:backup:create
```
### 恢复
```bash
cp 1493107454_2017_04_25_9.1.0_gitlab_backup.tar /var/opt/gitlab/backups/
sudo chown git.git /var/opt/gitlab/backups/1493107454_2017_04_25_9.1.0_gitlab_backup.tar
gitlab-ctl stop unicorn
gitlab-ctl stop sidekiq

#查看状态
gitlab-ctl status

#恢复数据文件
gitlab-rake gitlab:backup:restore BACKUP=1493107454_2017_04_25_9.1.0

#手工恢复配置文件
/etc/gitlab/gitlab-secrets.json
#重启gitlab
gitlab-ctl reconfigure
gitlab-ctl restart
gitlab-rake gitlab:check SANITIZE=true
```
## 禁用/启用 本地用户密码认证
> 使用拥有管理员权限的账号登陆
  - On the top bar, select Main menu > Admin.
  - On the left sidebar, select Settings > General.
  - Expand the Sign-in restrictions section.
  - Password authentication enabled
  - You can restrict the password authentication for web interface and Git over HTTP(S):
  - Web interface: When this feature is disabled, the Standard sign-in tab is removed and an external authentication provider must be used.
  - Git over HTTP(S): When this feature is disabled, a Personal Access Token or LDAP password must be used to authenticate.
## 通过命令行将用户设置为管理员(admin)
```bash
sudo gitlab-rails console -e production
user = User.find_by(username: 'my_username')
user.admin = true
user.save!
```
## 设置时区
> 默认情况下，gitlab使用UTC时间，因此备份的时候可能出现文件名日期与当前日期不一致的问题
```bash
vim /etc/gitlab/gitlab.rb
gitlab_rails['time_zone'] = 'Asia/Shanghai'

sudo gitlab-ctl reconfigure
sudo gitlab-ctl restart
```
---
## 参考连接
- [gitlab备份](https://docs.gitlab.com/ce/raketasks/backup_restore.html)
- [gitlab恢复](https://docs.gitlab.com/ce/raketasks/backup_restore.html#restore)
- [Sign-in restrictions](https://docs.gitlab.com/ee/user/admin_area/settings/sign_in_restrictions.html
- [Change your time zone](https://docs.gitlab.com/ee/administration/timezone.html)