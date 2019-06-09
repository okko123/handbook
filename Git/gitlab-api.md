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
curl --header "PRIVATE-TOKEN: EeVPPydkxJuxhaabbbgb1" 'https://www.gitlab.com/api/v4/projects?simple=ture&sort=desc&page=1&per_page=20'
```

- 将用户添加到项目中
```bash

curl -XPOST --header "PRIVATE-TOKEN: EeVPPydkxJuxhaabbbgb1" https://www.gitlab.com/api/v4/project/id/members --data "user_id=1&access_level=20"
```

https://docs.gitlab.com/ee/api/users.html#for-normal-users
https://docs.gitlab.com/ee/api/projects.html#list-all-projects
https://docs.gitlab.com/ee/api/members.html#add-a-member-to-a-group-or-project
https://ranying666.github.io/2017/06/20/gitlab-api/