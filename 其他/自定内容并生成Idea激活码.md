## 自定内容并生成Idea激活码
- Code怎么来的?
  > 访问: https://data.services.jetbrains.com/products?fields=code,name,description，你将看到以下信息
- 生成WebStorm、PyCharm的许可
```bash
curl -XPOST https://jetbra.noviceli.win/generateLicense -d
{
    "licenseeName": "abc",
    "assigneeName": "abc",
    "products": [
        {
            "code": "PCWMP",
            "fallbackDate": "2030-09-14",
            "paidUpTo": "2030-09-14"
        },
        {
            "code": "PC",
            "fallbackDate": "2030-09-14",
            "paidUpTo": "2030-09-14"
        },
        {
            "code": "PSI",
            "fallbackDate": "2030-09-14",
            "paidUpTo": "2030-09-14"
        }
    ]
}
```
---
### 参考连接
- [自定内容并生成Idea激活码](https://linux.do/t/topic/1798)