### sls 语法
- 访问最多的10条URI
* | select count(1) as pv, split_part(request_uri,'?',1) as path where request_method != 'head' group by path order by pv desc limit 10