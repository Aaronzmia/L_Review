# Mysql 5.5编译安装
1. 安装依赖
>       [root@node2.azt.com tools]$yum install ncurses-devel libaio-devel  
2. 安装cmake：mysql编译使用cmake取代make
>       [root@node2.azt.com tools]$yum install cmake -y
3. 创建帐号
>       [root@node2.azt.com tools]$useradd -s /sbin/nologin -M mysql
4. 编译安装mysql-5.5.54
```
[root@node2.azt.com tools]$tar xf mysql-5.5.54.tar.gz 
[root@node2.azt.com tools]$cd mysql-5.5.54
[root@node2.azt.com mysql-5.5.54]$cmake . -DCMAKE_INSTALL_PREFIX=/application/mysq-5.5.54 \
> -DMYSQL_DATADIR=/application-5.5.54/data \
> -DMYSQL_UNIX_ADDR=/application/mysql-5.5.54/tmp/mysql.sock \
> -DDEFAULT_CHARSET=utf8 \
> -DDEFAULT_COLLATION=utf8_general_ci \
> -DEXTRA_CHARSETS=gbk,gb2312,utf8,ascii \
> -DENABLED_LOCAL_INFILE=ON \
> -DWITH_INNOBASE_STORAGE_ENGINE=1 \
> -DWITH_FEDERATED_STORAGE_ENGINE=1 \
> -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
> -DWITHOUT_EXAMPLE_STORAGE_ENGINE=1 \
> -DWITHOUT_PARTITION_STORAGE_ENGINE=1 \
> -DWITH_FAST_MUTEXES=1 \
> -DWITH_FAST_MUTEXES=1 \
> -DWITH_ZLIB=bundled \
> -DENABLED_LOCAL_INFILE=1 \
> -DWITH_READLINE=1 \
> -DWITH_EMBEDDED_SERVER=1 \
> -DWITH_DEBUG=0
[root@node2.azt.com tools]$make && make install
[root@node2.azt.com application]$ln -sv mysq-5.5.54/ mysql
```

# Mysql单机多实例
##. 单一配置文件、单一启动程序多实例
```
[mysqld_multil]
mysqld    = /usr/bin/mysqld_safe
mysqladmin = /usr/bin/mysqladmin
user    = mysql

[mysqld1]
socket  = /var/lib/mysql/mysql.sock
port    = 3306
pid-file  = /var/lib/mysql/mysql.pid
datadir   = /var/lib/mysql/
user      = mysql

[mysqld2]
socket    =/mnt/data/db1/mysql.sock
port      = 3302
pid-file  = /mnt/data/db1/mysql.pid
datadir   = /mnt/data/db1/
user      = mysql

skip-name-resolve
server-id=10
dafault-storage-engine=innodb
innodb_buffer_pool_size=512M
innodb_additional_mem_pool=10M
default_character_set=utf8
character_set_server=utf8
#read-only
relay-log-space-limit=3G
expire_logs_day=20

启动命令：
mysqld_multi --config-file=/data/mysql/my_multi.cnf start 1,2
缺陷：耦合度太高，不好管理
```

##. 多配置文件、多启动程序部署
1. 创建多实例的数据文件目录
```
[root@node2.azt.com application]$mkdir -pv /data/{3306,3307}/data  
[root@node2.azt.com application]$chown -R mysql.mysql /data
```
2. 创建多实例配置文件
```
vim /data/3306/my.cnf
[client]
port            = 3306
socket          = /data/3306/mysql.sock

[mysql]
no-auto-rehash

[mysqld]
user    = mysql
port    = 3306
socket  = /data/3306/mysql.sock
basedir = /application/mysql
datadir = /data/3306/data
open_files_limit    = 1024
back_log = 600
max_connections = 800
max_connect_errors = 3000
table_cache = 614
external-locking = FALSE
max_allowed_packet =8M
sort_buffer_size = 1M
join_buffer_size = 1M
thread_cache_size = 100
thread_concurrency = 2
query_cache_size = 2M
query_cache_limit = 1M
query_cache_min_res_unit = 2k
#default_table_type = InnoDB
thread_stack = 192K
#transaction_isolation = READ-COMMITTED
tmp_table_size = 2M
max_heap_table_size = 2M
long_query_time = 1
pid-file = /data/3306/mysql.pid
log-bin = /data/3306/mysql-bin
relay-log = /data/3306/relay-bin
relay-log-info-file = /data/3306/relay-log.info
binlog_cache_size = 1M
max_binlog_cache_size = 1M
max_binlog_size = 2M
expire_logs_days = 7
key_buffer_size = 16M
read_buffer_size = 1M
read_rnd_buffer_size = 1M
bulk_insert_buffer_size = 1M
lower_case_table_names = 1
skip-name-resolve
slave-skip-errors = 1032,1062
replicate-ignore-db=mysql

server-id = 1

innodb_additional_mem_pool_size = 4M
innodb_buffer_pool_size = 32M
innodb_data_file_path = ibdata1:128M:autoextend
innodb_file_io_threads = 4
innodb_thread_concurrency = 8
innodb_flush_log_at_trx_commit = 2
innodb_log_buffer_size = 2M
innodb_log_file_size = 4M
innodb_log_files_in_group = 3
innodb_max_dirty_pages_pct = 90
innodb_lock_wait_timeout = 120
innodb_file_per_table = 0
[mysqldump]
quick
max_allowed_packet = 2M

[mysqld_safe]
log-error=/data/3306/mysql_3306.err        # 此处文件需要创建，否则可能启动不了
pid-file=/data/3306/mysqld.pid
```
3. 提供启动脚本
```

#!/bin/bash
#

port=3306                # 修改此处端口即可
mysql_user=root
mysql_pwd="redhat"
cmd_path="/application/mysql/bin"
mysql_sock="/data/${port}/mysql.sock"

# start
start() {
  if [ ! -e "${mysql_sock}" ]; then
    printf "Starting MySQL...\n"
    ${cmd_path}/mysqld_safe --defaults-file=/data/${port}/my.cnf &> /dev/null   &   
  else
    printf "MySQL is Running...\n"
    exit
  fi
}

# stop function
stop() {
  if [ ! -e "${mysql_sock}" ]; then
    printf "MySQL is stopped...\n"
    exit
  else
    printf "Stopping MySQL...\n"
    ${cmd_path}/mysqladmin -u ${mysql_user} -p${mysql_pwd} -S /data/${port}/mysql.sock shutdown
  fi
}

# restart function
restart() {
  printf "Restarting MySQL...\n"
  stop
  sleep 5
  start
}

case $1 in
start)
  start
;;
stop)
  stop
;;
restart)
  restart
;;
*)
  printf "Usage: /data/${port}/mysql {start|stop|restart}\n"
esac


[root@node2.azt.com application]$find /data -name mysql |xargs chmod 700      # 修改执行权限
```

4. 初始化数据库
[root@node2.azt.com scripts]$./mysql_install_db  --basedir=/application/mysql --datadir=/data/3307/data --user=mysql
[root@node2.azt.com scripts]$./mysql_install_db  --basedir=/application/mysql --datadir=/data/3306/data --user=mysql

5. 启动数据库
[root@node2.azt.com scripts]$/data/3306/mysql start
[root@node2.azt.com scripts]$/data/3307/mysql start

6. 连接数据库
[root@node2.azt.com scripts]$mysql -S /data/3306/mysql.sock

## Mysql编译参数
1. 5.5
```
cmake \
-DCMAKE_INSTALL_PREFIX：PATH：指定数据库的安装路径。
-DMYSQL_DATADIR：指定数据的存储目录。
-DMYSQL_UNIX_ADDR：指定sock的文件。
-DDEFAULT_CHARSET：默认字符集。
-DDEFAULT_COLLATION：默认排序字符集。
-DWITH_MYISAM_STORAGE_ENGINE：开启MYISAM引擎。
-DWITH_INNOBASE_STORAGE_ENGINE：开启InnoDB引擎。

cmake -DCMAKE_INSTALL_PREFIX:PATH=/data/mysql/example 
-DMYSQL_DATADIR=/data/mysql/example/db 
-DMYSQL_UNIX_ADDR=/data/mysql/example/logs/mysql.sock 
-DDEFAULT_CHARSET=utf8 
-DDEFAULT_COLLATION=utf8_general_ci 
-DWITH_MYISAM_STORAGE_ENGINE=1 
-DWITH_INNOBASE_STORAGE_ENGINE=1 
-DWITH_READLINE=1 -DENABLED_LOCAL_INFILE=1
```
2. 5.6
```
·CMAKE_BUILD_TYPE：指定产品编译说明信息。
·CMAKE_INSTALL_PREFIX：PATH：指定数据库的安装路径。
·MYSQL_DATADIR：指定数据的存储目录。
·DEFAULT_CHARSET：默认字符集。
·DEFAULT_COLLATION：默认排序字符集。
·WITH_MYISAM_STORAGE_ENGINE：开启MYISAM引擎。
·WITH_INNOBASE_STORAGE_ENGINE：开启InnoDB引擎。
·WITH_SSL：是否支持SSL。
·CMAKE_EXE_LINKER_FLAGS：指定使用jemalloc管理内存。

cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=/data/mysql/example -DMYSQL_DATADIR=/data/mysql/example/db -DSYSCONFDIR=/data/mysql/example/my.cnf -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DENABLE_DEBUG_SYNC=0 -DENABLED_LOCAL_INFILE=1 -DENABLED_PROFILING=1 -DMYSQL_UNIX_ADDR=/data/mysql/example/logs/mysql.sock -DWITH_DEBUG=0 -DWITH_SSL=yes -DWITH_SAFEMALLOC=OFF -DWITH_BDB=1 -DWITH_blackhole-storage=1 -DCMAKE_EXE_LINKER_FLAGS="-ljemalloc" 
```

# Mysql主从复制
## 概述
  MySQL数据库支持单向、双向、链式级联、环状等不同业务场景的复制。在复制过程中，一台服务器充当Master，接收来自用户的内容更新，而一个或多个其他的服务器充当Slave，接收来自主服务器binlog文件的日志内容，解析出SQL，更新到自己的服务器，使得主从保持一致；如果设置了链式级联复制，从服务器除了充当从服务器外，也会充当其下面从服务器的主服务器，类似A -> B -> C的复制方式；
  * 单向主从模式：只能在MAster端写入数据；
  * 双向主主复制逻辑架构：可以在Master1或者Master2端进行数据写入，或者两端同时写入数据（需要特殊设置）；
  * 线性级联单向主从复制：只能在master1端数据写入; 工作场景，Master1和Master2作为主主互备，slave1作为从库；
    * master1 ----> master2 -----> slave1
  * 环状级联单向多主同步：任意节点写入，复杂，一般情况慎用
## 应用场景
  1. 从服务器作为主服务器的实时数据备份
  * 主从服务器实现读写分离，从服务器实现负载均衡
    主从架构可以通过程序（PHP，JAVA等）或代理软件（mysql-proxy、Amodeba）实现对用户的请求读写分离，让从服务器只主力用户的select查询请求，降低用户查询响应时间，减少主服务器压力；对于更新数据的(update,insert,delete语句)写入操作，仍然交给主服务器处理，确保主服务器和从服务器保持实时同步；从服务器可以扩展，LVS负载均衡；
  * 多个服务器根据业务重要性进行拆分访问
## 实现方案
  1. 通过程序实现读写分离，效率和性能最佳
  * 通过开源软件实现，Mysql-Proxy、amoeba，稳定和功能性一般，不建议生产使用
  * 大型门户独立开发DAL层综合软件
## MySQL主从复制原理
  MySQL的主从复制是一个**异步**复制的过程，在Master和Slave之间的复制是通过三个线程参与完成，其中有两个线程**SQL线程和I/O线程**在Slave端，另外的一个**I/O线程**工作在Master端；
  要实现MySQL的主从复制功能，首先必须打开**Master端的binlog记录功能**，否则无法实现；复制的过程就是Slave从Master端获取Binlog日志，然后在Slave上以相同顺序执行获取的binlog日志所记录的各种SQL操作过程；
  打开MySQL的binlog功能：[mysqld]  log-bin = /data/3306/mysql-bin   <==> eg
```
mysql> show variables like '%log_bin%';
+---------------------------------+-------+
| Variable_name                   | Value |
+---------------------------------+-------+
| log_bin                         | ON    |
| log_bin_trust_function_creators | OFF   |
| sql_log_bin                     | ON    |
+---------------------------------+-------+
3 rows in set (0.00 sec)

```
## MySQL主从复制原理过程详细描述
1. 在Slave服务器上执行start slave命令开启主从复制开关，开始进行主从复制；
* 此时，Slave服务器的I/O线程会通过在Master上已经授权的复制用户权限请求连接Master服务器，并请求从指定的Binlog日志文件的指定位置(日志文件名和位置就是在配置主从复制服务时执行change master命令指定的)之后开始发送binlog日志内容；
* Master服务器接收到来自Slave服务器的I/O线程请求后，其上负责复制的I/O线程会根据Slave服务器的I/O线程请求的信息分批读取指定Binlog日志文件指定位置之后的binlog日志信息，然后返回给slave端的I/O线程，返回的信息中除了Binlog日志内容外，还有在Master服务器端记录的新的binlog日志名称，以及在新的binlog中的下一个指定更新位置； 
* 当Slave服务器的I/O线程获取到Master服务器上I/O线程发送的日志内容、日志文件及位置点后，会将binlog日志内容依次写到Slave端自身的Relay Log(中继日志)文件(MySQL-relay-bin.xxxxxx)的最末端，并将新的binlog文件名和位置记录到master-info文件中，以便下一次读取Master端新binlog日志时能够告诉Master服务器从新Binlog日志的指定文件及位置开始请求新的binlog日志内容；
* Slave服务器端的SQL线程会实时检测本地Relay log中的I/O线程新增加的日志内容，然后及时地把Relay Log文件中的内容解析成SQL语句，并在自身的Slave服务器上按解析SQL语句的位置顺序执行应用这些SQL语句，并在relay-log.info中记录当前应用relay log的文件名及位置点；
* 有特殊情况

## 主从配置过程
1. Master配置
```
1. 开启binlog及设置server-id
[mysqld]
server-id = 1                        # 用于同步的每台主机或实例的server-id都不能相同
log-bin = /data/3306/mysql-bin       # 可不指定地址

[root@node2.azt.com ~]$egrep "server-id|log-bin" /data/3306/my.cnf
log-bin = /data/3306/mysql-bin
server-id = 1

mysql> SHOW VARIABLES LIKE 'SERVER_ID';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| server_id     | 1     |
+---------------+-------+
1 row in set (0.00 sec)

mysql> SHOW VARIABLES LIKE 'log_bin';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| log_bin       | ON    |
+---------------+-------+
1 row in set (0.00 sec)

2. 准备第一次主从复制
```
1. 对数据库锁表只读
mysql> flush table with read lock;
Query OK, 0 rows affected (0.00 sec)

mysql> SHOW MASTER STATUS;
+------------------+----------+--------------+------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB |
+------------------+----------+--------------+------------------+
| mysql-bin.000007 |      433 |              |                  |
+------------------+----------+--------------+------------------+
1 row in set (0.00 sec)

2. 备份
[root@node2.azt.com ~]$mysqldump -uroot -predhat -S /data/3306/mysql.sock  --events -A -B | gzip > /data/mysql_backup/mysql_bak.$(date +%F).sql.gz
    -A：表示备份所有库
    -B：表示增加use DB和drop等，导库时会直接覆盖原有的
[root@node2.azt.com ~]$ls -l /data/mysql_backup/mysql_bak.$(date +%F).sql.gz
-rw-r--r--. 1 root root 152990 Apr 13 01:54 /data/mysql_backup/mysql_bak.2017-04-13.sql.gz

3. 解锁数据库
mysql> unlock tables;
Query OK, 0 rows affected (0.00 sec)

```

3. 创建用于主从复制的帐号
mysql> GRANT replication slave ON *.* TO 'rep'@'10.0.0.%' IDENTIFIED BY 'redhat';
Query OK, 0 rows affected (0.00 sec)

mysql> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT user,host FROM mysql.user WHERE user='rep';
+------+----------+
| user | host     |
+------+----------+
| rep  | 10.0.0.% |
+------+----------+
1 row in set (0.01 sec)

mysql> SHOW GRANTS for rep@'10.0.0.%';
+-----------------------------------------------------------------------------------------------------------------------+
| Grants for rep@10.0.0.%                                                                                               |
+-----------------------------------------------------------------------------------------------------------------------+
| GRANT REPLICATION SLAVE ON *.* TO 'rep'@'10.0.0.%' IDENTIFIED BY PASSWORD '*84BB5DF4823DA319BBF86C99624479A198E6EEE9' |
+-----------------------------------------------------------------------------------------------------------------------+
1 row in set (0.00 sec)
```

* 从库配置
```
1.设置server-id值并关闭binlog功能参数,修改my.cnf
[mysqld]
server-id = 3              # 不能跟Master和其它Slave节点相同

[root@node2.azt.com ~]$egrep 'server-id|log-bin' /data/3307/my.cnf
server-id	= 3
#log-bin=mysql-bin    # 注释不开启

mysql> SHOW VARIABLES LIKE 'SERVER_ID';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| server_id     | 3     |
+---------------+-------+
1 row in set (0.01 sec)

mysql> SHOW VARIABLES LIKE 'log_bin';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| log_bin       | OFF   |
+---------------+-------+
1 row in set (0.00 sec)

2. 导出主的的备份到Slave
[root@node2.azt.com ~]$gzip -d /data/mysql_backup/mysql_bak.2017-04-13.sql.gz 
[root@node2.azt.com ~]$mysql -uroot -p'redhat' -S /data/3307/mysql.sock < /data/mysql_backup/mysql_bak.2017-04-13.sql

3. 登录3307从库，配置复制参数
[root@node2.azt.com ~]$mysql -predhat -S /data/3307/mysql.sock 
mysql> CHANGE MASTER TO
    -> MASTER_HOST='10.0.0.32',                            # 主库IP
    -> MASTER_PORT=3306,                                   # 主库的端口，从库端口可以与主库不同
    -> MASTER_USER='rep',                                  # 主库建立用于复制的用户rep
    -> MASTER_PASSWORD='redhat',                           # 密码
    -> MASTER_LOG_FILE='mysql-bin.000007',                 # show master status的参数
    -> MASTER_LOG_POS='433';
或者使用：
[root@node2.azt.com ~]$mysql -predhat -S /data/3307/mysql.sock << EOF
> MASTER_HOST='10.0.0.32',
> MASTER_PORT=3306,
> MASTER_USER='rep',
> MASTER_PASSWORD='redhat',
> MASTER_LOG_FILE='mysql-bin.000007',
> MASTER_LOG_POS='433';
> EOF

4. 检测
[root@node2.azt.com ~]$cat /data/3307/data/master.info 
18
mysql-bin.000007
433
10.0.0.32
rep
redhat
3306
60
...

5. 开启从库同步开关，查看状态
mysql> START SLAVE;
Query OK, 0 rows affected (0.01 sec)

mysql> SHOW SLAVE STATUS\G;
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 10.0.0.32
                  Master_User: rep
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000007                 # 从库I/O线程当前读取主库binlog文件名
          Read_Master_Log_Pos: 433                              # 从库I/O线程当前读取主库binlog的位置
               Relay_Log_File: 3307mysqld-relay-bin.000002      # SQL线程正在应用的Relay log文件
                Relay_Log_Pos: 253                              # SQL线程正在应用的Relay log位置
        Relay_Master_Log_File: mysql-bin.000007                 # SQL线程正在应用的Relay log对应的binlog
             Slave_IO_Running: Yes                               # I/O线程状态，I/O线程负责从从库读取binlog日志，并写入从库的中继日志
            Slave_SQL_Running: Yes                               # SQL线程负责读取中继日志中的数据并转换为SQL语句应用到数据库中
              Replicate_Do_DB: 
          Replicate_Ignore_DB: 
           Replicate_Do_Table: 
       Replicate_Ignore_Table: 
      Replicate_Wild_Do_Table: 
  Replicate_Wild_Ignore_Table: 
                   Last_Errno: 0
                   Last_Error: 
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 433                              # relay_log中relay_log_pos位置对应于主库Binlog的位置
              Relay_Log_Space: 414
              Until_Condition: None
               Until_Log_File: 
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File: 
           Master_SSL_CA_Path: 
              Master_SSL_Cert: 
            Master_SSL_Cipher: 
               Master_SSL_Key: 
        Seconds_Behind_Master: 0                            # 复制过程中从库比主库延迟的秒数，更准的方法：主库写时间戳，从库读取，再同当前数据库时间比较
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error: 
               Last_SQL_Errno: 0
               Last_SQL_Error: 
  Replicate_Ignore_Server_Ids: 
             Master_Server_Id: 1
1 row in set (0.00 sec)
```
## 主从配置总结：
1. 准备两台数据库环境或单台多实例环境，确定服务正常和能够正常访问登录；
2. 配置主库的server-id及开启log-bin功能，从库配置server-id，要确保server-id不相同，从库一般不用开启log-bin，重启生效
3. 登录主库，配置用于主从复制的用户帐号及权限，一般为REPLICATION SLAVE
4. 主库锁表FLUSH TABLE WITH READ LOCK(窗口关闭后即失效，超时参数设置的时间到了，锁表也失效)，然后show master status查看binlog的位置状态
  ```
    mysql> SHOW VARIABLES LIKE "%timeout%";
    +----------------------------+----------+
    | Variable_name              | Value    |
    +----------------------------+----------+
    | connect_timeout            | 10       |
    | delayed_insert_timeout     | 300      |
    | innodb_lock_wait_timeout   | 50       |
    | innodb_rollback_on_timeout | OFF      |
    | interactive_timeout        | 28800    |       # 
    | lock_wait_timeout          | 31536000 |
    | net_read_timeout           | 30       |
    | net_write_timeout          | 60       |
    | slave_net_timeout          | 3600     |
    | wait_timeout               | 28800    |       # 
    +----------------------------+----------+
    10 rows in set (0.00 sec)
  ```
5. 备份，导出数据库，导出完成后，解锁主库unlock tables
6. 恢复数据到从库，执行相关CHANGE MASTER TO ...语句，制定master-info信息
7. 从库start slave，检查从库复制状态SHOW SLAVE STATUS\G;

## 应用技巧
* MySQl从库停止复制故障
>     1. stop slave; set global sql_slave_skip_count=n; start slave;          # 忽略执行N个更新
>     2. 根据可以忽略的错误号事先在配置文件中配置，挑错错误; slave-skip-errors = xxx,xxxx
>     3. 不同版本的数据库会引起不同步，高版本不能往低版本同步
* 让Mysql从库记录binlog日志的方法：从库作为其它从库的主库，双主
>     在my.cnf中加入：log-slave-updates
* 备份策略
>     1. 可以提供一个不对外提供服务的从库作为备份服务器
      2. 开启从库的binlog功能,log-slave-updates; 备份时可以选择只停止SQL线程，停止应用SQL语句到数据库，I/O线程保留工作状态，执行stop slave sql_thread;
* 能过**read-only**参数让从库只读访问
>     mysqld_safe --default-file=  --read-only &   或者在my.cnf中增加"read-only"



## 三种复制方式
1. statement: 基于SQL语句级别的Binlog 
2. Row: 
3. Mixed: 