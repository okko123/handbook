# openssl验证ssl、tls的https证书
## Check TLS/SSL Of Website
openssl s_client -connect poftut.com:443

## Check TLS/SSL Of Website with Specifying Certificate Authority
openssl s_client -connect poftut.com:443 -CAfile /etc/ssl/CA.crt

## Connect Smtp and Upgrade To TLS
openssl s_client -connect smtp.poftut.com:25 -starttls smtp

## Connect HTTPS Site Disabling SSL2
openssl s_client -connect poftut.com:443 -no_ssl2

## Connect HTTPS Only TLS1 or TLS2
openssl s_client -connect poftut.com:443 -tls1_2

## Specify Cipher or Encryption Type
openssl s_client -connect poftut.com:443 -cipher RC4-SHA

## Connect HTTPS Only RC4-SHA
openssl s_client -connect poftut.com:443 -cipher RC4-SHA

## Debug SSL/TLS To The HTTPS
openssl s_client -connect poftut.com:443 -tlsextdebug

## 检测 SSL 证书过期时间
echo | openssl s_client -servername $NAME -connect "$host":443 2>/dev/null | openssl x509 -noout -dates

```bash
#! /bin/sh
 
host=$1
port=$2
end_date=`openssl s_client -host $host -port $port -showcerts </dev/null 2>/dev/null |
          sed -n '/BEGIN CERTIFICATE/,/END CERT/p' |
      openssl x509 -text 2>/dev/null |
      sed -n 's/ *Not After : *//p'`
# openssl 检验和验证SSL证书。
# </dev/null 定向标准输入，防止交互式程序Hang。从/dev/null 读时，直接读出0 。
# sed -n 和p 一起使用，仅显示匹配到的部分。 //,// 区间匹配。
# openssl x509 -text 解码证书信息，包含证书的有效期。
 
if [ -n "$end_date" ]
then
    end_date_seconds=`date '+%s' --date "$end_date"`
# date指令format字符串时间。
    now_seconds=`date '+%s'`
    echo "($end_date_seconds-$now_seconds)/24/3600" | bc
fi


有两个小地方可以改进下。
echo “HOST: test.com /r/n GET / HTTP/1.1″|openssl s_client -connect test.com:443 这样可以增加速度 因为 openssl s_client 只负责链接 后面是请求内容如果不输入的话就是等待超时。时间会很长。

增加一个参数 -servername 可一直开启 TLS SNI support ，可以检测一个ip 多个证书的情况。
```




## 查看证书信息
openssl x509 -in getssl.crt -noout -text



---
## 参考连接
- [How To Use OpenSSL s_client To Check and Verify SSL/TLS Of HTTPS Webserver?](https://www.poftut.com/use-openssl-s_client-check-verify-ssltls-https-webserver/)
- [监控SSL证书过期 Monitor SSL certificate expiry](http://noops.me/?p=945)