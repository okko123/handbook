## 80 跳转https 443端口配置

server {
	listen 80 default_server;
	listen [::]:80 default_server;
	server_name _;
	return 301 https://$host$request_uri;
}

## php配置
server {
    listen       80;
    listen       443 ssl;

    server ltb.example.cn;
    ssl_certificate ssl/name.crt;
    ssl_certificate_key ssl/name.key;
    ssl_session_timeout 5m;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;

    ssl_ciphers  HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    server_name  ltb.qdama.cn;
    index        index.htm index.html index.php;
    root         /data/app/ltb-1.3;

    location ~ \.php$ {
        include        fastcgi_params;
        fastcgi_pass   unix:/dev/shm/php-fpm.sock;
        fastcgi_index  index.php;
    }
}
## fastcgi_params文件内容，主要修改SCRIPT_FILENAME
cat > fastcgi_params <<EOF
fastcgi_param  QUERY_STRING       $query_string;
fastcgi_param  REQUEST_METHOD     $request_method;
fastcgi_param  CONTENT_TYPE       $content_type;
fastcgi_param  CONTENT_LENGTH     $content_length;

fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;
fastcgi_param  REQUEST_URI        $request_uri;
fastcgi_param  DOCUMENT_URI       $document_uri;
fastcgi_param  DOCUMENT_ROOT      $document_root;
fastcgi_param  SERVER_PROTOCOL    $server_protocol;
fastcgi_param  REQUEST_SCHEME     $scheme;
fastcgi_param  HTTPS              $https if_not_empty;

fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
fastcgi_param  SERVER_SOFTWARE    nginx/$nginx_version;

fastcgi_param  REMOTE_ADDR        $remote_addr;
fastcgi_param  REMOTE_PORT        $remote_port;
fastcgi_param  SERVER_ADDR        $server_addr;
fastcgi_param  SERVER_PORT        $server_port;
fastcgi_param  SERVER_NAME        $server_name;

# PHP only, required if PHP was built with --enable-force-cgi-redirect
fastcgi_param  REDIRECT_STATUS    200;
EOF