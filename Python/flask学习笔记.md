### Flask上下文全局变量
|变量名|上下文|说明|
|-|-|-|
|current_app|程序上下文|当前激活程序的程序实例|
|g|程序上下文|处理请求时用作临时存储的对象。每次请求都会重设这个变量|
|request|请求上下文|请求对象，封装了客户端发出的 HTTP 请求中的内容|
|session|请求上下文|用户会话，用于存储请求之间需要“记住”的值的词典|
- session: 只要设置，在任意请求中都能拿到，无论你拿多少次
- flash: 一旦设置，可在任意一次的请求中获取，但只能获取一次
- g: 在A路由中设置，只能在A路由的请求中获取，其他的请求都不能获取
### 请求钩子使用修饰器实现。Flask 支持以下 4 种钩子。
- before_first_request：注册一个函数，在处理第一个请求之前运行。
- before_request：注册一个函数，在每次请求之前运行。
- after_request：注册一个函数，如果没有未处理的异常抛出，在每次请求之后运行。
- teardown_request：注册一个函数，即使有未处理的异常抛出，也在每次请求之后运行。
在请求钩子函数和视图函数之间共享数据一般使用上下文全局变量 g。例如，before_
request 处理程序可以从数据库中加载已登录用户，并将其保存到 g.user 中。随后调用视
图函数时，视图函数再使用 g.user 获取用户。
请求钩子的用法会在后续章中介绍，如果你现在不太理解，也不用担心。

### boostrap 使用本地文件
app.config.setdefault('BOOTSTRAP_SERVE_LOCAL',True)

### 
- FLASK_APP=app_name
- FLASK_ENV=development|production
- FLASK_DEBUG=Ture