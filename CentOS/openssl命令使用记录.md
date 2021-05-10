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

## 查看证书信息
openssl x509 -in getssl.crt -noout -text
---
## 参考连接
- [How To Use OpenSSL s_client To Check and Verify SSL/TLS Of HTTPS Webserver?](https://www.poftut.com/use-openssl-s_client-check-verify-ssltls-https-webserver/)