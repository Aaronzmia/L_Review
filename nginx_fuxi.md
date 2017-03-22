## 安装：
* 安装gcc gcc-c++ zlib zlib-devel openssl openssl-devel pcre pcre-devel
* 下载nginx：wget http://nginx.org/download/nginx-1.10.2.tar.gz
* 解压编译：
```
[root@node2.azt.com nginx-1.10.2]$useradd -r nginx
[root@node2.azt.com nginx-1.10.2]$tar -xf nginx-1.10.2.tar.gz
[root@node2.azt.com nginx-1.10.2]$cd nginx-1.10.2
[root@node2.azt.com nginx-1.10.2]$./configure --prefix=/usr/local/nginx --conf-path=/etc/nginx/nginx.conf --user=nginx --group=nginx --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx/nginx.pid --lock-path=/var/lock/nginx.lock --with-http_ssl_module --with-http_stub_status_module --with-http_gzip_static_module --with-http_flv_module --with-http_mp4_module --http-client-body-temp-path=/var/tmp/nginx/client --http-proxy-temp-path=/var/tmp/nginx/proxy --http-fastcgi-temp-path=/var/tmp/nginx/fastcgi --http-uwsgi-temp-path=/var/tmp/nginx/uwsgi --http-scgi-temp-path=/var/tmp/nginx/scgi
```
* 输出结果
```
  nginx path prefix: "/usr/local/nginx"
  nginx binary file: "/usr/local/nginx/sbin/nginx"
  nginx modules path: "/usr/local/nginx/modules"
  nginx configuration prefix: "/etc/nginx"
  nginx configuration file: "/etc/nginx/nginx.conf"
  nginx pid file: "/var/run/nginx/nginx.pid"
  nginx error log file: "/var/log/nginx/error.log"
  nginx http access log file: "/var/log/nginx/access.log"
  nginx http client request body temporary files: "/var/tmp/nginx/client"
  nginx http proxy temporary files: "/var/tmp/nginx/proxy"
  nginx http fastcgi temporary files: "/var/tmp/nginx/fastcgi"
  nginx http uwsgi temporary files: "/var/tmp/nginx/uwsgi"
  nginx http scgi temporary files: "/var/tmp/nginx/scgi"
```
* 安装
```
[root@node2.azt.com nginx-1.10.2]$make && make install
```
* 创建目录
```
[root@node2.azt.com nginx-1.10.2]$mkdir -pv /var/tmp/nginx/{client,proxy,fastcgi,uwsgi}
mkdir: created directory `/var/tmp/nginx'
mkdir: created directory `/var/tmp/nginx/client'
mkdir: created directory `/var/tmp/nginx/proxy'
mkdir: created directory `/var/tmp/nginx/fastcgi'
mkdir: created directory `/var/tmp/nginx/uwsgi'
```

## 常用
* 启动：/usr/local/nginx/sbin/nginx
* 语法检查：/usr/local/nginx/sbin/nginx -tar
* 查看编译参数：/usr/local/nginx/sbin/nginx -V
* html：/usr/local/nginx/html

## 常用模块
ngx_http_core_module：一些核心的http参数配置，对应Nginx的配置为HTTP区块部分



## 配置文件解析
```
[root@node4.azt.com application]$egrep -v "#|^$" nginx/conf/nginx.conf.default    # 去掉#号注释和空白的行
worker_processes  1;                                # worker进程的数量
events {                                            # 事件区开始的
    worker_connections  1024;                       # 每个worker进程支持的最大连接数
}
http {                                              # HTTP区域
    include       mime.types;                       # Nginx支持的媒体类型库文件
    default_type  application/octet-stream;         # 默认的媒体类型
    sendfile        on;                             # 开启高效传输模式 
    keepalive_timeout  65;                          # 连接超时时长，默认60s
    server {                                        # 一个server表示一个独立的虚拟机站点
        listen       80;                            # 监听端口
        server_name  localhost;                     # 提供服务的域名主机名
        location / {                                # Nginx 中的 Location 指令 是NginxHttpCoreModule中重要指令。Location 指令，是用来为匹配的 URI 进行配置，URI 即语法中的”/uri/”，可以是字符串或正则表达式。
            root   html;                            # 站点的根目录，相当于Nginx的安装目录，html目录
            index  index.html index.htm;            # 默认的首页文件，多个用空格分开
        }
        error_page   500 502 503 504  /50x.html;    # 出现对应的http状态码时，访问50x.html
        location = /50x.html {                      # 指定50x.html的站点目录为html目录
            root   html;
        }
    }
}
```

## 虚拟主机
* Apache使用<VirtualHost>...</VirtualHost>，Nginx使用server{}标识一个虚拟机
* 基于域名
```
[root@node4.azt.com conf]$vim nginx.conf
    server_name  www.azt.com;
    location / {
        root   html/www;
        index  index.html index.htm;
    }
[root@node4.azt.com conf]$mkdir ../html/www
[root@node4.azt.com conf]$echo "http://www.azt.com" > ../html/www/index.html
[root@node4.azt.com conf]$cat ../html/www/index.html
http://www.azt.com
[root@node4.azt.com conf]$../sbin/nginx -t                                                  # 语法检查，重要
nginx: the configuration file /application/nginx-1.10.2//conf/nginx.conf syntax is ok
nginx: configuration file /application/nginx-1.10.2//conf/nginx.conf test is successful
[root@node4.azt.com conf]$../sbin/nginx -s reload                                           # 配置文件重载

[root@node4.azt.com conf]$../sbin/nginx -t
nginx: the configuration file /application/nginx-1.10.2//conf/nginx.conf syntax is ok
nginx: configuration file /application/nginx-1.10.2//conf/nginx.conf test is successful
[root@node4.azt.com conf]$../sbin/nginx -s reload
```
* 基于端口，常用于公司内部网站
* 基于IP
* 虚拟主机别名：Apache使用ServerAlias，nginx直接在server_name后面添加，以空格分割

## 常用优化
* 虚拟主机：include vhosts/*.conf，将所有虚拟主机配置文件放在vhosts目录下，以.conf后缀名保存

## Nginx状态信息
* ngx_http_stub_status_module模块：需要在编译中加入--with-http_stub_status_module
* 基本配置
```
## status
server{
  listen  80;
  server_name  status.azt.com;
  location / {
    stub_status on;                   # 打开状态信息的开关
    access_log off;
  }
}
```
* 显示结果解析
```
Active connections: 3                 # 表示nginx正在处理的活动连接数
server accepts handled requests       
 18 18 15                             # 第一个Nginx从启动到现在共处理的连接数，第二个成功创建了多少次握手，总共处理了多少次请求
                                      # 请求丢失数=握手-处理连接数
Reading: 0 Writing: 1 Waiting: 2      # Reading为Nginx读取到客户端的Header信息数，Writing为返回给客户端的Header信息 数，Waiting为Nginx已经处理完正在等待下一次请求指令的驻留连接，在开启keep-alive的情况下，等于active-(Reading+Writing)
```

## Nginx错误日志
* 属于ngx_core_module的参数，error_log，可放在Main，也可放在不同的虚拟主机中单独记录
* 格式：error_log  file    level;
* level: [debug|info|notice|warn|error|crit|alert|emerg]
* main，http, server, location 

## Nginx访问日志
* ngx_http_log_module
* 语法格式：log_format   name    string...
* 默认格式
```
#log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
#                  '$status $body_bytes_sent "$http_referer" '
#                  '"$http_user_agent" "$http_x_forwarded_for"';


$remote_addr：访问网站的客户端地址
$remote_user：远程客户端用户名称
$time_local：记录访问时间和时区
$request：用户的http请求起始行信息
$status：http状态码，记录请求返回的状态，200,403,501
$body_bytes_sent：服务器发送给客户端的响应body字节数
$http_referer：记录此次请求从哪个链接访问过来，可以根据referer设置防盗链
$http_user_agent：记录客户端访问信息
$http_x_forwarded_for：当前端有代理服务器时，设置web节点记录客户端地址的配置，此参数生效的前提是代理服务器也进行了相关的x_forword_for设置

10.0.0.119 - - [04/Feb/2017:19:39:23 +0800] "GET / HTTP/1.1" 200 19 "-" "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.1; WOW64; Trident/4.0; SLCC2; .NET CLR 2.0.50727; .NET CLR 3.5.30729; .NET CLR 3.0.30729; Media Center PC 6.0; .NET4.0C; .NET4.0E; InfoPath.3)" "-"
```
* access_log格式参数
```
#access_log path [format [buffer=size] [gzip[=level]] [flush=time] [if=condition]];
#access_log off;

buffer=size：存放日志的缓冲区大小
flush=time：将缓冲区的日志刷到磁盘的时间   # buffer和flush可在高并发场景下提升网站访问性能
    eg：access_log logs/access_www.log main gzip buffer=32k flush=5s
gzip[=level]：压缩级别
if=condition：其他条件
access_log off：关闭日志记录
```
* http, server, location, if in location, limit_except
* 日志切割
```bash
#!/bin/bash
#for cut  nginx log 
Dateformat=`date +%Y%m%d`
Basedir="/application/nginx"
Nginxlogdir="$Basedir/logs"
Logname="access_www"
[ -d $Nginxlogdir ] && cd $Nginxlogdir || exit 1
[ -f ${Logname}.log ] || exit 1
/bin/mv ${Logname}.log ${Dateformat}_${Logname}.log
$Basedir/sbin/nginx -s reload
```

## Nginx location
* location指令的作用就是根据用户请求的URI来执行不同的应用
* 用法：location [ = | ~ | ~* | ^~ ] uri {...}
```
= ： 表示精确的URI匹配
~： 表示区分大小写的正则匹配
~*：表示不区分大小写的正则匹配
!~ && !~*：表示区分大小写不匹配的正则和不区分大小写的不匹配的正则
/：通用匹配，任何请求都会匹配到
```
* =的精确匹配优先级最高，^~次之，再次是按文件中顺序的正则匹配，/为默认匹配
```
#直接匹配网站根，通过域名访问网站首页比较频繁，使用这个会加速处理，官网如是说。
#这里是直接转发给后端应用服务器了，也可以是一个静态首页
# 第一个必选规则
location = / {
    proxy_pass http://tomcat:8080/index
}
# 第二个必选规则是处理静态文件请求，这是nginx作为http服务器的强项
# 有两种配置模式，目录匹配或后缀匹配,任选其一或搭配使用
location ^~ /static/ {
    root /webroot/static/;
}
location ~* \.(gif|jpg|jpeg|png|css|js|ico)$ {
    root /webroot/res/;
}
#第三个规则就是通用规则，用来转发动态请求到后端应用服务器
#非静态文件请求就默认是动态请求，自己根据实际把握
#毕竟目前的一些框架的流行，带.php,.jsp后缀的情况很少了
location / {
    proxy_pass http://tomcat:8080/
}
```

## Nginx rewrite
* 用于实现URL地址重写，需要PCRE软件的支持，通过Perl兼容正则表达式语法进行规则匹配，默认安装支持rewrite模块；
* 语法格式：rewrite REGEX REPLACEMENT [flag];
* server, location, if
```
last : 相当于Apache的[L]标记，表示完成rewrite，一般写在server和if中
break : 停止执行当前虚拟主机的后续rewrite指令集，一般写在location中
redirect : 返回302临时重定向，地址栏会显示跳转后的地址
permanent : 返回301永久重定向，地址栏会显示跳转后的地址
使用alias必须用last标记，使用proxy_pass指令要使用Break标记；
```
* eg： 
```
1. rewrite ^/.* http://www.azt.com/$1 permanent;    # 当用户访问azt.com及下面的任意内容时，永久重定向到www.azt.com对应的地址
2. 
```

## Nginx访问认证
* auth_basic string|off  : 用于设置认证提示字符串
* auth_basic_user_file file
* htpasswd需要借助于apache实现
```
[root@node4.azt.com conf]$yum install httpd -y
[root@node4.azt.com conf]$htpasswd -bc /application/nginx/conf/htpasswd aztest 123456
Adding password for user aztest
[root@node4.azt.com conf]$chmod 400 /application/nginx/conf/htpasswd
[root@node4.azt.com conf]$chown nginx /application/nginx/conf/htpasswd
[root@node4.azt.com conf]$cat /application/nginx/conf/htpasswd
aztest:tarRU/F9EJjRU
[root@node4.azt.com conf]$../sbin/nginx -t
nginx: the configuration file /application/nginx-1.10.2//conf/nginx.conf syntax is ok
nginx: configuration file /application/nginx-1.10.2//conf/nginx.conf test is successful
[root@node4.azt.com conf]$../sbin/nginx -s reload
```

## 403错误常见原因
* Nginx配置文件中没有配置默认首页参数，或者首页文件在站点目录下没有index index.php index.html index.htm;
* autoinddex on; 会让Nginx在找不到首页文件时，展示目录结构，一般不要使用
* 站点目录或内部的程序文件没有nginx的用户访问权限
* Nginx配置文件中设置了allow,deny等权限控制




# Nginx服务优化
## 隐藏版本信息
```
修改前
[root@node4.azt.com lib]$curl -I 10.0.0.34
HTTP/1.1 200 OK
Server: nginx/1.10.2
...
```
- 修改：在nginx.conf中http标签段中添加"server_tokens off;(可放在http, server, location)"
```
[root@node4.azt.com lib]$curl -I 10.0.0.34
HTTP/1.1 200 OK
Server: nginx
```

## 隐藏Nginx软件名及版本号
1) 修改$NGINX/src/core/nginx.h 
```
[root@node4.azt.com nginx]$cd ~/tools/nginx-1.10.2
[root@node4.azt.com nginx-1.10.2]$vim src/core/nginx.h
    #define NGINX_VERSION      "x.x.x"                     修改版本号显示
    #define NGINX_VER          "nginx/" NGINX_VERSION       修改nginx的软件名称
    #define NGINX_VAR          "NGINX"
``` 
2) 修改$NGINX/src/http/ngx_http_header_filter_module.c
```
[root@node4.azt.com nginx-1.10.2]$vim src/http/ngx_http_header_filter_module.c
     49 static char ngx_http_server_string[] = "Server: nginx" CRLF;        # 修改为要显示的软件名称
```
3) 修改$NGINX/src/http/ngx_http_special_response.c 
```
    22 "<hr><center>" NGINX_VER "</center>" CRLF
    29 "<hr><center>nginx</center>" CRLF
```
4) 重新编译Nginx升级
注：修改配置文件不同于修改模块，需要重启生效；
不停机修改配置：
```
[root@node4.azt.com nginx-1.10.2]$/application/nginx/sbin/nginx -V
[root@node4.azt.com nginx-1.10.2]$./configure ...
[root@node4.azt.com nginx-1.10.2]$make  # 注意不能make install

[root@node4.azt.com nginx-1.10.2]$cp /application/nginx/sbin/nginx /application/nginx/sbin/nginx.bak
[root@node4.azt.com nginx-1.10.2]$cp objs/nginx /application/nginx/sbin/nginx
cp: overwrite `/application/nginx/sbin/nginx'? y
cp: cannot create regular file `/application/nginx/sbin/nginx': Text file busy
[root@node4.azt.com nginx-1.10.2]$cp -f objs/nginx /application/nginx/sbin/nginx
cp: overwrite `/application/nginx/sbin/nginx'? y

[root@node4.azt.com nginx-1.10.2]$/application/nginx/sbin/nginx -t
nginx: the configuration file /application/nginx-1.10.2//conf/nginx.conf syntax is ok
nginx: configuration file /application/nginx-1.10.2//conf/nginx.conf test is successful
[root@node4.azt.com nginx-1.10.2]$/application/nginx/sbin/nginx -s reload

```
修改后结果
```
[root@node4.azt.com nginx-1.10.2]$curl -I 10.0.0.34
HTTP/1.1 200 OK
Server: AZWEB
```

## 更改Nginx服务的默认用户
1) 直接更改配置文件参数，修改默认'user nobody' -> 'user nginx nginx;'
2) 在编译Nginx时指定编译的用户和组：--user=nginx --group=nginx

## 优化Nginx服务的worker进程个数
* 服务配置文件参数：worker_processes 1;  #<==指定了Nginx要开启的进程数
* 建议配置为服务器`CPU核心数*2`
```
[root@node4.azt.com ~]$grep processor /proc/cpuinfo |wc -l            # 查看CPU总核心数
1
[root@node4.azt.com ~]$grep 'physical id' /proc/cpuinfo | sort | uniq | wc -l       # 查看CPU颗数
1
```

## 优化绑定不同的nginx进程到不同CPU上
```
worker_processes 4;
worker_cpu_affinity 0001 0010 0100 1000;     #CPU掩码
```

## Nginx事件处理模型优化
Nginx支持的工作模式有`select/poll/kqueue(BSD系统)/epoll/rtsig//dev/poll`
```
use epoll
[events段]
```

## 调整Nginx单个进程允许的客户端最大连接数
最大客户端连接数由worker_processes和worker_connections决定，即Max_client=worker_processes*worker_connections；进程的最大连接数受Linux系统进程的最大文件打开数限制，在执行操作系统命令"ulimit -HSn 65535"或配置相应文件后，worker_connections的设置才能生效；
```
worker_connections number
[evnets]
```

## 配置Nginx worker进程最大打开文件数
```
worker_rlimit_nofile 65535;
[主标签段]
```

## 优化服务器域名的散列表大小
```
server_names_hash_max_size 512;        # 默认为512kb, 一般是CPU L1的4-5倍；
server_names_hash_bucket_size size;    # 32|64|128, 
```

## 开启高效文件传输模式
```
sendfile on | off               # 开启文件高效传输模式，内核中，零拷贝；比read和write函数要高效，因为要拷贝到应用层才操作； 
tcp_nohush on | off             # 激活或禁用Linux上的TCP_CORK socket选项，仅在sendfile开启时开启才有效；可以允许把http response header和文件的开始部分放在一个文件发布，减少网络报文的数量；
tcp_nodelay on | off 
```

## 连接超时优化
```
keepalive_timeout timeout [header_timeout];
# keepalive可以使客户端到服务器已建立的连接一直工作不退出，当服务器有持续请求时，keep-alive会使用已经建立的连接提供服务，从而避免服务器重新建立新连接处理请求；
# 和HTTP响应header域的“keep-Alive：timeout=time”有关，这些header信息也会被客户端浏览器识别并处理，但非所有客户端都会按照服务器端的设置处理；
tcp_nodelay on | off;
# 提高I/O性能
# 默认情况下当数据发送时，内核并不会马上发送，可能会等待更多的字节组成一个数据包，这样可以提高I/O性能。但在发送字节很少的场景，会导致等待更长时间
client_header_timeout time(15)
# 设置读取客户端请求头数据的超时时间，默认值60
# 设置读取客户端请求头数据的超时时间，如果这个超时时间内，客户端没有发送任何数据，返回"Request time out(408)"错误
client_body_timeout 15;
# 设置读取客户端请求主体的超时时间，默认值60
# 设置读取客户端请求主体的超时时间，这个超时仅仅为两次成功的读取操作之间的一个超时，非请求整个主体数据的超时时间，如果这个超时时间内，客户端没有发送任何数据，返回"Request time out(408)"错误
send_timeout 25;
# 响应客户端的超时时间
# 超时关闭
```

## 上传文件大小的限制
```
client_max_body_size 8m;
# 设置最大的允许的客户端请求主体大小，在请求头域有“Content-Length”，如果超过，客户端会收到413错误，即请求条目过大，有可能浏览器不能正确显示；0表示禁止
```

## FastCGI相关参数优化
```
fastcgi_cache_path /usr/local/nginx/fastcgi_cache levels=1:2 keys_zone=TEST:10m inactive=5m;    
fastcgi_connect_timeout 60;     # 表示Nginx服务器和后端FastCGI服务连接的超时时间，默认60；建立的连接越多，越消耗资源
fastcgi_send_timeout 60;        # 设置Nginx允许FastCGI服务器端返回数据的超时时间，即在规定时间之内后端服务器必须传完所有的数据，否则，Nginx将断开这个链接；
fastcgi_read_timeout 60;        # 设置Nginx从FastCGI服务器端读取响应信息的超时时间，表示连接建立成功后，Nginx等待后端服务器的响应时间，是Nginx已经进入后端的排队之中等候处理的时间
fastcgi_buffer_size 64k;        # Nginx FastCGI的缓冲区大小参数，设定用来读取从FastCGI服务器端收到的第一部分响应信息的缓冲区大小，这里的第一部分通常会包含一个小的响应头部。默认情况下，这个参数是由fastcgi_buffers指定的一个缓冲区大小；    
fastcgi_buffers 4 64k;          # 设定用来读取从FastCGI服务器端收到的信息的缓冲区大小和缓冲区数值，默认值为fastcgi_buffers 8 4k|8k; 如果一个PHP脚本所产生的页面大小为256KB，那么会为其分配4个64KB的缓冲区来缓存；如果页面大小大于256KB，那么大于256KB的部分会缓存到fastcgi_temp指定的路径中，但是这并不是好方法，因为内存中的数据处理速度要快于硬盘。一般这个值应该为站点中PHP脚本所产生的页面大小的中间值，如果站点大部分脚本所产生的页面大小为256KB，那么可以把这个值设置为“16 16k”、“4 64k”等;
fastcgi_busy_buffers_size 128k;         # 设置系统忙时可以使用的proxy_buffers大小，推荐proxy_buffers*2
fastcgi_temp_file_write_size 128k;      # 临时文件大小，可设置为128 ~ 256k
fastcgi_cache TEST;                     # 开启FastCGI缓存并为其指定一个名称。开启缓存非常有用，可以有效降低CPU的负载，并且防止502错误的发生。但是开启缓存也会引起很多问题，要视具体情况而定;
fastcgi_cache_valid 200 302 1h;         # 指定应答代码的缓存时间。实例中的值表示将200和302应答缓存一个小时，将301应答缓存1天，其他应答均缓存1分钟；
fastcgi_cache_valid 301 1d;             # 301缓存一天
fastcgi_cache_valid any 1m;             # 其他缓存1分钟
fastcgi_cache_path /var/logs/nginx/fastcgi_cache_dir levels=1:2 keys_zone=cache_fastcgi:128m inactive=1d max_size=10g;          # 为FastCGI缓存指定一个路径，目录结构等级，关键字区域存储时间和非活动删除时间；1:2会生成128*256个子目录
```
常见配置
```
1) nginx.conf
[root@node4.azt.com ~]$cat /application/nginx/conf/nginx.conf
worker_processes  4;
events {
    worker_connections  1024;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;
	tcp_nopush on;
	tcp_nodelay on;
	client_header_timeout 15;
	client_body_timeout 15;
	send_timeout 15; 

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                  '$status $body_bytes_sent "$http_referer" '
                  '"$http_user_agent" "$http_x_forwarded_for"';
    server_tokens off;

	fastcgi_cache_path /usr/local/nginx/fastcgi_cache levels=1:2
                keys_zone=ngx_fcgi_cache:10m
                inactive=5m;
    fastcgi_connect_timeout 300;
    fastcgi_send_timeout 300;
    fastcgi_read_timeout 300;
    fastcgi_buffer_size 16k;
    fastcgi_buffers 16 16k;
    fastcgi_busy_buffers_size 16k;
    fastcgi_temp_file_write_size 16k;
    fastcgi_cache_use_stale error timeout invalid_header http_500;
	
    include extra/www.conf;
    include extra/status.conf;
    include extra/ibangqi.conf;
    include extra/blog.conf;
}

2) 主机配置
location ~ .*\.(php|php5)?$ {
            root  html/blog;
            fastcgi_pass 127.0.0.1:9000;
            fastcgi_index index.php;
            include fastcgi.conf;
            fastcgi_cache ngx_fcgi_cache;
            fastcgi_cache_valid 200 302 1h;
            fastcgi_cache_valid 301 1d;
            fastcgi_cache_valid any 1m;
            fastcgi_cache_min_uses 1;
            fastcgi_cache_key http://$host$request_uri;
        }
```

## Nginx gzip压缩
* 提升网站性能，节约带宽成本
* 纯文本文件压缩比很高，最好进行压缩，如：html、js、css、xml、shtml格式的文件；
* 被压缩的文件必须要大于1KB，由于压缩算法等特殊原因，极小的文件压缩后可能反而变大；
* 图片、视屏文件尽量不要压缩
```
gzip on           
# 开启压缩功能
gzip_min_length 1k;
# 设置允许压缩的页面最小字节数，从header头的conten-length中获取，默认为0，全部压缩；
gzip_buffers 4 32k;
# 压缩缓冲区大小，表示申请4个32k的内存作为压缩结果流缓存，默认值是申请与原始数据大小相同的内存空间来存储gzip压缩结果；
gzip_comp_level 9;
# 压缩比大小， 1-9，压缩比越大，传输速度快，但处理越慢
gzip_types text/css text/xml application/javascript;
# 指定压缩的类型，text/html总是会被压缩
gzip_vary on
# vary header支持，该选项可以让前端的缓存服务器缓存经过gzip压缩的页面，例如用squid缓存经过Nginx压缩的数据
```

## Nginx expires
```
expires TIME
```

## Nginx日志优化

## 站点目录及文件URL访问控制
```
1、禁止解析指定目录下的指定程序
location ~ ^/images/.*\.(php|php5|sh|pl|py)$
    {
        deny all;
    }
location ~ ^/static/.*\.(php|php5|sh|pl|py)$
    {
        deny all;
    }
location ~ ^/data/(atta/avta)/.*\.(php|php5)$
    {
        deny all;
    }
注：对上述的限制必须写在Nginx处理PHP服务配置的前面
2、禁止访问*.txt和*.doc文件
location ~* \.(txt|doc)$ {
    if (-f request_filename) {
        root /data/www/www;
        # rewrite ...   # 可以重定向到某位上URL
        break
    }
}
location ~* \.(txt|doc)$ {
    root /data/...;
    deny all;
}

3、禁止访问指定的单个目录
location ~ ^/(static)/ {
    deny all;
}
location ~ ^/static {
    deny all;
}

4、禁止访问多个目录
location ~ ^/(static|js) {
    deny all;
}

5、禁止访问目录并返回指定的HTTP状态码
location /xxx/ {return 404; }

6、限制网站来源IP访问：ngx_http_access_module
allow 
deny

7、反向代理时限制客户IP
if ( $remote_addr = 10.0.0.7 ){
    return 403;
}
if ( $remote_addr = 218.247.17.132 ) {
    set $allow_access_root 'true';
}

8、禁止非法域名解析访问企业网站
server {
    listen 80 default_server;
    server_name _;
    return 501;
}
server {
    listen 80 default_server;
    server_name _;
    return 501;     # 直接返回501
}
server {
    listen 80 default_server;
    server_name _;
    rewrite ^(.*) http://xxxx/$1 permanent;
}
域名恶意解析到公司的服务器IP，在server标签加入以下代码
if ($host !~ ^www/.xxx/.com$) {
    rewrite ^(.*) http://xxxx/$1 permanent;
}
```
## Nginx web服务实现防盗链
```
location ~* \.(jpg|gif|png|swf|flv|wma|wmv|asf|mp3|mmf|zip|rarr)$ {
    valid_referers none blocked *.xxxx.org xxx.org          # 可以正常访问的请求
if ($invalid_referer) { 
    rewrite ^/ http://www.xxx./sss/sss.jpg;
    }
}
access_log off 
expires 1d

location ~* \.(jpg|gif|png|swf|flv|wma|wmv|asf|mp3|mmf|zip|rarr)$ {
    valid_referers none blocked *.xxxx.org xxx.org          # 可以
if ($invalid_referer) { 
    return 403
    }
}
```

## 控制Nginx并发连接数量
* limit_conn_zone key zone=name:size;    <http中>
设置共享内存区域，key可以是字符串、Nginx自带变量或前两个组合，如$binary_remote_addr、$server_name。name为内存区域的名称，size为大小；
* limt_conn zone number;
用于指定key设置的最大连接数；

## 速率
* limit_req_zone key zone=name rate=rate;
* limit_req zone=name [burst=num][nodelay];