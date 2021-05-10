## 基于官方php-fpm镜像，添加扩展gd、ldap
- Dockerfile文件
  ```file
  FROM php:7.4-fpm
  RUN apt-get update && apt-get install -y \
          libfreetype6-dev \
          libjpeg62-turbo-dev \
          libpng-dev \
          libldap2-dev \
      && docker-php-ext-configure gd --with-freetype   --with-jpeg \
      && docker-php-ext-install -j$(nproc) gd \
      && docker-php-ext-configure ldap \
      && docker-php-ext-install -j$(nproc) ldap
  docker build . -t php:7.4-fpm-ext
  ```
### ltb工具，Service Desk
- 需要安装smarty-v3的版本
  ```bash
  wget https://github.com/smarty-php/smarty/archive/refs/tags/v3.1.39.tar.gz
  tar xf v3.1.39.tar.gz
  mkdir -p /usr/share/php/smarty3/
  cp -r smarty-3.1.39/libs/* /usr/share/php/smarty3/
  ```
- 需要使用php-5.6以上的版本，使用php-7.4的容器镜像拉起php-fpm
  ```bash
  wget https://ltb-project.org/archives/ltb-project-service-desk-0.3.tar.gz
  tar xf ltb-project-service-desk-0.3.tar.gz
  mv ltb-project-service-desk-0.3 /var/www/html
  # 由于容器中，php-fpm使用www-data用户运行，而www-data的用户ID为33
  chown -R 33.33 /var/www/html
  ```
- nginx配置
  ```bash
  cat > service-desk.conf <<EOF
  server {
      listen       80;
      listen       443 ssl;
  
      ssl_certificate ssl/service-desk.crt;
      ssl_certificate_key ssl/service-desk.pem;
      ssl_session_timeout 5m;
      ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
  
      ssl_ciphers  HIGH:!aNULL:!MD5;
      ssl_prefer_server_ciphers on;
  
      server_name  sd.example.com;
      index        index.php index.htm index.html;
      root         /var/www/html/htdocs;
  
      location ~ \.php$ {
          include        fastcgi_params;
          fastcgi_pass   127.0.0.1:9000;
          fastcgi_index  index.php;
      }
  }
  EOF
  ```
- docker启动脚本
  ```bash
  docker run \
  --volume /var/www/html:/var/www/html \
  --volume /usr/share/php/smarty3:/usr/share/php/smarty3 \
  -p 9000:9000 \
  --detach 419f42dc8f0e
  ```