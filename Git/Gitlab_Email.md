
gitlab配置smtp服务
===
- 以Outlook为例子
```bash
vim /etc/gitlab/gitlab/rb
#修改一下内容
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp-mail.outlook.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "username@outlook.com"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_domain'] = "smtp-mail.outlook.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'
```
- 使用Gitlab自带工具，测试SMTP服务
```bash
gitlab-rails console
irb(main):003:0> Notify.test_email('destination_email@address.com', 'Message Subject', 'Message Body').deliver_now
```
- 参考文章
  - [https://docs.gitlab.com/omnibus/settings/smtp.html#outlook]
