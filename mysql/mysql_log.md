## MySQL日志：
* 查询日志：mysql对接受到的每一个查询操作记录下的信息；不建议开启，可以存储两个位置
    * 文件中
    * MySQL数据库的表中
* 慢查询日志：查询日志的特殊子类型，查询时间超出特定限制时长的查询操作所记录的日志信息；
* 错误日志：记录了当mysqld启动和停止时，以及服务器在运行过程中发生任何严重错误时的相关信息;启动配置文件默认开启，或者编译时指定默认的编译选项
* 二进制日志：记录了所有的DDL和DML语句，但不包括数据查询语句。语句以“事件”的形式，描述了数据的更改过程，对灾难时的数据回复起着极重要的作用。
* 中继日志：从服务器，内容同二进制日志；常用于主从复制
* 事务日志：ACID，将随机I/O转换为顺序I/O；
* SHOW GLOBAL|SESSION VARIABLES LIKE '%log%';


### 查询日志：生产环境不应该开启查询日志；
* log_output = {TABLE|FILE|NONE}   
    * eg: log_output = TABLE,FILE同时保存在表和文件中 FILE：general_log	
```
mysql> SHOW GLOBAL VARIABLES LIKE 'log_output';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| log_output    | FILE  |
+---------------+-------+
1 row in set (0.01 sec)
```	
* general_log = {ON|OFF}
    - 是否启用查询日志
* general_log_file = file_name
    - 当log_output有FILE类型时，日志信息的记录位置；当没有指定绝对路径，意味着数据file_name会记录在数据目录下；即datadir指定的目录；
```
mysql> SHOW GLOBAL VARIABLES LIKE 'general_log%';
+------------------+----------------------------------------+
| Variable_name    | Value                                  |
+------------------+----------------------------------------+
| general_log      | OFF                                    |
| general_log_file | /application/mysql-5.5.32/data/www.log |
+------------------+----------------------------------------+
2 rows in set (0.00 sec)
```

### 慢查询日志
    定位mysql哪些语句查询速度慢，阻塞还是表连接、排序问题导致问题慢，服务器性能低，需要手动开启；
    记录所有执行时间超过参数'long_query_time'(单位为s)设置并且扫描记录数不小于min_examined_row_limit的所有SQL语句的日志；
```
MariaDB [(none)]> SELECT @@GLOBAL.long_query_time;
+--------------------------+
| @@GLOBAL.long_query_time |
+--------------------------+
|                10.000000 |
+--------------------------+
1 row in set (0.00 sec)
```
* slow_query_log = {ON|OFF}: 是否启用慢查询日志
* slow_query_log = /path/to/somefile：日志文件路径

* log_slow_filter = admin,filesort,filesort_on_disk,full_join,full_scan,query_cache,query_cache_miss,tmp_table,tmp_table_on_disk
    - 慢查询语句过滤器；定义慢速查询中指定哪些认为是自身原因导致其查询速度较慢的语句；(管理相关、文件排序、完全连接、全表扫描、查询缓存。。。)
* log_slow_rate_limit =
    - 设定速率，避免由于记录慢查询日志而给磁盘带来额外压力，会导致查询I/O更慢 
* log_slow_verbosity =
    - 在记录慢查询日志时，是否以详细格式记录；


### 错误日志：
1. Mysqld启动和关闭过程中输出的信息；
2. Mysqld运行中产生的错误信息；
3. event scheduler(事件调度器)运行一个event时产生的日志信息；
4. 在主从复制架构中的从服务器上启动从服务器线程时产生的日志信息；

* log_error = /path/to/somefile      #错误日志名：host_name.err
* log_warnings = {ON|OFF}：是否记录警告信息于错误日志中；会增加IO压力；


### 二进制日志
    潜在的或的确要引起数据库中的数据发生改变的语句，甚至是语句产生的数据；二进制日志是有格式的，因此，对于二进制日志文件来说，里面的每一次记录都叫一个event；
* SHOW ｛BINARY|MASTER｝LOGS
    - 查看主服务器端处于由mysqld维护状态中的二进制日志文件；
* SHOW BINLOG EVENTS [IN 'log_name'] [FROM pos] [LIMIT [OFFSET,] row_count]
    - 显示指定的二进制日志文件中的相关事件；
	* mysql> SHOW BINLOG EVENTS IN 'mysql-bin.000002'\G
		上一个日志的结束位置就是下一个日志的开始位置；	


1. 日志记录格式：
    * 基于“语句”记录: statement
    * 基于“行”记录: row, 日志数据更精确；
	* “混合”,mixed
	* 注：mysql-bin.index：文件记录了当前mysql记录了多少个二进制日志；日志文件的索引文件

2. 二进制日志文件的构成：
	日志文件：文件名前缀.文件名后缀
	索引文件：文件名前缀.index

3. 相关配置：
	* log_bin = /path/to/somefile | ON | OFF
	* binlog_format = MIXED		   
        - MIXED | STATEMENT | ROW
	* sql_log_bin = ON               
        - 真正意义上是否记录二进制日志；159
        
	* max_binlog_cache_size          
        - 二进制日志缓存大小；二进制会先存放到缓存中，再同步到日志文件；
	* max_binlog_size               
        - 二进制日志文件单个文件的上限制，达到上限，自动滚动；单位为字节，记录的值未必是精确值，一般来说，服务器级别最大设置为1G，最小为4K；
	* max_binlog_stmt_cache_size =   
        - 语句缓存大小，定义了上面的cache_size
	* sync_binlog = 0;               
        - 设定多久同步一次二进制日志文件；0表示不同步；任何正值都表示记录多少个语句后同步一次；
	* SET SESSION | GLOBAL sql_log_bin=0|1;
        - 关闭/开启记录二进制日志：

4. 二进制日志的格式：
```
# at 19364
#140829 15:50:07 server id 1  end_log_pos 19486 	Query	thread_id=13	exec_time=0	error_code=0
SET TIMESTAMP=1409298607/*!*/;
GRANT SELECT ON tdb.* TO tuser@localhost
/*!*/;
# at 19486

# at 365
#160601  5:40:51 server id 1  end_log_pos 403 	GTID 0-1-36
/*!100001 SET @@session.gtid_domain_id=0*//*!*/;
/*!100001 SET @@session.server_id=1*//*!*/;
/*!100001 SET @@session.gtid_seq_no=36*//*!*/;
# at 403


事件发生的日期和时间；(140829 15:50:07)
事件发生在服务器的标识（server id）
事件的结束位置：（end_log_pos 19486）
事件的类型：(Query)
事件发生时所在的服务器执行此事件的线程的ID：（thread_id=13）
语句的时间戳与将其写入二进制文件中的时间差：（exec_time=0）
错误代码：（error_code=0)
事件内容：（SET TIMESTAMP=1409298607/*!*/;
            GRANT SELECT ON tdb.* TO tuser@localhost）

GTID事件专属：mysql5.6 或 mariadb 10.X series
    事件所属的全局事务的GTID：（GTID 0-1-2）
```

5. 二进制日志的查看命令：
```
mysqlbinlog
    -u
    -h
    -p
    -j, --start-position=#: 从指定的事件位置查看
    --stop-position=#：只显示到指定的事件位置

    --start-datetime=name
    --stop-datetime=name
        YYYY-MM-DD hh:mm:ss

eg：
    mysqlbinlog --start-date="20016-04-20 9:55:00" --stop-date="20016-04-20 10:05:00" /var/log/mysql/bin.123456
    mysqlbinlog --stop-position="368312" /var/log/mysql/bin.123456 | mysql -u root -pmypwd
    mysqlbinlog --start-position="368315" /var/log/mysql/bin.123456 | mysql -u root -pmypwd
```

中继日志：从服务器从主服务器上复制而来的二进制日志文件，先保存在本地的日志文件中；主从复制架构中用到的日志；

事务日志：通常是指innodb存储引擎的日志，以Innodb开头

补充材料：日志相关的服务器参数详解：


		expire_logs_days={0..99}
		设定二进制日志的过期天数，超出此天数的二进制日志文件将被自动删除。默认为0，表示不启用过期自动删除功能。如果启用此功能，自动删除工作通常发生在MySQL启动时或FLUSH日志时。作用范围为全局，可用于配置文件，属动态变量。

		general_log={ON|OFF}
		设定是否启用查询日志，默认值为取决于在启动mysqld时是否使用了--general_log选项。如若启用此项，其输出位置则由--log_output选项进行定义，如果log_output的值设定为NONE，即使用启用查询日志，其也不会记录任何日志信息。作用范围为全局，可用于配置文件，属动态变量。
		 
		general_log_file=FILE_NAME
		查询日志的日志文件名称，默认为“hostname.log"。作用范围为全局，可用于配置文件，属动态变量。


		binlog-format={ROW|STATEMENT|MIXED}
		指定二进制日志的类型，默认为STATEMENT。如果设定了二进制日志的格式，却没有启用二进制日志，则MySQL启动时会产生警告日志信息并记录于错误日志中。作用范围为全局或会话，可用于配置文件，且属于动态变量。

		log={YES|NO}
		是否启用记录所有语句的日志信息于一般查询日志(general query log)中，默认通常为OFF。MySQL 5.6已经弃用此选项。
		 
		log-bin={YES|NO}
		是否启用二进制日志，如果为mysqld设定了--log-bin选项，则其值为ON，否则则为OFF。其仅用于显示是否启用了二进制日志，并不反应log-bin的设定值。作用范围为全局级别，属非动态变量。
		 
		log_bin_trust_function_creators={TRUE|FALSE}
		此参数仅在启用二进制日志时有效，用于控制创建存储函数时如果会导致不安全的事件记录二进制日志条件下是否禁止创建存储函数。默认值为0，表示除非用户除了CREATE ROUTING或ALTER ROUTINE权限外还有SUPER权限，否则将禁止创建或修改存储函数，同时，还要求在创建函数时必需为之使用DETERMINISTIC属性，再不然就是附带READS SQL DATA或NO SQL属性。设置其值为1时则不启用这些限制。作用范围为全局级别，可用于配置文件，属动态变量。
		 
		log_error=/PATH/TO/ERROR_LOG_FILENAME
		定义错误日志文件。作用范围为全局或会话级别，可用于配置文件，属非动态变量。
		 
		log_output={TABLE|FILE|NONE}
		定义一般查询日志和慢查询日志的保存方式，可以是TABLE、FILE、NONE，也可以是TABLE及FILE的组合(用逗号隔开)，默认为TABLE。如果组合中出现了NONE，那么其它设定都将失效，同时，无论是否启用日志功能，也不会记录任何相关的日志信息。作用范围为全局级别，可用于配置文件，属动态变量。
		 
		log_query_not_using_indexes={ON|OFF}
		设定是否将没有使用索引的查询操作记录到慢查询日志。作用范围为全局级别，可用于配置文件，属动态变量。
		 
		log_slave_updates
		用于设定复制场景中的从服务器是否将从主服务器收到的更新操作记录进本机的二进制日志中。本参数设定的生效需要在从服务器上启用二进制日志功能。
		 
		log_slow_queries={YES|NO}
		是否记录慢查询日志。慢查询是指查询的执行时间超出long_query_time参数所设定时长的事件。MySQL 5.6将此参数修改为了slow_query_log。作用范围为全局级别，可用于配置文件，属动态变量。
		 
		log_warnings=#
		设定是否将警告信息记录进错误日志。默认设定为1，表示启用；可以将其设置为0以禁用；而其值为大于1的数值时表示将新发起连接时产生的“失败的连接”和“拒绝访问”类的错误信息也记录进错误日志。

		long_query_time=#
		设定区别慢查询与一般查询的语句执行时间长度。这里的语句执行时长为实际的执行时间，而非在CPU上的执行时长，因此，负载较重的服务器上更容易产生慢查询。其最小值为0，默认值为10，单位是秒钟。它也支持毫秒级的解析度。作用范围为全局或会话级别，可用于配置文件，属动态变量。

		max_binlog_cache_size{4096 .. 18446744073709547520}
		二进定日志缓存空间大小，5.5.9及以后的版本仅应用于事务缓存，其上限由max_binlog_stmt_cache_size决定。作用范围为全局级别，可用于配置文件，属动态变量。

		max_binlog_size={4096 .. 1073741824}
		设定二进制日志文件上限，单位为字节，最小值为4K，最大值为1G，默认为1G。某事务所产生的日志信息只能写入一个二进制日志文件，因此，实际上的二进制日志文件可能大于这个指定的上限。作用范围为全局级别，可用于配置文件，属动态变量。




		max_relay_log_size={4096..1073741824}
		设定从服务器上中继日志的体积上限，到达此限度时其会自动进行中继日志滚动。此参数值为0时，mysqld将使用max_binlog_size参数同时为二进制日志和中继日志设定日志文件体积上限。作用范围为全局级别，可用于配置文件，属动态变量。

		innodb_log_buffer_size={262144 .. 4294967295}
		设定InnoDB用于辅助完成日志文件写操作的日志缓冲区大小，单位是字节，默认为8MB。较大的事务可以借助于更大的日志缓冲区来避免在事务完成之前将日志缓冲区的数据写入日志文件，以减少I/O操作进而提升系统性能。因此，在有着较大事务的应用场景中，建议为此变量设定一个更大的值。作用范围为全局级别，可用于选项文件，属非动态变量。
		 
		innodb_log_file_size={108576 .. 4294967295}
		设定日志组中每个日志文件的大小，单位是字节，默认值是5MB。较为明智的取值范围是从1MB到缓存池体积的1/n，其中n表示日志组中日志文件的个数。日志文件越大，在缓存池中需要执行的检查点刷写操作就越少，这意味着所需的I/O操作也就越少，然而这也会导致较慢的故障恢复速度。作用范围为全局级别，可用于选项文件，属非动态变量。
		 
		innodb_log_files_in_group={2 .. 100}
		设定日志组中日志文件的个数。InnoDB以循环的方式使用这些日志文件。默认值为2。作用范围为全局级别，可用于选项文件，属非动态变量。
		 
		innodb_log_group_home_dir=/PATH/TO/DIR
		设定InnoDB重做日志文件的存储目录。在缺省使用InnoDB日志相关的所有变量时，其默认会在数据目录中创建两个大小为5MB的名为ib_logfile0和ib_logfile1的日志文件。作用范围为全局级别，可用于选项文件，属非动态变量。


		relay_log=file_name
		设定中继日志的文件名称，默认为host_name-relay-bin。也可以使用绝对路径，以指定非数据目录来存储中继日志。作用范围为全局级别，可用于选项文件，属非动态变量。

		relay_log_index=file_name
		设定中继日志的索引文件名，默认为为数据目录中的host_name-relay-bin.index。作用范围为全局级别，可用于选项文件，属非动态变量。

		relay-log-info-file=file_name
		设定中继服务用于记录中继信息的文件，默认为数据目录中的relay-log.info。作用范围为全局级别，可用于选项文件，属非动态变量。


		relay_log_purge={ON|OFF}
		设定对不再需要的中继日志是否自动进行清理。默认值为ON。作用范围为全局级别，可用于选项文件，属动态变量。

		relay_log_space_limit=#
		设定用于存储所有中继日志文件的可用空间大小。默认为0，表示不限定。最大值取决于系统平台位数。作用范围为全局级别，可用于选项文件，属非动态变量。


		slow_query_log={ON|OFF}
		设定是否启用慢查询日志。0或OFF表示禁用，1或ON表示启用。日志信息的输出位置取决于log_output变量的定义，如果其值为NONE，则即便slow_query_log为ON，也不会记录任何慢查询信息。作用范围为全局级别，可用于选项文件，属动态变量。

		slow_query_log_file=/PATH/TO/SOMEFILE
		设定慢查询日志文件的名称。默认为hostname-slow.log，但可以通过--slow_query_log_file选项修改。作用范围为全局级别，可用于选项文件，属动态变量。


		sql_log_bin={ON|OFF}
		用于控制二进制日志信息是否记录进日志文件。默认为ON，表示启用记录功能。用户可以在会话级别修改此变量的值，但其必须具有SUPER权限。作用范围为全局和会话级别，属动态变量。

		sql_log_off={ON|OFF}
		用于控制是否禁止将一般查询日志类信息记录进查询日志文件。默认为OFF，表示不禁止记录功能。用户可以在会话级别修改此变量的值，但其必须具有SUPER权限。作用范围为全局和会话级别，属动态变量。

		sync_binlog=#
		设定多久同步一次二进制日志至磁盘文件中，0表示不同步，任何正数值都表示对二进制每多少次写操作之后同步一次。当autocommit的值为1时，每条语句的执行都会引起二进制日志同步，否则，每个事务的提交会引起二进制日志同步。