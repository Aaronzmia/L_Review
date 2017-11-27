## 基本概念
* CAP：任何一个分布式只能满足其中的两者，而对于分布式数据系统，分区容忍性是基本要求，否则就失去了价值
    * 一致性(CONSISTENCY)，任何一个读操作总是能够读取之前完成的写操作。
    * 可用性(AVAILABILITY)， 每一次操作总是能够在确定的时间返回
    * 分区容忍性(PARTITION TOLERANCE)，在出现网络分区的情况下，仍然能够满足一致性和可用性
* ACID：评估一个存储引擎是否支持事务的标准， 
    * 原子性（Atomicity）
    * 一致性（Consistency）
    * 隔离性（Isolation）
    * 持久性（Durability）
* BASE：ACID的变种，可用性是通过容忍部分失败而不导致系统整体不可用而获得的
    * Basic Availability：基本可用
    * Soft-state ：软状态/柔性事务，可以理解为”无连接”的, 而 “Hard state” 是”面向连接”的
    * Eventual consistency：最终一致性，最终整个系统（时间和系统的要求有关）看到的数据是一致的

## 分布式存储/分布式文件系统
### 概念
* 集中式：共享存储(NAS/SAN)
* 分布式：存储是多个多节点提供的存储空间融合成的较大存储空间
* 专用的元数据节点：集中元数据存储到
* 无专用元数据节点：所有节点均完整存储元数据，数据节点存储了部分数据
### 分布式
* 文件系统：有文件系统接口
* 存储：无文件系统接口，通过API访问
### 常见实现
* GFS：Google File System，GFS擅长处理单个大文件，GFS+MapReduce （编程模型-运行框架-API）可以实现程序切割到多节点运行，实现分布式处理
* HDFS：Hadoop Distributed File System，根据GFS思想开发的，擅长处理单个大文件
    * 适用场景：数据不太多的在文件，百万级别的大文件
* TFS：Taobao File System；将元数据存储于关系数据库或其它高性能存储中，从而能维护海量文件元数据
* GluterFS：去中心化设计，没有专门的元数据节点；
* Ceph：Linxu内核级别实现的文件系统，而且已经被收录进内核；
* MooseFS：mfs
* MogileFS：性能好于MooseFS，Perl语言研发
* FastDFS：MogileFS的重写，C语言重写

## MogileFS
### MogileFS的架构
1. tracker：元数据节点，从database中检索/存储元数据，生成映射表存储于DB，并用于接收客户端请求，通过查询数据库对客户端提供后端所存储的真实文件位置
2. database：元数据的内容，可以理解为客户端来获取数据文件时提供的Key和真实存在存储里面的文件名的对照表
3. Storage Node：用于存储文件的节点
4. tracker收到客户端的请求，tracker通过查询DB节点，将客户端所请求的文件，对应Storage存储的位置在返回给客户端，客户端在通过拿到的文件名以及文件位置，再去Storage上查找
### MogileFS的特性
1. 应用层：无需特殊核心组件
2. 无单点失败
3. 自动文件复制
4. 传输中立，无特殊协议
5. 简单命名空间
6. Shared-Nothing
7. non-RAID
8. 不能追加写、随机写
9. Tracker Client传输(mogilefsd)，管理数据复制、删除、查询、修复以及监控
10. 数据通过HTTP/WebDAV服务上传到Storage node（mogstored
11. MySQL存储MogileFS元数据(命名空间、位置)
### MogileFS核心概念
1. Domain：一个Domain代表一个命名空间，就是一个目录
    * 一个MogileFS可以有多个Domain
    * 用来存放不同文件(大小，类型)
    * 同一个Domain内，key必须唯一
    * 不同Domain内，Key可以相同
2. Class
    * 文件属性管理
    * 定义文件存储在不同设备上的份数
    * 用于将多个小文件合并成一个单独被冗余的复制单元，所以，在class级别，会存储多个副本
3. Domain + Fid 定位文件

### 安装使用MogileFS
* 环境：
    ```
    MogileFS节点：10.0.0.32 10.0.0.34 10.0.0.33
    database节点：10.0.0.33
    即是track也是storage node
    nginx: 10.0.0.41
    ```
1. 安装mogilefs
    ```
    MogileFS-Server-2.46-2.el6.noarch.rpm            
    MogileFS-Utils-2.19-1.el6.noarch.rpm  
    perl-Danga-Socket-1.61-1.el6.rf.noarch.rpm  
    perl-Perlbal-1.78-1.el6.noarch.rpm
    MogileFS-Server-mogilefsd-2.46-2.el6.noarch.rpm  
    Perlbal-1.78-1.el6.noarch.rpm         # 反代
    perl-MogileFS-Client-1.14-1.el6.noarch.rpm
    MogileFS-Server-mogstored-2.46-2.el6.noarch.rpm  
    Perlbal-doc-1.78-1.el6.noarch.rpm     
    perl-Net-Netmask-1.9015-8.el6.noarch.rpm

    [root@node2.azt.com mogilefs]$yum install MogileFS-* Perlbal-1.78-1.el6.noarch.rpm perl-* perl-IO-AIO  -y
    ```
2. Database节点配置
    * 安装mysql/mariadb
    * 授权
        ```
        mysql> GRANT ALL ON *.* TO 'root'@'10.0.0.%' IDENTIFIED BY 'redhat';
        Query OK, 0 rows affected (0.00 sec)

        mysql> CREATE DATABASE mogilefs;
        Query OK, 1 row affected (0.00 sec)

        mysql> GRANT ALL ON mogilefs.* TO 'moguser'@'10.0.0.%' IDENTIFIED BY 'mogpass';
        Query OK, 0 rows affected (0.00 sec)

        mysql> FLUSH PRIVILEGES;
        Query OK, 0 rows affected (0.00 sec)
        ```
    * 初始化mogilefs数据库
        [root@node3.azt.com ~]$mogdbsetup --dbhost=10.0.0.33 --dbrootpass='redhat' --dbuser='moguser' --dbpass='mogpass' --dbname=mogilefs --yes
3. Tracker 节点
    * 修改配置文件：/etc/mogilefs/mogilefs.conf
        ```
        daemonize = 1    # 是否运行为守护进程
        pidfile = /var/run/mogilefsd/mogilefsd.pid
        db_dsn = DBI:mysql:mogilefs:host=10.0.0.33     # 连接数据库数据源的连接方式
        db_user = moguser                            
        db_pass = mogpass
        listen = 10.0.0.33:7001
        conf_port = 7001
        query_jobs = 10                                # 查询线程程数量
        delete_jobs = 1                                     
        replicate_jobs = 5                             # 复制线程
        reaper_jobs = 1
        ```
    * 启动：
        service mogilefsd start
4. storage节点（可以是所有节点）
    * 创建设备目录，修改权限，生产应挂载独立分区
        [root@node3.azt.com ~]$mkdir -pv /data/mogilefs/dev1    # dev1名称不能更改
        [root@node3.azt.com ~]$chown -R mogilefs.mogilefs /data/mogilefs/dev1
    * 修改配置文件：/etc/mogilefs/mogstored.conf
        ```
        maxconns = 10000
        httplisten = 0.0.0.0:7500
        mgmtlisten = 0.0.0.0:7501
        docroot = /data/mogilefs
        ```
    * 启动：
        [root@node3.azt.com ~]$service mogstored start
5. tracker节点添加storage节点
    * mogadm check
    * 添加主机
        ```
        [root@node3.azt.com ~]$mogadm --trackers=10.0.0.33:7001 host add 10.0.0.33 --ip=10.0.0.33 --status=alive
        [root@node3.azt.com ~]$mogadm --trackers=10.0.0.33:7001 host add 10.0.0.32 --ip=10.0.0.32 --status=alive
        [root@node3.azt.com ~]$mogadm --trackers=10.0.0.33:7001 host add 10.0.0.34 --ip=10.0.0.34 --status=alive
        [root@node3.azt.com ~]$mogadm host list
        10.0.0.33 [1]: alive
        IP:       10.0.0.33:7500

        10.0.0.32 [2]: alive
        IP:       10.0.0.32:7500

        10.0.0.34 [3]: alive
        IP:       10.0.0.34:7500
        ```
    * 添加设备
        ```
        [root@node3.azt.com ~]$mogadm --trackers=10.0.0.33:7001 device add 10.0.0.32 1
        [root@node3.azt.com ~]$mogadm --trackers=10.0.0.33:7001 device add 10.0.0.34 2
        [root@node3.azt.com ~]$mogadm --trackers=10.0.0.33:7001 device add 10.0.0.33 3
        [root@node3.azt.com ~]$mogadm device list
        10.0.0.33 [1]: alive
                            used(G)    free(G)   total(G)  weight(%)
        dev3:   alive      2.908      6.310      9.218        100

        10.0.0.32 [2]: alive
                            used(G)    free(G)   total(G)  weight(%)
        dev1:   alive      4.741      4.477      9.218        100

        10.0.0.34 [3]: alive
                            used(G)    free(G)   total(G)  weight(%)
        dev2:   alive      5.878      3.340      9.218        100
        ```
    * 状态检查
        ```
        [root@node3.azt.com ~]$mogadm check
        Checking trackers...
        127.0.0.1:7001 ... OK

        Checking hosts...
        [ 1] 10.0.0.33 ... OK
        [ 2] 10.0.0.32 ... OK
        [ 3] 10.0.0.34 ... OK

        Checking devices...
        host device         size(G)    used(G)    free(G)   use%   ob state   I/O%
        ---- ------------ ---------- ---------- ---------- ------ ---------- -----
        [ 1] dev3             9.218      2.908      6.310  31.55%  writeable   0.4
        [ 2] dev1             9.218      4.742      4.476  51.44%  writeable   0.0
        [ 3] dev2             9.218      5.879      3.339  63.77%  writeable   0.0
        ---- ------------ ---------- ---------- ---------- ------
                    total:    27.654     13.529     14.125  48.92%
        ```
    * 创建domain: mogadm domain
        ```
        [root@node3.azt.com ~]$mogadm domain add images
        [root@node3.azt.com ~]$mogadm domain add files
        [root@node3.azt.com ~]$mogadm domain list
        domain               class                mindevcount   replpolicy   hashtype
        -------------------- -------------------- ------------- ------------ -------
        files                default                   2        MultipleHosts() NONE   

        images               default                   2        MultipleHosts() NONE   

        ```

    * 创建class，需要指定域和class，否则都存在default class，可指定--mindevcount， replpolicy
        ```
        [root@node3.azt.com ~]$mogadm class add images MZ 
        [root@node3.azt.com ~]$mogadm class add images else  [--mindevcount= ]
        [root@node3.azt.com ~]$mogadm class list
        domain               class                mindevcount   replpolicy   hashtype
        -------------------- -------------------- ------------- ------------ -------
        files                default                   2        MultipleHosts() NONE   

        images               MZ                        2        MultipleHosts() NONE   
        images               default                   2        MultipleHosts() NONE   
        images               else                      2        MultipleHosts() NONE   
        ```
    * 上传、获取文件
        ```
        [root@node3.azt.com ~]$mogupload --trackers=10.0.0.33 --domain images --class MZ --key='/mog_test.jpg' --file=/root/mog_test.jpg
        # 检查key
        [root@node3.azt.com ~]$moglistkeys --trackers=10.0.0.33 --domain images
        /mog_test.jpg
        # 获取数据
        [root@node3.azt.com ~]$mogfileinfo --trackers=10.0.0.33 --domain images --key='/mog_test.jpg'
        - file: /mog_test.jpg
            class:                   MZ
        devcount:                    2
            domain:               images
            fid:                    2
            key:        /mog_test.jpg
            length:               104783
        - http://10.0.0.33:7500/dev3/0/000/000/0000000002.fid
        - http://10.0.0.32:7500/dev1/0/000/000/0000000002.fid

        ```
 
 ## 使用Nginx反代MogileFS
 * 所需模块：nginx-mogilefs-module-1.0.4
 * 编译安装：
    ```
    [root@node11.azt.com tools]$ yum groupinstall "Development Tools" "Server Platform Developments"  
    [root@node11.azt.com tools]$ yum install pcre-devel openssl-devel -y 
    [root@node11.azt.com tools]$ tar xf nginx-1.10.3.tar.gz -C /usr/local/
    [root@node11.azt.com tools]$ tar xf nginx_mogilefs_module-1.0.4.tar.gz 
    [root@node11.azt.com tools]$ cd /usr/local/nginx-1.10.3/

    [root@node11.azt.com nginx-1.10.3]$ ./configure \
       --prefix=/usr/local/nginx \
       --conf-path=/etc/nginx/nginx.conf \
       --error-log-path=/var/log/nginx/error.log \
       --http-log-path=/var/log/nginx/access.log \
       --pid-path=/var/run/nginx/nginx.pid  \
       --lock-path=/var/lock/nginx.lock \
       --user=nginx \
       --group=nginx \
       --with-http_ssl_module \
       --with-http_flv_module \
       --with-http_stub_status_module \
       --with-http_gzip_static_module \
       --with-pcre \
       --with-debug \
       --add-module=/root/tools/nginx_mogilefs_module-1.0.4/

    [root@node11.azt.com nginx-1.10.3]$ make && make install
    ```
* 配置文件
    ```
    [root@node11.azt.com ~]$# vim /etc/nginx/nginx.conf

     upstream trackers {
                server 10.0.0.32:7001;
                server 10.0.0.33:7001;
                server 10.0.0.34:7001;
        }
    server {
        listen       80;
        server_name  localhost;

        #charset koi8-r;

        access_log  logs/bbs.access.log  main;

        location / {
            root   html;
            index  index.html index.htm;
        }

        location ~* /images {
                mogilefs_tracker trackers;
                mogilefs_domain images;
                mogilefs_methods GET;
                mogilefs_noverify on;

                mogilefs_pass {
                        proxy_pass $mogilefs_path;
                        proxy_hide_header Content-Type;
                        proxy_buffering off;
                }
        }
        location ~* /html/ {

            mogilefs_tracker trackers;
            mogilefs_domain html;
            mogilefs_pass  {
                proxy_pass $mogilefs_path;
                proxy_hide_header Content-Type;
                proxy_buffering off;
            }
        }
    }
    ```
* 测试语法，启动服务  
    [root@node11.azt.com nginx-1.12.0]$/usr/local/nginx/sbin/nginx -t
    nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
    nginx: configuration file /etc/nginx/nginx.conf test is successful
    [root@node11.azt.com nginx-1.12.0]$/usr/local/nginx/sbin/nginx
