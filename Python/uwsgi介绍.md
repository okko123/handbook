# uwsgi介绍
## WSGI
Web服务器网关接口（Python Web Server Gateway Interface，缩写为WSGI）是为Python语言定义的Web服务器和Web应用程序或框架之间的一种简单而通用的接口。自从WSGI被开发出来以后，许多其它语言中也出现了类似接口。WSGI是作为Web服务器与Web应用程序或应用框架之间的一种低级别的接口，以提升可移植Web应用开发的共同点。WSGI是基于现存的CGI标准而设计的。
WSGI区分为两个部份：一为“服务器”或“网关”，另一为“应用程序”或“应用框架”。在处理一个WSGI请求时，服务器会为应用程序提供环境资讯及一个回呼函数（Callback Function）。当应用程序完成处理请求后，透过前述的回呼函数，将结果回传给服务器。所谓的 WSGI 中间件同时实现了API的两方，因此可以在WSGI服务和WSGI应用之间起调解作用：从WSGI服务器的角度来说，中间件扮演应用程序，而从应用程序的角度来说，中间件扮演服务器。“中间件”组件可以执行以下功能：
重写环境变量后，根据目标URL，将请求消息路由到不同的应用对象。
允许在一个进程中同时运行多个应用程序或应用框架。
负载均衡和远程处理，通过在网络上转发请求和响应消息。
进行内容后处理，例如应用XSLT样式表。
以前，如何选择合适的Web应用程序框架成为困扰Python初学者的一个问题，这是因为，一般而言，Web应用框架的选择将限制可用的Web服务器的选择，反之亦然。那时的Python应用程序通常是为CGI，FastCGI，mod_python中的一个而设计，甚至是为特定Web服务器的自定义的API接口而设计的。WSGI没有官方的实现, 因为WSGI更像一个协议。只要遵照这些协议,WSGI应用(Application)都可以在任何服务器(Server)上运行, 反之亦然。WSGI就是Python的CGI包装，相对于Fastcgi是PHP的CGI包装。
WSGI将 web 组件分为三类： web服务器，web中间件,web应用程序， wsgi基本处理模式为 ： WSGI Server -> (WSGI Middleware)* -> WSGI Application 。
## uWSGI
## uwsgi
* uwsgi的配置文件解析
  ```bash
  [uwsgi]
  socket = 127.0.0.1:3031
  master = true
  #为每个工作进程设置请求数的上限。当一个工作进程处理的请求数达到这个值，那么该工作进程就会被回收重用（重启）。你可以使用这个选项来默默地对抗内存泄漏（尽管这类情况使用reload-on-as和reload-on-rss选项更有用）。
  max-requests = 1000
  ```
* 启动/停止/重启uwsgi服务
  ```bash
  #使进程在后台运行，并将日志打到指定的日志文件
  uwsgi --daemonize /var/log/uwsgi.log
  uwsgi --stop <pidfile>
  uwsgi --reload <pidfile>
  ```


## 参考资料
* [uWSGI web应用介绍](https://uwsgi-docs-zh.readthedocs.io/zh_CN/latest/WSGIquickstart.html)
* [网关协议介绍](https://www.jianshu.com/p/7d8bd98efaf9)
* [廖雪峰教程](https://www.liaoxuefeng.com/wiki/1016959663602400/1017805733037760)
* [uwsgi配置文件介绍](https://www.iteye.com/blog/heipark-1847421)