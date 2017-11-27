# 集群
## 集群简介
    将多台主机按照同一个简单目的的组合在一起实现某一特定功能的计算机的集合即可以成为计算机集群；
    scale up：向上扩展，垂直扩展，使用性能更好的主机来取代当前性能较差的主机；价格跟废弃的问题
    cale out：向外扩展，横向扩展，一台服务器无法满足时，通过增加类似级别服务器的方式，提供相同服务，获得容量的提升；管理的问题，网络拓扑等问题 
## 集群特点
* 高性能
* 价格有效性-Cost-effectiveness，横向，扩充服务器
* 可伸缩性-Scalability，只需要将新的服务器加入现有的集群架构中
* 高可用性-Availability
* 透明性-Transparency
* 可管理性-Manageability
* 可编程性-Programmability
## 集群分类
* 负载均衡集群：Load Balancing，主要目标在于通过添加更多的主机来维持服务于更多用户请求，主要目的扩容，一定程度上提高可用性；调度器会成为单点故障；
* 高可用集群：High Avaliablity，在集群中的任意一个节点失效的情况下，该节点的所有资源(IP及服务)能够自动切换到其它正常的节点上；常用于不易实现负载均衡的应用，如负载均衡器，主数据库、主存储对之间；     
    A = 平均无故障时间/(平均无故障时间+平均修复时间)
    95%, 99%, 99.9%, 99.99%, 99.999%  要付出相应的代价；
* 高性能集群：High Performance    
    www.top500.org              
* 分布式系统：主机不是独立完整的，何在一起才是完整的  
    NoSQL：HBase，Redis  
    存储：MogileFS  
    文件系统：Ceph  


# Nginx负载均衡
## 区别
    LVS等负载均衡是转发用户请求的数据包，或者改写，而Nginx反向代理是接收用户的请求然后重新戴尔请求去请求后端节点，然后返回数据给用户； 
## 功能模块
* ngx_http_proxy_module：proxy代理模块，用于把请求后抛给服务器节点或upstream服务器池
* ngx_http_upstream_module：负载均衡模块，可以实现网站的负载均衡功能及节点的健康检查
## 示例
```
upstream bp_servers {
    # upstream关键字，bp_servers为Upstream集群组的名称
    server 192.168.10.205 weight=1;
    server 192.168.10.206 weight=1 max_fails=1 fail_timeout=10s;
    server 192.168.10.207 backup
}

server {
    listen 80;
    server_name bp.azt.com;
    location / {你
            proxy_pass http://bp_servers;
    }
}
```
## 参数说明
* Server指定后端主机，可以是IP:PORT也可以是域名
* weight=X ：服务器权重，默认为1，权重越大被分配的请求越多
* max_fails=1 ：Nginx尝试连接后端主机失败的次数，配合proxy_next_upstream、fastcgi_next_upstream和memcached_next_upstream这个三个参数使用，当Nginx接收后端服务器返回这三个参数定义的状态码时，会将这个请求转发给正常工作的后端服务器，例如404, 502, 503；
* backup指定为备份服务器，当上面的集群服务器都无法
* fail_timeout=10s：在max_fails定义的失败次数都是502后，距离下次检查的间隔时间
* down：标志服务器不可用

## 调度算法
* rr：轮询，静态算法，默认调度算法； 
    按客户请求逐一分配到不同的后端节点服务器，相当于lvs中的rr算法，如果后端服务器宕机，宕机的服务器会自动从节点池中删除，新的请求会分配给正常的服务器
* wrr：加权轮询，静态算法
    在rr轮询的算法中加上权重，权重与用户访问成正比，权重越大，被转发的请求也越多，要根据服务器的配置和性能指定权重大小；
* ip_hash：静态算法
    每个请求按IP的hash结果分配，当新的请求到达时，先将其客户端IP进行hash计算，只要hash值相同，就会被分配到同一个服务器，ip_hash可以解决动态网页的session共享问题；但由于企业NAT的原因，无法保证1:1的均衡；LVS的-p参数，keepalived配置里的persistence_timeout 50参数都与此类似；  
    当使用ip_hash时，weight及backup不生效
* fair：动态调度算法
    根据后端节点的响应时间来分配请求，响应时间短的优先分配。此算法可以根据页面大小和加载时间长短智能的进行负载均衡；
    Nginx本身不支持fair算法，需要下载upstream_fair模块
* least_conn：最短连接，动态算法
    根据后端节点的连接数来决定分配，哪个机器连接数少就分发到哪个服务器；
* url_hash：动态
    根据访问URL的hash结果来分配请求，让每个URL定向到同一个后端服务器，后端服务器为缓存服务器时效果显著，不支持weight等其他参数；  
    需安装Nginx的hash模块软件包
```
upstream NAME{
    server xxxx;
    server xxxx;
    hash $request_uri;
    hash_method crc32;
}
```
* 一致性hash：
    一般用于代理后端业务为缓存服务（squid、memcached）的场景，通过将用户请求的URI或者指定的字符串进行计算，然后调度到后端的服务器上，此后用户查找同一个URI或者指定字符串都会被调度到此服务器上，因此后端的每个节点缓存的内容是不同的，一致性hash算法可以解决后端某个或几个节点宕机后，缓存的数据动荡最小；Tengine支持
```
consistent_hash $request_uri
```

## http_proxy_module模块
    proxy_pass属于ngx_http_proxy_module模块，此模块可以将请求转发到另一台服务器，在实际的反向代理中，会通过location功能匹配指定的URI，然后把接收到的符合匹配uri的请求通过proxy_pass送到指定的upstream；  
    Nginx的代理功能是通过http proxy模块来实现的，默认安装时已经加载，可直接使用；
* proxy_set_header：设置http请求Header项传递给后端服务器节点，可实现让代理后端服务器节点获取访问客户端的信息
* client_body_buffer_size：指定客户端请求主体缓存区大小
* proxy_connect_timeout：反向代理与后端节点服务器连接的超时时间，即发起握手等候响应的超时时间；
* proxy_send_timeout：表示代理后端服务器的数据回传时间，即在规定时间内后端服务器必须传入所有的数据，否则，NGINX将断开；
* proxy_read_timeout：设置Nginx从代理的后端服务器获取信息的时间，表示建立连接后，Nginx等待后端服务器的响应时间，其实是Nginx进入后端的排队之中等候处理的时间； 
* proxy_buffer_size：设置缓冲区大小，默认该缓冲区的大小等于指令proxy_buffers设置的大小
* proxy_buffers：设置缓冲区数量的大小，Nginx从代理的后端服务器获取的响应信息，会放置到缓冲区
* proxy_busy_buffers_szie：设置系统繁忙时可以使用的Proxy_buffers大小，推荐为prxoy_buffers*2
* proxy_temp_file_write_size：指定proxy缓存临时文件的大小

### 常用配置：
    proxy_set_header Host $host：当后端服务器有多个虚拟主机时，可以识别代理的是哪个虚拟主机；
    proxy_set_header X-Forwared-For $remote_addr

## eg：根据请求URL的目录地址实现转发
```
location /static/ {
    proxy_pass http://static_pools;
    include proxy.conf;
}
location /upload/ {
    proxy_pass http://upload_pools;
    include proxy.conf;
}
location / {
    proxy_pass http://default_pools;       # 不符合上述规则的请求，全部丢入此处
    include proxy.conf;
}

实现2
if ($request_uri ~* "^/static/(.*)$") {
    proxy_pass http://static_pools/$1;
}
if ($request_uri ~* "^/upload/(.*)$") {
    proxy_pass http://upload_pools/$1;
}jut
location /  {
    proxy_pass http://default_pools/$1;
}
```
## 根据客户端设备(user_agent)转发
```
location / {
    if ($http_user_agent ~* "MSIE") {
        proxy_pass http://MSIE_POOLS;
    }
    if ($http_user_agent ~* "Chrome") {
        proxy_pass http://CHROME_POOLS;
    }
    proxy_pass http://OTHER_POOLS;
}

针对手机端
location / {
    if ($http_user_agent ~* "android") {
        proxy_pass http://AMDROID_POOLS;
    }
    if ($http_user_agent ~* "iphone") {
        proxy_pass http://IPHONE_POOLS;
    }
    proxy_pass http://OTHER_POOLS;
}
```
## 根据文件扩展名转发
```
location ~ .*.(gif|ipg|jpeg|png|bmp|swf|css|js)$ {
    proxy_pass http://XXXX;
}


if ($request_uri ~* ".*\.(php|php5)") {
    proxy_pass http://XXXXX
}
if ($request_uri ~* ".*\.(jsp|jsp*|do|do*)$") {
    proxy_pass http://XXXXXXXXX
}
```

## Nginx负载均衡健康检查
### 自带模块提供的max_fails及fail_timeout
    在实际应用当中，如果你后端应用是能够快速重启的应用，比如nginx的话，自带的模块是可以满足需求的。但是需要注意。如果后端有不健康节点，负载均衡器依然会先把该请求转发给该不健康节点，然后再转发给别的节点，这样就会浪费一次转发。
    可是，如果当后端应用重启时，重启操作需要很久才能完成的时候就会有可能拖死整个负载均衡器。此时，由于无法准确判断节点健康状态，导致请求handle住，出现假死状态，最终整个负载均衡器上的所有节点都无法正常响应请求。由于公司的业务程序都是java开发的，因此后端主要是nginx集群和tomcat集群。由于tomcat重启应部署上面的业务不同，有些业务启动初始化时间过长，就会导致上述现象的发生，因此不是很建议使用该模式。
    并且ngx_http_upstream_module模块中的server指令中的max_fails参数设置值，也会和ngx_http_proxy_module 模块中的的proxy_next_upstream指令设置起冲突。比如如果将max_fails设置为0，则代表不对后端服务器进行健康检查，这样还会使fail_timeout参数失效（即不起作用）。此时，其实我们可以通过调节ngx_http_proxy_module 模块中的 proxy_connect_timeout 指令、proxy_read_timeout指令，通过将他们的值调低来发现不健康节点，进而将请求往健康节点转移。
### 淘宝开发的nginx_upstream_check_module模块
    通过它可以用来检测后端 realserver 的健康状态。如果后端 realserver 不可用，则所以的请求就不会转发到该节点上；
    Tengine自带该模块，Nginx需要通过打补丁的方式将次模块添加到Nginx中；
    http://tengine.taobao.org/document_cn/http_upstream_check_cn.html
    
```
1、下载nginx_upstream_check_module模块
[root@node4.azt.com tools]$wget https://codeload.github.com/yaoweibin/nginx_upstream_check_module/zip/master
[root@node4.azt.com tools]$unzip master 
2、为nginx打补丁
[root@node4.azt.com tools]$cd nginx-1.10.2 # 进入nginx的源码目录
[root@node4.azt.com nginx-1.10.2]$patch -p1 < ../nginx_upstream_check_module-master/check_1.11.1+.patch 
# 装1.11以前版本均报错

[root@node4.azt.com nginx-1.10.2]$./configure --user=nginx --group=nginx --prefix=/application/nginx-1.10.2/ --with-http_stub_status_module --with-http_ssl_module --add_module=../nginx_upstream_check_module-master/
[root@node4.azt.com nginx-1.10.2]$make (注意：此处只make，编译参数需要和之前的一样)
[root@node4.azt.com nginx-1.10.2]$mv /application/nginx/sbin/nginx{,.bak}
[root@node4.azt.com nginx-1.10.2]$cp ./objs/nginx /application/nginx/sbin/

```
```
Syntax: check interval=milliseconds [fall=count] [rise=count] [timeout=milliseconds] [default_down=true|false] 
该指令可以打开后端服务器的健康检查功能；
- interval：向后端发送的健康检查包的间隔。
- fall(fall_count): 如果连续失败次数达到fall_count，服务器就被认为是down。
- rise(rise_count): 如果连续成功次数达到rise_count，服务器就被认为是up。
- timeout: 后端健康请求的超时时间。
- default_down: 设定初始时服务器的状态，如果是true，就说明默认是down的，如果是false，就是up的。默认值是true，也就是一开始服务器认为是不可用，要等健康检查包达到一定成功次数以后才会被认为是健康的。
- type：健康检查包的类型，现在支持以下多种类型
    - tcp：简单的tcp连接，如果连接成功，就说明后端正常。
    - ssl_hello：发送一个初始的SSL hello包并接受服务器的SSL hello包。
    - http：发送HTTP请求，通过后端的回复包的状态来判断后端是否存活。
    - mysql: 向mysql服务器连接，通过接收服务器的greeting包来判断后端是否存活。
    - ajp：向后端发送AJP协议的Cping包，通过接收Cpong包来判断后端是否存活。
- port: 指定后端服务器的检查端口。你可以指定不同于真实服务的后端服务器的端口，比如后端提供的是443端口的应用，你可以去检查80端口的状态来判断后端健康状况。默认是0，表示跟后端server提供真实服务的端口一样。该选项出现于Tengine-1.4.0。

check_keepalive_requests request_num：该指令可以配置一个连接发送的请求数，其默认值为1，表示Tengine完成1次请求后即关闭连接

Syntax: check_http_send http_packet：该指令可以配置http健康检查包发送的请求内容。为了减少传输数据量，推荐采用"HEAD"方法。
当采用长连接进行健康检查时，需在该指令中添加keep-alive请求头，如："HEAD / HTTP/1.1\r\nConnection: keep-alive\r\n\r\n"。 同时，在采用"GET"方法的情况下，请求uri的size不宜过大，确保可以在1个interval内传输完成，否则会被健康检查模块视为后端服务器或网络异常


Syntax: check_http_expect_alive [ http_2xx | http_3xx | http_4xx | http_5xx ] ：该指令指定HTTP回复的成功状态，默认认为2XX和3XX的状态是健康的

Syntax: check_shm_size size ：所有的后端服务器健康检查状态都存于共享内存中，该指令可以设置共享内存的大小。默认是1M，如果你有1千台以上的服务器并在配置的时候出现了错误，就可能需要扩大该内存的大小

Syntax: check_status [html|csv|json] ：显示服务器的健康状态页面。该指令需要在http块中配置。在Tengine-1.4.0以后，你可以配置显示页面的格式。支持的格式有: html、csv、 json。默认类型是html。
你也可以通过请求的参数来指定格式，假设‘/status’是你状态页面的URL， format参数改变页面的格式
    /status?format=html
    /status?format=csv
    /status?format=json
同时你也可以通过status参数来获取相同服务器状态的列表，比如：
    /status?format=html&status=down
    /status?format=csv&status=up

```

