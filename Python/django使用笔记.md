## django使用笔记
> 创建helloworld项目
```bash
django-admin startproject helloworld
```
> 创建helloworld项目内的app，ldap、openvpn
```bash
cd helloworld
django-admin startapp ldap
django-admin startapp openvpn
```
> 初始化数据库，创建超级用户
```bash
python manage.py migrate
python manage.py createsuperuser
```