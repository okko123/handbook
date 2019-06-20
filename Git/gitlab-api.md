# 获取所有项目信息
- 获取gitlab管理员的Private token，在User - Settings - Private Token
- 获取用户的ID，在User - Settings - Profile - User ID，或者使用API接口获取
```bash
curl --header "PRIVATE-TOKEN: EeVPPydkxJuxhaabbbgb1" https://www.gitlab.com/api/v4/users
可选择参数
active=true/false
blocked=true/false
username=:username
```
- 获取所有项目的ID
```bash
curl --header "PRIVATE-TOKEN: EeVPPydkxJuxhaabbbgb1" https://www.gitlab.com/api/v4/projects
#simple=true参数来简化输出的内容，sort=asc/desc进行排序。特别注意，返回的数据是分页的，每页默认20条，如果项目较多需要使用分页参数。per_page=20控制每页返回的条数，page=1控制当前页数

#获取页数的方法，在返回的头部信息X-Total-Pages为总的页数
curl --head --header "PRIVATE-TOKEN: EeVPPydkxJuxhaabbbgb1" 'https://www.gitlab.com/api/v4/projects'

#Example
curl --header "PRIVATE-TOKEN: EeVPPydkxJuxhaabbbgb1" 'https://www.gitlab.com/api/v4/projects?sample=ture&sort=desc&page=1&per_page=20'
```

- 将用户添加到项目中
```bash
curl -XPOST --header "PRIVATE-TOKEN: EeVPPydkxJuxhaabbbgb1" https://www.gitlab.com/api/v4/project/id/members --data "user_id=1&access_level=20"
```
- 获取部署gitlab中所有的deploy key
```bash
curl --head --header "PRIVATE-TOKEN: EeVPPydkxJuxhaabbbgb1" 'https://www.gitlab.com/api/v4/deploy_keys'
```

- 命令行下删除privilege deploy key
```bash
#Starting a Rails console session
sudo gitlab-rails console
#获取deploykey id
DeployKey.all()
#删除DeployKey
DeployKey.find_by(id: [deploy_key_id]).destroy
```

## gitlab升级路径
https://docs.gitlab.com/ee/policy/maintenance.html#upgrade-recommendations
例如本机版本为8.13.4升级到11.3.4，需要安装此路径进行更新：8.13.4 -> 8.17.7 -> 9.5.10 -> 10.8.7 -> 11.3.4
不能跨版本升级，例如10.0.4 -> 11.11.3，使用rpm -Uvh / gitlab-rake gitlab:backup:restore 恢复仓库，会提示版本不一致，拒绝导入

https://docs.gitlab.com/ee/api/users.html#for-normal-users
https://docs.gitlab.com/ee/api/projects.html#list-all-projects
https://docs.gitlab.com/ee/api/members.html#add-a-member-to-a-group-or-project
https://ranying666.github.io/2017/06/20/gitlab-api/
https://gitlab.com/gitlab-org/gitlab-ce/issues/53783