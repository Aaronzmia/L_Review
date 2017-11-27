# Mysql的备份与恢复
## 为什么要备份
1. 灾难回复：硬件/软件故障、人为误操作、自然灾害、黑客攻击导致的数据丢失
2. 提供测试

## 备份要注意的要点
1. 能容忍最多丢失多少数据
2. 恢复数据需要在多长时间内完成
3. 需要恢复哪些数据
4. 备份仅能保证恢复到备份那一刻，要结合二进制日志
5. 还原测试，确保备份可用
6. 还原演练

## 备份类型
1. 完全备份，部分部分
    * 完全备份：备份整个数据集合
    * 部分备份：只备份数据子集
2. 完全备份，增量备份，差异备份
    * 增量备份：最近一次完全备份/增量备份以来变化的数据；
    * 差异备份：仅备份最近一次完全备份以来变化的数据
3. 热备份、温备份、冷备份
    * 热备份：线上系统读写操作不受影响，备份过程中读写操作均可执行；InnoDB
    * 温备份：读操作可执行，写操作不能执行，MyISAM，InnoDB
    * 冷备份：读写操作均不可执行
4. 物理备份，逻辑备份
    * 物理备份：直接复制数据文件进行备份
    * 逻辑备份：从数据库中"导出"数据另存而进行的备份，会丢失精度；与存储引擎无关

## 备份时需要考虑的因素：
1. 持锁多久
2. 备份过程时长
3. 备份负载

## 备份的内容
1. 数据
2. 二进制日志、InnoDB的事务日志
3. 代码（存储过程、存储函数、触发器、事件调度器）
4. 服务器的配置文件

## 设计备份方案：
1. 数据集：完全+增量
2. 备份手段：物理、逻辑

## 备份工具
1. mysqldump：逻辑备份工具，适用于所有存储引擎，支持温备；支持完全备份、部分备份；对InnoDB存储引擎支持热备；
2. cp, tar等复制归档工具：物理备份，适用于所有存储引擎；冷备；完全备份，部分备份；
3. lvm2的快照：几乎热备(请求施加全局读锁，立即快照，释放锁)，借助于文件系统管理工具进行备份
4. mysqlhotcopy：热复制，几乎冷备；仅适用于MyISAM存储引擎

## 备份工具的选择：
1. Mysqldump + 复制binlog：mysqldump负责完全备份；binlog通过start-datetime--stop-datetime中的event来完成增量备份
2. lvm2快照 + 复制binlog：lvm2 + tar/cp等做物理/完全备份；binlog完成增量
3. xtrabackup：Percona提供的支持对InnoDB做热备(物理备份)的工具；


# 备份和恢复
## 逻辑备份工具：mysqldump, mydumper, phpMyAdmin；schema和数据存储在一起、巨大的sql语句来实现，单个巨大的备份文件
### mysqldump
客户端命令，通过mysql协议连接至mysqld服务
```
mysqldump [options] [db_name [tbl_name ...]]
    shell> mysqldump [options] db_name [tbl_name ...]
        不会自动创建`create database`语句，指定db_name，只会备份所有的tb，恢复时，需要自己先创建database，才能导入数据
    shell> mysqldump [options] --databases db_name ...
        即便备份库中的一个表也会创建数据库
    shell> mysqldump [options] --all-databases
        自动创建数据库

    -A/--all-databases：备份所有数据库
    -B db_name .../--database db_name ...：备份指定数据库,想一次备份多个库需要添加B参数，B参数会在备份数据中添加create database和use语句;
    
    
    MyISAM：支持温备；锁定备份库，而后启动备份操作；FLUSH
        锁定方法：
            -x/--locak-all-tables：锁定所有库的所有表
            -l/--locak-tables：对每个单独的数据库，在启动备份之前锁定其所有表
        对InnoDB表实现温备操作一样生效
        eg全备：-u -p -A -B --master-data=2 -x |gzip
    
    InnoDB：支持热备
            --single-transaction：该选项在导出数据之前提交一个BEGIN SQL语句，BEGIN 不会阻塞任何应用程序且能保证导出时数据库的一致性状态。它只适用于多版本存储引擎，仅InnoDB。本选项和--lock-tables 选项是互斥的，因为LOCK  TABLES 会使任何挂起的事务隐含提交。要想导出大表的话，应结合使用--quick 选项；
        eg全备：-u -p -A -B --master-data=2 --single-transaction |gzip >

    其它选项：
        -E/--events：备份指定数据库相关的所有event scheduler;
        -R/--routines：备份指定数据库相关的所有存储过程和存储函数
        --triggers：备份表相关的触发器；默认选项可不加

        --master-data=[#]：
            1：记录为CHANGE MASTER TO 语句，此语句不被注释
            2：记录为注释的CHANGE MASTER TO语句 
        --flush-logs：锁定表完成后，执行flush logs命令
        注：二进制日志文件不应该和数据文件放在同一磁盘；
        -d：只备份表结构
        -t：只备份数据
        --events: 备份事件调度器代码
        --routines: 备份存储过程和存储函数
        --triggers：备份触发器
```
### 示例
* 备份数据库：mysqldump -uroot -hlocalhost -p --databases XXX > /PATH/TO/SOMEWHERE.sql
* 备份多个数据库：mysqldump -uroot -hlocalhost -p --databases xxx1 xxx2 > /PATH/TO/SOMEWEHER.sql
* 单表备份：
* 完全备份：mysqldump -uroot  -hlocalhost --all-databases --lock-all-tables --master-data=2 > /PATH/TO/SOMEWEHER.sql
* 还原备份
    * 建议关闭二进制日志记录，关闭其他用户对服务器的写操作
        MariaDB [(none)]> SET sql_log_bin=OFF; 
    * 完全还原  
        mysql < /PATH/xxx.sql or mysql > source /PATH/xxx.sql
    * 还原至时间点
        mysqlbinlog --start-position=xxx --stop-position=xxx /PATH/binlog.00000x | mysql
    * 打开二进制日志记录
        
## lvm2备份
1. 请求锁定所有表
    ```
    mysql> FLUSH TABLES WITH READ LOCK;     
    ```
2. 记录二进制文件及事件位置
    ```
    mysql> SHOW MASTER STAUS;
    mysql> FLUSH LOGS;
    mysql> SHOW MASTER STAUS;    | # mysql -e 'SHOW MASTER STATUS' > /PATH?
    ```

3. 创建快照卷
    ```
    # lvcreate -L 1G -n mydata-snap -p r -s /dev/mapper/myvg-mydata   
    ```
4. 释放锁
    ```
    mysql> UNLOCK TABLES; 

    ```
5. 挂载快照卷执行数据备份

6. 备份完成后，删除快照卷

7. 制定好策略，通过原卷备份二进制日志；

8. 恢复数据
    ```
    [root@node1 lvm_snap]# rm -rf /lvm_data/*
    [root@node1 ~]# service mysqld start    #启动MySQL, 如果是编译安装的应该不能启动(需重新初始化), 如果rpm安装则会重新初始化数据库
    [root@node1 ~]# cd /lvm_data/
    [root@node1 lvm_data]# rm -rf * #删除所有文件
    [root@node1 lvm_data]# tar xf /tmp/mysqlback.tar     #解压备份数据库到此文件夹 
    [root@node1 lvm_data]# ls  #查看当前的文件
    employees  ibdata1  ib_logfile0  ib_logfile1  mysql  mysql-bin.000001  mysql-bin.000002  mysql-bin.000003  mysql-bin.index  test
    ```

## xtrabackup
    Xtrabackup是由percona提供的mysql数据库备份工具，据官方介绍，这也是世界上惟一一款开源的能够对innodb和xtradb数据库进行热备的工具;  http://www.percona.com/software/percona-xtrabackup/ 
### 完全备份
    innobackupex --user=DBUSER --password=DBUSERPASS  /path/to/BACKUP-DIR  
1. 创建最小权限的用户进行备份
```
mysql> CREATE USER ’bkpuser’@’localhost’ IDENTIFIED BY ’s3cret’;
mysql> REVOKE ALL PRIVILEGES, GRANT OPTION FROM ’bkpuser’;
mysql> GRANT RELOAD, LOCK TABLES, REPLICATION CLIENT ON *.* TO ’bkpuser’@’localhost’;
mysql> FLUSH PRIVILEGES;
```
2. 
```
使用innobakupex备份时，其会调用xtrabackup备份所有的InnoDB表，复制所有关于表结构定义的相关文件(.frm)、以及MyISAM、MERGE、CSV和ARCHIVE表的相关文件，同时还会备份触发器和数据库配置信息相关的文件。这些文件会被保存至一个以时间命名的目录中。

在备份的同时，innobackupex还会在备份目录中创建如下文件：
(1)xtrabackup_checkpoints —— 备份类型（如完全或增量）、备份状态（如是否已经为prepared状态）和LSN(日志序列号)范围信息；

每个InnoDB页(通常为16k大小)都会包含一个日志序列号，即LSN。LSN是整个数据库系统的系统版本号，每个页面相关的LSN能够表明此页面最近是如何发生改变的。

(2)xtrabackup_binlog_info —— mysql服务器当前正在使用的二进制日志文件及至备份这一刻为止二进制日志事件的位置。

(3)xtrabackup_binlog_pos_innodb —— 二进制日志文件及用于InnoDB或XtraDB表的二进制日志文件的当前position。

(4)xtrabackup_binary —— 备份中用到的xtrabackup的可执行文件；

(5)backup-my.cnf —— 备份命令用到的配置选项信息；

在使用innobackupex进行备份时，还可以使用–no-timestamp选项来阻止命令自动创建一个以时间命名的目录；如此一来，innobackupex命令将会创建一个BACKUP-DIR目录来存储备份数据。
```
3. 执行备份操作





