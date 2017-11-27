# zabbix监控Tomcat，JVM
* agent端操作
```
查看tomcat版本
# catalina.sh version      
...
Server version: Apache Tomcat/8.0.38
...

下载对应版本的JMX Remote jar 二进制包，放到$TOMCAT/lib下
# wget http://archive.apache.org/dist/tomcat/tomcat-8/v8.0.38/bin/extras/catalina-jmx-remote.jar
# # mv catalina-jmx-remote.jar /usr/local/tomcat/lib/

修改catalina.sh，添加如下内容
CATALINA_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=192.168.10.111
"
CATALINA_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=192.168.40.10 -Dcom.sun.management.jmxremote.port=12345"

重启tomcat

```
* zabbix_server端操作
```
修改zabbix_server配置文件
    JavaGateway=127.0.0.1
    JavaGatewayPort=10052
    StartJavaPollers=5
启动zabbix_java
    
```

下面介绍几种常用的JAVA容器的JMX开启方式：
1）Apache Tomcat
如果是windows版本，编辑TOMCAT_HOME/bin/catalina.bat，在开头加入下面几行：
set CATALINA_OPTS=%CATALINA_OPTS% -Djava.rmi.server.hostname=JMX_HOST
set CATALINA_OPTS=%CATALINA_OPTS% -Djavax.management.builder.initial=
set CATALINA_OPTS=%CATALINA_OPTS% -Dcom.sun.management.jmxremote=true
set CATALINA_OPTS=%CATALINA_OPTS% -Dcom.sun.management.jmxremote.port=JMX_PORT set CATALINA_OPTS=%CATALINA_OPTS% -Dcom.sun.management.jmxremote.ssl=false
set CATALINA_OPTS=%CATALINA_OPTS% -Dcom.sun.management.jmxremote.authenticate=false

如果是Linux版本，编辑TOMCAT_HOME/bin/catalina.sh，在开头加入下面几行：
CATALINA_OPTS=${CATALINA_OPTS} -Djava.rmi.server.hostname=JMX_HOST CATALINA_OPTS=${CATALINA_OPTS} -Djavax.management.builder.initial= CATALINA_OPTS=${CATALINA_OPTS} -Dcom.sun.management.jmxremote=true CATALINA_OPTS=${CATALINA_OPTS} -Dcom.sun.management.jmxremote.port=JMX_PORT CATALINA_OPTS=${CATALINA_OPTS} -Dcom.sun.management.jmxremote.ssl=false CATALINA_OPTS=%{CATALINA_OPTS} -Dcom.sun.management.jmxremote.authenticate=false
注意JMX_HOST为tomcat的主机名或IP地址，JMX_PORT为JMX端口，通常使用12345，然后重启tomcat，JMX就开启了。


2）IBM WebSphere AS
进入WebSphere Administrative Console open Servers → Server Types → WebSphere application servers → WAS_SERVER_NAME → Java and Process Management → Process definition → Java Virtual Machine.
在“Generic JVM arguments”增加下面环境变量：
-Djavax.management.builder.initial=
然后再进入 WebSphere Administrative Console, open Servers → Server Types → WebSphere application servers → WAS_SERVER_NAME → Java and Process Management → Process definition → Java Virtual Machine → Custom properties.
增加下面几个环境变量：
Name: java.rmi.server.hostname
Value: JMX_HOST
Name: javax.management.builder.initial
Value: none
Name: com.sun.management.jmxremote
Value: true
Name: com.sun.management.jmxremote.port
Value: JMX_PORT
Name: com.sun.management.jmxremote.ssl
Value: false
Name: com.sun.management.jmxremote.authenticate
Value: false
应用更改，重启应用就开启了。
3）Oracle GlassFish AS
进入GlassFish Console, open GAS_CONFIG → JVM Settings → JVM Options.
加入下面的环境变量到“JVM options”:
Value: -Djava.rmi.server.hostname=JMX_HOST
Value: -Dcom.sun.management.jmxremote=true
Value: -Dcom.sun.management.jmxremote.port=JMX_PORT
Value: -Dcom.sun.management.jmxremote.ssl=false
Value: -Dcom.sun.management.jmxremote.authenticate=false
重启就开启了。
4）Oracle WebLogic 11g (10.23.x) and 12c (12.1.x)
对于windows的版本，编辑WL_DOMAIN_HOME/bin/setDomainEnv.cmd，在文件结尾加入下面几行：
set JAVA_OPTIONS=%JAVA_OPTIONS% -Djava.rmi.server.hostname=JMX_HOST
set JAVA_OPTIONS=%JAVA_OPTIONS% -Djavax.management.builder.initial=weblogic.management.jmx.mbeanserver.WLSMBeanServerBuilder set JAVA_OPTIONS=%JAVA_OPTIONS% -Dcom.sun.management.jmxremote=true
set JAVA_OPTIONS=%JAVA_OPTIONS% -Dcom.sun.management.jmxremote.port=JMX_PORT
set JAVA_OPTIONS=%JAVA_OPTIONS% -Dcom.sun.management.jmxremote.ssl=false
set JAVA_OPTIONS=%JAVA_OPTIONS% -Dcom.sun.management.jmxremote.authenticate=false
对于Linux的版本，编辑WL_DOMAIN_HOME/bin/setDomainEnv.cmd，在文件结尾加入下面几行：
JAVA_OPTIONS=”${JAVA_OPTIONS} -Djava.rmi.server.hostname=JMX_HOST” JAVA_OPTIONS=”${JAVA_OPTIONS} -Djavax.management.builder.initial=weblogic.management.jmx.mbeanserver.WLSMBeanServerBuilder” JAVA_OPTIONS=”${JAVA_OPTIONS} -Dcom.sun.management.jmxremote=true” JAVA_OPTIONS=”${JAVA_OPTIONS} -Dcom.sun.management.jmxremote.port=JMX_PORT” JAVA_OPTIONS=”${JAVA_OPTIONS} -Dcom.sun.management.jmxremote.ssl=false” JAVA_OPTIONS=”${JAVA_OPTIONS} -Dcom.sun.management.jmxremote.authenticate=false” export JAVA_OPTIONS
然后重启weblogic，就开启了。
需要注意的是，如果你的应用不是布署在默认的应用服务器上，而是新增了一个应用服务器布署的话，应该使用下面这个方法:
进入weblogic控制台->环境->服务器->”你新增的服务器”->配置->服务器启动。在“参数”的输入框内输入：
-Dcom.sun.management.jmxremote.port=JMX_PORT -Djava.rmi.server.hostname=JMX_HOST -Dcom.sun.management.jmxremote.authenticate=false  -Dcom.sun.management.jmxremote.ssl=false -Djavax.management.builder.initial=weblogic.management.jmx.mbeanserver.WLSMBeanServerBuilder



zabbix安装：
1. rpm包方式
```
$ yum install zabbix-server-mysql zabbix-web-mysql

shell> mysql -uroot -p<root_password>
mysql> create database zabbix character set utf8 collate utf8_bin;
mysql> grant all privileges on zabbix.* to zabbix@localhost identified by '<password>';
mysql> quit;

$ zcat /usr/share/doc/zabbix-server-mysql-3.2.*/create.sql.gz | mysql -uzabbix -p zabbix

$ vi /etc/zabbix/zabbix_server.conf
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=<password>

$ systemctl start zabbix-server
$ systemctl enable zabbix-server

php_value max_execution_time 300
php_value memory_limit 128M
php_value post_max_size 16M
php_value upload_max_filesize 2M
php_value max_input_time 300
php_value always_populate_raw_post_data -1
$ php_value date.timezone Europe/Riga     # 时区

$ setsebool -P httpd_can_connect_zabbix on

```

zabbix客户端yum安装：
```
# rpm -ivh  http://repo.zabbix.com/zabbix/3.2/rhel/6/x86_64/zabbix-release-3.2-1.el6.noarch.rpm
```

2. adding user
* Admin：zabbix的超级用户，拥有所有权限
* Guest：zabbix的特殊默认用户，默认没有任何权限，如果没有登录，会以Guest身份登录
* zabbix中，权限是分配给user groups，而不是单个用户
Administration -> Users -> Create user


zabbix_get的使用：
zabbix_get [-hv] -s <host name or IP> [-p <port>] [-I <IP ADDRESS>] -k <key>
    -h：远程zabbix-agetn的IP地址或者主机名
    -s：远程zabbix-agent的端口
    -I：本机出去的IP地址，用于多网卡环境
    -k：获取远程zabbix-agent数据所使用的key
    注：zabbix_get仅能测试获取Agent监控方式的KEY，不能获取Simple Check、JMX、SNMP等其它监控方式的KEY类型的数据

Zabbix完整的监控流程配置：
    Host groups -> Host -> Applications -> Itmes -> Triggers -> Event -> Actions -> User groups -> User -> Medias -> Audit

Zatree：提供Host Group的树形展示和在Item中指定关键字查询及数据排序，提供到2.4.X(https://github.com/spide4k/zatree)

zabbix的web监控：
    即对HTTP服务的监控，模拟用户去访问网站，对特定的结果进行比较，状态码、返回字符串等特定的数据进行比较和监控，从而判断网站web服务的可用性
    Configuration -> Hosts -> Web -> Create scenario
    steps参数解释：
        Name：URL名称
        URL：必须是全路径带页面名
        Post：传递给页面的参数，多个参数之间用&连接，此处可引用前面定义的变量
        Variables：设置变量
        Required string: 页面中能匹配到的字符，若不匹配，则认为出错
        Required status code：匹配的状态码，不匹配则出错
    
zabbix的ITEM：
    Type of information：
        Numeirc(unsgned)：64位无符号整数
        Numeric(float)：浮点数
        Character：字符/字符串类型数据限制为255B
        Log：日志文件，必须使用的Key为log[]
        Text：文本，不限制大小
    Data Type：数据类型用于存储Items中Key所获取的数值值，用于存储在不同的表中，如history,history_str等表
        Boolean：在数据存储的时候将原本的值替换为0或1，TRUE存储为1，FALSE存储为0，所有的值都区分大小写
            TRUE：true/t/yes/y/on/up/running/enabled/available/非0
            FALSE：false/f/no/n/off/down/unused/disabled/unavailable/0
        Octal：八进制的数值格式
        Decimal：十进制的数值格式
        Hexadecimal：十六进制的数值格式
        Zabbix自动执行数据类型的格式转换
    Units: 如果设置了单位符号，Zabbix会处理接收到的数据，并且把数值转换为需要显示的单位；B，Bps（bytes每秒）会除以1024，显示1B/1Bps
        Unixtime：接收到的值转换为"yyyy.mmmm.dd hh:mm:ss"，必须是一个数值类型
        Uptime：接收到的值转换为"hh:mm:ss"或"N days, hh:mm:ss"
        S：转换为"yyy mmm dddhhh mmm sssms"，转换为三个主要的单位
    Use custom multiplier：如果开启，所接受到的数值将会被乘以证书或者浮点数；网络流量通常会乘以8
    Update interval：间隔时间通过Item手机数据，0不会采集数据
    Store value：
        As is：无预先处理
        Delta(speed per second)：数值计算的方法为(value-prev_value)/(time-prev_time) => 当前值-上一次的值/当前时间-上一次时间
        Delta(simple change)：数值计算的方法value-prev_value
    Show value：值的显示，通常使用as is，显示自己的值
    
zabbix的ITEM的key：
1. 用户自定义参数格式：仅支持Agent方式，写入/etc/zabbix/zabbix_agentd.conf
    UserParameter=key,command
    UserParameter=key[*],command $1 $2 $3...
2. 自定义Key中的对特殊字符的处理：\ ' " ` * ? [] {} ....
    UnsafeUserParameters=1
    如果定义的字符中出现$后面接数字，需要用$$
3. Key返回的值
    自定义参数可以返回文本(character/log/text)和空值，如果返回的是一个无效值，则显示ZBX_NOTSUPPORTED
4. 子配置文件
    Include=/etc/zabbix/zabbix_agentd.conf.d/
    定义后，此目录下的所有配置文件都会被当作子配置文件，如果重复会导致客户端Agent启动失败

Item常见Key：
1. 监控网卡流量的key
    net.if.out[if,<mode>]
    net.if.in[if,<mode>]
    net.if.discovery
    # net.if.collisions[if]
    net.if.total[if,<mode>]
2. 监控端口的key
    net.tcp.listen[port]
    net.tcp.port[<ip>,port]
    net.tcp.service[service,<ip>,<port>]
    net.tcp.service.perf[service,<ip>,<port>]
3. 监控进程的key
    kernel.maxfiles
    kernel.maxproc
    proc.mem[<name>,<user>,<mode>,<cmdline>]
    proc.num[<name>,<user>,<mode>,<cmdline>]
4. 监控CPU和内存的Key
    system.cpu.intr
    system.cpu.load[<cpu>,<mode>]
    system.cpu.num[<type>]
    system.cpu.switches
    system.cpu.util[<cpu>,<type>,<mode>]
    vm.memory.size[<mode>]
    system.swap.in[<device>,<type>]
    system.swap.out[<device>,<type>]
    system.swap.size[<device>,<type>]
5. 磁盘I/O的key
    vfs.dev.read[<device>,<type>,<mode>]
    vfs.dev.write[<device>,<type>,<mode>]
    vfs.fs.inode[fs,<mode>]
6. 文件监控的Key
    vfs.file.cksum[file]
    vfs.file.contents[file,<encoding>]
    vfs.file.exists[file]
    vfs.file.md5sum[file]
    vfs.file.regexp[file,regexp,<encoding>,<start line>,<end line>,<output>]
    vfs.file.regmatch[file,regexp,<encoding>,<start line>,<end line>]
    vfs.file.size[file]
    vfs.file.time[file,<mode>]
    vfs.fs.discovery
    vfs.fs.size[fs,<mode>]
7. 日志监控的Key
    log[file,<regexp>,<encoding>,<maxlinse>,<mode>,<output>]
    logrt[file_pattern,<regexp>,<encoding>,<maxlines>,<mode>,<output>]
8. Windows专用的Key
    eventlog[name,<regexp>,<severity>,<source>,<eventid>,<maxlines>,<mode>]
    net.if.list
    perf_counter[counter,<interval>]
    proc_info[<process>,<attribute>,<type>]
    service_state[*]
    services[<type>,<state>,<exclude>]
    wmi.getp[<namespace>,<query>]




























zabbix表分区：
    * 关闭Housekeeper功能
    * 




























zabbix数据库的备份：
```
#!/bin/bash
#
source /etc/bashrc && source /etc/profile

MySQL_USER=zabbix
MySQL_PASSWORD=XXXXXXXX
MySQL_HOST=localhost
MySQL_PORT=3306
MySQL_DUMP_PATH=/mysql_backup
MySQL_DATABASE_NAME=zabbix
DATE=`date +&Y%m%d`

[ -d ${MySQL_DUMP_PATH} ] || mkdir ${MySQL_DUMP_PATH}
cd ${MySQL_DUMP_PATH}
[ -d logs ] || mkdir logs
[ -d ${DATE} ] || mkdir ${DATE}
cd ${DATE}

TABLE_NAME_ALL=$(mysql -u${MySQL_USER} -p${MySQL_PASSWORD} -P${MySQL_PORT} -h${MySQL_HOST} ${MySQL_DATABASE_NAME} -e "SHOW TABLES"|egrep -v "(Tables_in_zabbix|history*|trends*|acknowledges)|alerts|auditlog|events|service_alarms")
```

