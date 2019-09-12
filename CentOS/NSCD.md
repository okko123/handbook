## NSCD介绍
比如DNS领域常见的dig命令不会使用NSCD提供的缓存，相反ping得到的DNS解析结果将使用NSCD提供的缓存。
### NSCD核心配置
```bash
reload-count unlimited | number        #注意下文会具体说明
enable-cache hosts <yes|no>            #Enables or disables the specified service cache. The default is no.
positive-time-to-live hosts value      #success缓存的响应时间，注意，下文会具体说明
negative-time-to-live hosts value      #非success缓存的响应时间，注意，下文会具体说明
```
### 关于缓存时间
```bash
positive-time-to-live hosts 60
negative-time-to-live hosts 10
```
---
* https://leeweir.github.io/2019/02/02/DNS%E7%BC%93%E5%AD%98%E4%BB%8B%E7%BB%8D-NSCD/