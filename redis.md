# redis：REmote DIctionary Server
* NOSQL技术、KV存储或数据结构存储，提供数据结构的远程存储功能
* memecached仅是内存中的cache，不提供持久存储能力；但redis提供持久存储能力
* 内存中运行：数据集保存在内存中
* 数据周期性的从内存中写入到磁盘中，实现持久功能
* 单线程
* 支持在服务器端运行Lua脚本，完成复杂操作
* 支持主从架构，借助sentinel实现一定意义上的HA
* 3.0开始支持集群，分布式
* 数据结构服务器：String，List，Hash，Set，Sorted set, logs

## 常见存储系统：
* RDBMS
* NOSQL
    * KV NoSQL：redis
    * Column Family Nosql：HBase(Hadoop组件)

* NewSQL：支持分布式


## Redis安装使用
* centos 7直接yum安装，依赖jemalloc
```
[root@www ~]# rpm -ql redis
/etc/logrotate.d/redis
/etc/redis-sentinel.conf            # 运行为sentinel的配置文件
/etc/redis.conf                     # 主配置文件
/etc/systemd/system/redis-sentinel.service.d
/etc/systemd/system/redis-sentinel.service.d/limit.conf
/etc/systemd/system/redis.service.d
/etc/systemd/system/redis.service.d/limit.conf
/usr/bin/redis-benchmark
/usr/bin/redis-check-aof
/usr/bin/redis-check-rdb
/usr/bin/redis-cli                   # redis的命令行工具，支持远程连接到redis进行基于command的操作
/usr/bin/redis-sentinel              # 实现在主从架构中实现其高性能的工具 
```
### redis.conf
```
[root@www ~]# grep -v '^#' /etc/redis.conf |grep -v '^$'
bind 127.0.0.1                                  # 监听地址，多个地址用空格隔开
protected-mode yes
port 6379                                       # 监听端口tcp/6379
tcp-backlog 511                                 
# 等待队列，任何tcp协议都可能使用，前端并发高，接收缓存满，会额外开辟一块给新进请求；b acklog的长度是未建立的tcp连接和已经建立的tcp连接之和，等待进程从队列中调用建立的连接。

timeout 0                                       # 客户端连接超时，0不启用
tcp-keepalive 300
daemonize no                                    # 是否运行为守护进程，为No的时候，基于脚本启动也会以守护进程的方式运行

supervised no
pidfile /var/run/redis/redis.pid
loglevel notice
logfile /var/log/redis/redis.log
databases 16                                    # 可以使用多少个database，SELECT <dbid>，分布式不支持使用多库
save 900 1                                      # 900s内1个键发生了变化，执行快照，存储到磁盘
save 300 10
save 60 10000                                   # 60S内10000个key发生变化，执行快照，如果需要禁用，使用 `save""`
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /var/lib/redis

```
### redis-cli
### redis数据结构：help  @XXXX
* string：字符，值类似于 key value。
    * SET key value [EX|NX|XX]
    * GET
    * INCR
    * DECR
    * EXISTS
* set：集合，值类似于 key value1 [value2 value3...]。
    * DECR
    * INCR
    * SADD
    * SMEMBERS
    * SISMEMBER
* sorted_set：有序的集合，值类似于 key score1 value1 [score2 value2 score2 value2....]。
    * ZADD
    * ZSCORE
    * ZRANGE
    * ZRANGEBYSCORE
* hash：哈希kv，值类似于 key field1 value1 [field2 values]。
    * HSET
    * HGET
    * HGETALL
    * HKEYS
    * HVALS
    * HLEN
* list：列表，值类似于集合，只不过采用采用了双向链表的方式，存取采用left与right两个方向的push与pop动作的方式。
    * RPUSH
    * LPUSH
    * LPOP
    * RPOP
* Bitmaps, HyperLogLog：实现数据统计

### Redis实现认证功能
```
1) 编辑redis.conf,添加`requirepass [PASS]`
[root@www ~]# vim /etc/redis.conf
    requirepass aztest
[root@www ~]# systemctl restart redis

2) redis-cli中，使用AUTH PASS
[root@www ~]# redis-cli -h 127.0.0.1
127.0.0.1:6379> SELECT 0
(error) NOAUTH Authentication required.
127.0.0.1:6379> AUTH aztest
OK
```

### 清空数据库
* FLUSHDB：清空当前库
* FLUSHALL: 清空所有库

### 事务：一组相关的操作是原子性的，要么都执行，要么都不执行
    通过MULTI，EXEC，WATCH等命令实现事务功能；将一个或多个命令归并为一个操作提请服务器按顺序执行的机制；不支持回滚操作
* MULIT：启动一个事务，中间执行的命令都会被防置在此事务中
* EXEC：执行事务，一次性将事物中的所有操作执行完成后返回给客户端； 
* WATCH：乐观锁；在EXEC命令执行之前，用于监视指定数量键，并且如果监视中的某任意键数据被修改，则服务器拒绝执行事务；先于MULTI执行

### connection相关的命令
* AUTH
* ECHO
* PING
* QUIT
* SELECT

### Server相关的命令
* CLIENT GETNAME：获取当前客户端的连接名
* CLIENT KILL ip:port：指定ip:port可以关闭指定的CLIENT
* CLIENT SETNAME connection-name：设定当前连接的名称

* CONFIG GET
* INFO para：获取当前服务器的状态信息和统计信息
* CONFIG RESETSTAT：重置info中所统计的数据
* CONFIG SET：运行时修改指定参数的值
* CONFIG REWRITE：把内存中修改的新值同步到配置文件中

* DBSIZE -：显示当前选定数据库中键的数量

* BGSAVE：
* SAVE：
* LASTSAVE：获取最新一次save执行的时间戳

* MONITOR：实时监控新的数据操作请求
* SHUTDOWN：将所有数据保存到磁盘后安全关闭server，可指定NOSAVE

### redis的发布与订阅功能（publish/subscribe）
    频道：消息队列
* publish channel message：发送消息给某个队列
* subscribe channels：用于订阅一个或多个队列；  psubcribe
* unsubsrcibe：退订此前订阅的频道

### Redis的持久化
    RDB：snapshot，二进制格式数据文件；默认启用的机制；按照事先定制的策略，周期性的将数据保存至磁盘；数据文件默认为dump.rdb；客户端可以显式使用SAVE或BGSAVE命令启动快照保存机制； Redis调用FORK，创建一个子进程，父进程会继续处理客户端的请求，而子进程负责将内存中的数据快照到磁盘上去，Linux系统有写时复制机制，所以父进程和子进程共享相同的物理页面， 而且当父进程处理写请求时，操作系统会为父进程要修改的文件创建一个副本，这个时候，子进程实现的保存一定是保存时间点一致的数据；当子进程写入到临时文件完成后，会用临时文件替换上一次的文件，然后子进程使用完成退出；不足下一旦数据库出现问题，由于RDB的数据不是最新的，所以基于RDB恢复的数据一定会造成数据丢失
* SAVE：同步，在主线程中保存快照；此时会阻塞所有客户端端请求；快照完整将数据写入到磁盘一次，而不是增量
* BGSAVE：异步，主进程不会被阻塞，自动在后台实现保存操作

* 相关配置：
    * save xxx x
    * stop-write-on-bgsave-error yes
    * rdbcompression yes
    * rdbchecksum yes
    * dbfilename dump.rdb
    * dir /var/lib/redis  

    AOF：Append Only File，把Redis的每一个操作命令都以附加的方式直接附加到指定文件的尾部，Redis能够合并重写AOF的持久化文件，可以使用BGREWRITEAOF命令来实现，收到命令后，Redis将用与快照类似的方式将内存中的数据以命令的方式保存在临时文件中，最后替换原来的文件； 
* 通过记录每一次写操作至指定的文件尾部实现持久化；当Redis重启时，可通过重新执行文件中的命令在内存中重建数据库；
* BGREAOF：AOF文件重写，不会读取正在使用AOF文件，而是通过将内存中的数据以命令的方式保存到临时文件中，完成后替换原来的AOF文件；

* 重写过程：
    1. redis主进程通过fork创建子进程
    2. 子进程根据redis内存中的数据创建数据库重建命令序列于临时文件中；
    3. 父进程继续接收client的请求，并会把这些请求中的写操作继续追加至原来的AOF文件；额外的，这些新的写请求还会被放置于一个缓冲队列中； 
    4. 子进程重写完成，会通知父进程；父进程会把缓冲中的命令写到临时文件中
    5. 父进程用临时文件替换老的AOF文件中

* 相关配置
    * appendonly no                                   # AOF持久化存储，二进制
    * appendfilename "appendonly.aof"
    * appendfsync {always|everysec|no}                # AOF的持久化策略，always表示只要发生数据操作就执行保存或者重写AOF；everysec一秒一次；no关闭
    * no-appendfsync-on-rewrite no  # 在重写时将当前AOF的日志存储在内存中，防止AOF附加操作与重写产生数据写入堵塞问题，提高了性能却增加了数据的风险性。                  
    * auto-aof-rewrite-percentage 100                 # 每当AOF日志是上次重写的一倍时就自动触发重写操作
    * auto-aof-rewrite-min-size 64mb                  # 自动触发重写的最低AOF日志大小为64MB，为了防止在AOF数据量较小的情况话频繁发生重写操作
    * aof-load-truncated yes                          # 当redis发生奔溃，通过AOF恢复时，不执行最后最后那条因为中断而发生问题的语句
* 注意：持久本身不能取代备份；还应该制定备份策略，对redis数据库定期进行备份；
* RDB和AOF同时启用：
    1. BGSAVE和BGREWRITE不会同时执行；
    2. 在Redis服务器启动用于恢复数据时，会优先使用AOF

### Redis的复制
* 特点
    * 一个Master可以有多个Slave
    * 支持链式复制
    * Master支持以非阻塞方式同步数据至slave
* 相关配置
    * #slave of                                               # slave of开启才会生效 
    * slave-serve-stale-data yes                      # 允许使用过期数据
    * slave-read-only yes                             
    * repl-diskless-sync no                           # 是否基于diskless复制
    * repl-diskless-sync-delay 5
    * repl-disable-tcp-nodelay no
    * slave-priority 100
* 注意：如果master使用requirepass开启认证功能，从服务器要使用masterauth <PASSWORD>来连入主服务器请求使用此密码进行验证

### sentinel:
    Redis在其主从架构中实现高可用的方案
    监控多个服务器节点；通知；自动故障转移
    留言协议，投票协议
* 程序：
    * redis-sentinel /path/to/file.conf       # 使用配置文件保存状态信息，必须要有配置文件
    * redis-server /path/to/file.conf --sentinel
* 步骤：
    1. 服务器自身初始化，运行redis-server中专用于sentinel功能的代码；
    2. 初始化sentinel状态，根据给定的配置文件，初始化监控的master服务器列表
    3. 创建连向master的连接
* 专用配置文件：/etc/redis-sentinel.conf
    1. port 26379
    2. dir /tmp
    3. sentinel monitor <master-name> <ip> <port> <quorum>    # 至少有quorum定义的票，才可以成为主节点
    4. sentinel down-after-milliseconds mymaster 30000        # 认为mymaster离线需要的超时市场，默认30S
    5. sentinel parallel-syncs mymaster 1                     # 允许多少个服务器向新的主服务器发起同步请求
    6. sentinel failover-timeout mymaster 180000              # 故障转移的超时时间
    7. logfile /var/log/redis/sentinel.log 
* 主观下线，客观下线
    * 主观下线：一个sentinel实例判断出某节点下线；
    * 客观下线：多个sentinel节点协商后判断出某节点下线；
* 专用命令：
    SENTINEL masters
    SENTINEL slaves <master name>
    SENTINEL get-master-addr-by-name <master name>
    SENTINEL reset
    SENTINEL failover <master name>

### CLustering
    分布式数据库，通过分片机制进行数据分布，clustering内的每个节点仅数据库的一部分数据
    集群中的每个节点都可以作为接入节点
    每个节点持有全局元数据，但仅持有一部分数据
    codis  







