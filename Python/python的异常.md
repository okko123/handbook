## python的异常
- 异常的简单结构和复杂结构
```python
# 简单结构
try:
  pass
except Exception as e: #python2 中还可以这样写：except Exception,e
  pass

# 复杂结构
try:
  # 主代码块
  pass
except KeyError,e:
  # 异常时，执行该块
  pass
else:
  # 主代码块执行完，执行该块
  pass
finally:
  # 无论异常与否，最终执行该块
  pass

# 例子：先定义特殊提醒的异常，最后定义Exception,来确保程序正常运行。
s1 = 'hello'
try:
  int(s1)
except KeyError,e:
  print '键错误'
except IndexError,e:
  print '索引错误'
except Exception, e:
  print '错误'
```
---
### 参考信息
- [内置异常](https://docs.python.org/zh-cn/3.12/library/exceptions.html?highlight=exception)