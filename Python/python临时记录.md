### python 获取指定文件夹下所有文件名
- os.walk()可以用于遍历指定文件下所有的子目录、非目录子文件。
  ```python
  import os

  filePath = '/data'
  for i,j,k in os.walk(filePath):
      print(i,j,k)
  ```
- os.listdir()用于返回指定的文件夹下包含的文件或文件夹名字的列表，这个列表按字母顺序排序。
  ```python
  import os

  filePath = '/data'
  os.listdir(filePath)
  ```
---
### 使用pandas进行json2csv转换
```python
import pandas as pd

df = pd.read_json (r'/data/json/test.json')
删除指定列
df = df.drop(columns="area")

df.to_csv (r'/data/json/test.csv', index = None)
```
---
### 时间操作
- 生成当天0点的时间戳
  ```python
  import datetime

  # 方法1
  now = datetime.datetime.now()
  midnight = now.replace(hour=0, minute=0, second=0, microsecond=0)
  midnight_ts = midnight.timestamp()

  # 方法2
  today = datetime.date.today()
  _d = datetime.datetime.combine(today, datetime.time.min)
  _t = time.mktime(_d.timetuple())

  # 14天前
  t = datetime.date.today() - datetime.timedelta(days=14)
  
  def timestamp_to_str(timestamp):
      d = datetime.datetime.fromtimestamp(timestamp)
      s = d.strftime("%Y-%m-%d %H:%M:%S")
      return s

  datetime.datetime.now().date()
  datetime.date.today()
  datetime.time()

  datetime.date.today().strftime("%Y-%m-%d %H:%M:%S")
  ```
- 检查https证书的过期时间
  ```python
  import ssl
  import OpenSSL

  import datetime
  from pytz import timezone

  def get_ssl_expiry_date(host, port=443):
      """ get notAfter data from server cert """
      cert = ssl.get_server_certificate((host, port))
      x509 = OpenSSL.crypto.load_certificate(OpenSSL.crypto.FILETYPE_PEM, cert)
      return x509.get_notAfter().decode()

  # conf
  SRC_TZ = 'UTC'
  DST_TZ = 'Asia/Shanghai'

  def load_ssl_date(dt_string, pattern='%Y%m%d%H%M%SZ'):
      """ convert ssl date from string to datetime obj """
      src_tz = timezone(SRC_TZ)
      dst_tz = timezone(DST_TZ)
      dt = src_tz.localize(datetime.datetime.strptime(dt_string, pattern))
      return dt.astimezone(tz=dst_tz)
  ```
---
### 使用文件名中的数字进行排序
```python
import re

l = ['file10.txt', 'file1.txt', 'file5.txt']
s = sorted(l, key=lambda s: int(re.search(r'\d+', s)))
print(s)

```
---
### 字典对象格式化输出
```python
import json

d = {
    "name": "jack",
    "age": 10,
    "weight": 30
}

data = json.dumps(d, indent=4, sort_keys=False)
print(data)
```
---
### asyncio使用记录
```bash
Python 版本低于3.7
asyncio.run(main())
替换成
asyncio.get_event_loop().run_until_complete(main())
```
---
### logging模块使用记录
1. 打印控制台信息
   ```bash
   import logging

   logging.basicConfig(format='%(asctime)s - %(pathname)s[line:%(lineno)d] - %(levelname)s: %(message)s',
                       level=logging.DEBUG)
   logging.debug('debug 信息')
   logging.warning('只有这个会输出。。。')
   logging.info('info 信息')

   # 由于在logging.basicConfig()中的level 的值设置为logging.DEBUG, 所有debug, info, warning, error, critical 的log都会打印到控制台。
   日志级别： debug < info < warning < error < critical
   logging.debug('debug级别，最低级别，一般开发人员用来打印一些调试信息')
   logging.info('info级别，正常输出信息，一般用来打印一些正常的操作')
   logging.warning('waring级别，一般用来打印警信息')
   logging.error('error级别，一般用来打印一些错误信息')
   logging.critical('critical 级别，一般用来打印一些致命的错误信息,等级最高')
   # 所以如果设置level = logging.info()的话，debug 的信息则不会输出到控制台。
   ```
2. 利用logging.basicConfig()保存log到文件
   ```bash
   logging.basicConfig(level=logging.DEBUG,#控制台打印的日志级别
                       filename='new.log',
                       filemode='a',##模式，有w和a，w就是写模式，每次都会重新写日志，覆盖之前的日志
                       #a是追加模式，默认如果不写的话，就是追加模式
                       format=
                       '%(asctime)s - %(pathname)s[line:%(lineno)d] - %(levelname)s: %(message)s'
                       #日志格式
                       )
   ```
3. 既往屏幕输入，也往文件写入log
   > logging库采取了模块化的设计，提供了许多组件：记录器、处理器、过滤器和格式化器。
     - Logger 暴露了应用程序代码能直接使用的接口。
     - Handler将（记录器产生的）日志记录发送至合适的目的地。 
     - Filter提供了更好的粒度控制，它可以决定输出哪些日志记录。
     - Formatter 指明了最终输出中日志记录的布局。
   > Loggers:
     - Logger 对象要做三件事情。首先，它们向应用代码暴露了许多方法，这样应用可以在运行时记录消息。其次，记录器对象通过严重程度（默认的过滤设施）或者过滤器对象来决定哪些日志消息需要记录下来。第三，记录器对象将相关的日志消息传递给所有感兴趣的日志处理器。
     - 常用的记录器对象的方法分为两类：配置和发送消息。
     - 这些是最常用的配置方法：
       - Logger.setLevel()指定logger将会处理的最低的安全等级日志信息, debug是最低的内置安全等级，critical是最高的内建安全等级。例如，如果严重程度为INFO，记录器将只处理INFO，WARNING，ERROR和CRITICAL消息，DEBUG消息被忽略。
       - Logger.addHandler()和Logger.removeHandler()从记录器对象中添加和删除处理程序对象。处理器详见Handlers。
       - Logger.addFilter()和Logger.removeFilter()从记录器对象添加和删除过滤器对象。
    > Handlers
      - 处理程序对象负责将适当的日志消息（基于日志消息的严重性）分派到处理程序的指定目标。Logger 对象可以通过addHandler()方法增加零个或多个handler对象。举个例子，一个应用可以将所有的日志消息发送至日志文件，所有的错误级别（error）及以上的日志消息发送至标准输出，所有的严重级别（critical）日志消息发送至某个电子邮箱。在这个例子中需要三个独立的处理器，每一个负责将特定级别的消息发送至特定的位置。常用的有4种：
        1. logging.StreamHandler -> 控制台输出 
        2. logging.FileHandler  -> 文件输出
        3. logging.handlers.RotatingFileHandler -> 按照大小自动分割日志文件，一旦达到指定的大小重新生成文件 
        4.  logging.handlers.TimedRotatingFileHandler  -> 按照时间自动分割日志文件 
    > Formatters
      - Formatter对象设置日志信息最后的规则、结构和内容，默认的时间格式为%Y-%m-%d %H:%M:%S，下面是Formatter常用的一些信息

        |参数|解释|
        |---|---|
        |%(name)s|Logger的名字|
        |%(levelno)s|数字形式的日志级别|
        |%(levelname)s|文本形式的日志级别|
        |%(pathname)s|调用日志输出函数的模块的完整路径名，可能没有|
        |%(filename)s|调用日志输出函数的模块的文件名|
        |%(module)s|调用日志输出函数的模块名|
        |%(funcName)s|调用日志输出函数的函数名|
        |%(lineno)d|调用日志输出函数的语句所在的代码行|
        |%(created)f|当前时间，用UNIX标准的表示时间的浮 点数表示|
        |%(relativeCreated)d|输出日志信息时的，自Logger创建以 来的毫秒数|
        |%(asctime)s|字符串形式的当前时间。默认格式是 “2003-07-08 16:49:45,896”。逗号后面的是毫秒|
        |%(thread)d|线程ID。可能没有|
        |%(threadName)s|线程名。可能没有|
        |%(process)d|进程ID。可能没有|
        |%(message)s|用户输出的消息|
4. 例子
   ```bash
   import logging
   from logging import handlers
   
   class Logger(object):
       level_relations = {
           'debug':logging.DEBUG,
           'info':logging.INFO,
           'warning':logging.WARNING,
           'error':logging.ERROR,
           'crit':logging.CRITICAL
       }#日志级别关系映射
   
       def __init__(self,filename,level='info',when='D',backCount=3,fmt='%(asctime)s - %(pathname)s[line:%(lineno)d] - %(levelname)s: %(message)s'):
           self.logger = logging.getLogger(filename)
           format_str = logging.Formatter(fmt)#设置日志格式
           self.logger.setLevel(self.level_relations.get(level))#设置日志级别
           sh = logging.StreamHandler()#往屏幕上输出
           sh.setFormatter(format_str) #设置屏幕上显示的格式
           th = handlers.TimedRotatingFileHandler(filename=filename,when=when,backupCount=backCount,encoding='utf-8')#往文件里写入#指定间隔时间自动生成文件的处理器
           #实例化TimedRotatingFileHandler
           #interval是时间间隔，backupCount是备份文件的个数，如果超过这个个数，就会自动删除，when是间隔的时间单位，单位有以下几种：
           # S 秒
           # M 分
           # H 小时、
           # D 天、
           # W 每星期（interval==0时代表星期一）
           # midnight 每天凌晨
           th.setFormatter(format_str)#设置文件里写入的格式
           self.logger.addHandler(sh) #把对象加到logger里
           self.logger.addHandler(th)
   if __name__ == '__main__':
       log = Logger('all.log',level='debug')
       log.logger.debug('debug')
       log.logger.info('info')
       log.logger.warning('警告')
       log.logger.error('报错')
       log.logger.critical('严重')
       Logger('error.log', level='error').logger.error('error')
   ```
---
### 参考信息
- [使用Python检查ssl证书过期时间](https://knktc.com/2021/06/20/use-python-to-check-ssl-expiry-date/)
- [Python脚本批量检查SSL证书过期时间](https://linuxeye.com/479.html)
- [Sort a list of numeric strings in Python](https://note.nkmk.me/en/python-sort-num-str/)
- [Python实用教程系列——Logging日志模块](https://zhuanlan.zhihu.com/p/166671955)
- [AttributeError: module asyncio has no attribute run](https://blog.csdn.net/lly1122334/article/details/107708156)