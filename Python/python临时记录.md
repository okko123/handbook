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
### 参考信息
- [使用Python检查ssl证书过期时间](https://knktc.com/2021/06/20/use-python-to-check-ssl-expiry-date/)
- [Python脚本批量检查SSL证书过期时间](https://linuxeye.com/479.html)
- [Sort a list of numeric strings in Python](https://note.nkmk.me/en/python-sort-num-str/)
- [Python实用教程系列——Logging日志模块](https://zhuanlan.zhihu.com/p/166671955)