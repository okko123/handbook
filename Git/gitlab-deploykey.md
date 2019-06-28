## 命令行下删除privilege deploy key
- 使用sudo执行gitlab-psq命令,在pgsql下查找deploy key的ID。并删除该key与每个项目的关联
```bash
$ sudo gitlab-psql
sql (9.6.11)
Type "help" for help.

gitlabhq_production=# select id, user_id, title from keys where type LiKE 'DeployKey';
 id | user_id |          title
----+---------+--------------------------
 11 |      10 | ci
 20 |       1 | mgr2
 23 |       1 | colin@app1
 16 |       1 | mgr1
 24 |       1 | admin1.sh
 25 |       1 | www-data@dev
 22 |       1 | staging1
(7 rows)

gitlabhq_production=# delete from deploy_keys_projects where deploy_key_id IN(17,19,21);
DELETE 78
```
- 删除保存在gitlab上的deploy key
```bash
#打开Rails的控制台 session
sudo gitlab-rails console

#获取deploykey id
DeployKey.all()

#删除DeployKey
DeployKey.find_by(id: [deploy_key_id]).destroy
```
