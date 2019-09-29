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
---
## 参考连接
[gitlab备份](https://docs.gitlab.com/ce/raketasks/backup_restore.html)
[gitlab恢复](https://docs.gitlab.com/ce/raketasks/backup_restore.html#restore)