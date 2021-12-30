# lua笔记
## 参数作用
- init_by_lua_file
- init_worker_by_lua
## nginx通过content_by_lua和content_by_lua_file来嵌入lua脚本
### content_by_lua，在nginx配置文件中嵌入lua代码
- 修改nginx配置文件nginx.conf，重启nginx访问 http://localhost//hellolua 应该可以看到 Hello Lua.
  ```bash
  location /hellolua {
      content_by_lua '
          ngx.header.content_type = "text/html";
          ngx.say("Hello Lua.");
      ';
  }
  ```
### content_by_lua_file，在nginx配置文件中引入lua脚本文件
- 修改nginx配置文件nginx.conf，访问 http://localhost/demo 则可以看到 Hello Lua Demo.
  ```bash
  # lua_code_cache表示关掉缓存，缓存关掉的情况下修改lua脚本不需要重启nginx。在关闭缓存后重启nginx，会出现alert警告：nginx: [alert] lua_code_cache is off; this will hurt performance
  # content_by_lua_file指定脚本路径。此处为相对路径，相对于nginx根目录，编辑lua脚本
  location /demo {
      lua_code_cache off;
      content_by_lua_file lua_script/demo.lua;
  }
  
  cat > filename:demo.lua <<EOF
  ngx.header.content_type = "text/html"
  ngx.say("Hello Lua Demo.")
  EOF
  ```
### Nginx常用参数获取
```lua
ngx.header.content_type = "text/html"
ngx.header.PowerBy = "Lua"
-- 请求头table
for k, v in pairs(ngx.req.get_headers()) do
    ngx.say(k, ": ", v)
end
 
-- 请求方法 GET、POST等
ngx.say("METHOD:" .. ngx.var.request_method)
 
-- 获取GET参数
for k, v in pairs(ngx.req.get_uri_args()) do
    ngx.say(k, ":", v)
end
 
 
-- 获取POST参数
ngx.req.read_body()
for k, v in pairs(ngx.req.get_post_args()) do
    ngx.say(k, ":", v)
end
 
-- HTTP版本
ngx.say(ngx.req.http_version())
 
-- 未解析的请求头字符串
ngx.say(ngx.req.raw_header())  
 
-- 未解析的BODY字符串
ngx.print(ngx.req.get_body_data())
 
-- ngx.exit(400)
-- ngx.redirect("/", 200)

-- 下面看个小例子，生成字符串的md5值。
ngx.header.content_type = "text/html"
local resty_md5 = require "resty.md5"
local  md5 = resty_md5:new()
 
local s = "Hello Lua."
md5:update(s)
local str = require "resty.string"
ngx.say(str.to_hex(md5:final()))
 
ngx.say(ngx.md5(s))
```

---
# 参考连接
[Nginx+Lua入门知识](https://itopic.org/lua-start.html)