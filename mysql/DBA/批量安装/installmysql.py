#!/usr/bin/python
# -*- coding: utf-8 -*-
import os
import sys
import pwd
import getopt
import socket
import fcntl
import struct
import string

pre_base = "mysql"
dbport = "3306"
mhost = None
pj_dir=None
"""
#oscheck
/opt/mysql
/opt/mysql/mysql-5.5.37-linux2.6-x86_64
link /usr/local/mysql

#init
/data/mysql/xxxx_port
/data/mysql/xxxx_port/data
/data/mysql/xxxx_port/tmp
/data/mysql/xxxx_port/logs

环境变量/usr/local/mysql/bin 是否存在

根据输入参数项目名，端口号，主库ip(MasterNone)
/data/mysql/xxxx_port/my_port.cnf

启动mysql
/usr/local/mysql/bin/mysqld --defaults=/data/mysql/xxxx_port/my_port.cnf &

加入同步结构中
"""

def oscheck():
    try:
        pwd.getpwnam("mysql")
    except: 
        os.system("groupadd mysql")
        os.system("useradd -g mysql -d /opt/mysql -s /sbin/nologin mysql") 
        print "create mysql user ok"

    user = pwd.getpwnam("mysql")

    if ( (os.path.isdir("/opt/mysql") == False) ):
        os.mkdir("/opt/mysql")
        os.chown("/opt/mysql", user[3],user[2])
        print "create dir /opt/mysql"

    if ( (os.path.isdir("/opt/mysql/mysql-5.5.37-linux2.6-x86_64")) == False):
            os.chdir("/tmp")
	    if ( os.path.exists("daosen-mysql-5.5.37-linux2.6-x86_64.tar.gz") == False):
            	os.system("wget http://192.168.199.75/mysql/daosen-mysql-5.5.37-linux2.6-x86_64.tar.gz -o /tmp/down.log")
	    print "Download Ok /tmp/daosen-mysql-5.5.37-linux2.6-x86_64.tar.gz"
	    print "tar  zxf daosen-mysql-5.5.37-linux2.6-x86_64.tar.gz -C /opt/mysql"
            os.system("tar zxf daosen-mysql-5.5.37-linux2.6-x86_64.tar.gz -C /opt/mysql")
            os.chown("/opt/mysql", user[3],user[2])
            print "create /opt/mysql/mysql-5.5.37-linux2.6-x86_64 ok!"

    if ( (os.path.islink("/usr/local/mysql")) == False):
        os.symlink("/opt/mysql/mysql-5.5.37-linux2.6-x86_64", "/usr/local/mysql")
        os.lchown("/usr/local/mysql", user[3],user[2])
        print "create link ok"

    if ( (os.path.isdir("/data/mysql")) == False):
        os.mkdir("/data/mysql")
        os.chown("/data/mysql", user[3],user[2]) 
    cmd = "grep 'mysql' /etc/profile|grep -v grep|wc -l"
    mpNum = os.popen(cmd).read()
    if ( int(mpNum) <= 0):
	print "export PATH=$PATH:/usr/local/mysql/bin >> /etc/profile"
        line = "export PATH=$PATH:/usr/local/mysql/bin"
        os.system("echo %s >>/etc/profile; source /etc/profile" % line)

    
    print "oscheck ok"

def install_mysql():
    global pre_base
    global dbport
    pj_dir = "%s_%s" % (pre_base, dbport)
    user = pwd.getpwnam("mysql")
    print "create dir %s" % pj_dir
    if ( (os.path.isdir("/data/mysql/%s" % pj_dir)) == False):
        os.mkdir("/data/mysql/%s" % pj_dir)
        os.mkdir("/data/mysql/%s/data" % pj_dir)
        os.mkdir("/data/mysql/%s/logs" % pj_dir)
        os.mkdir("/data/mysql/%s/tmp" % pj_dir)
        os.chown("/data/mysql/%s" % pj_dir, user[3], user[2])
    else:
        print "%s, %s is exists!!!" %(pj_dir, dbport)
        return 1

    os.chown("/data/mysql/%s/" % pj_dir, user[3], user[2])
    conf = "/data/mysql/%s/my_%s.cnf" %(pj_dir,dbport)
    print  " create conf file %s" % conf
    cnf = gen_conf()
    fd_conf = open(conf, 'w')
    fd_conf.write(cnf)
    fd_conf.close()
    os.system("cp -r /usr/local/mysql/data/* /data/mysql/%s/data" % pj_dir )
    os.system("chown -R mysql:mysql /data/mysql/%s" % pj_dir)
    # start mysqld_safe
    cmd = "/usr/local/mysql/bin/mysqld_safe --defaults-file=/data/mysql/%s/my_%s.cnf >/dev/null &" % (pj_dir, dbport)
    os.system("echo \"%s\" >/data/mysql/%s/start.sh" % (cmd, pj_dir))
    print "start msyql: %s " % cmd
    os.system(cmd)
    cmd = "/usr/local/mysql/bin/mysqladmin -S /data/mysql/%s/mysql_%s.sock shutdown"%(pj_dir, dbport)
    os.system("echo %s > /data/mysql/%s/stop.sh" % (cmd, pj_dir))
    cmd="/usr/local/mysql/bin/mysql -S /data/mysql/%s/mysql_%s.sock" %( pj_dir, dbport)
    os.system("echo %s >/data/mysql/%s/login.sh" %(cmd, pj_dir))
    cmd="chmod +x /data/mysql/%s/*.sh" % pj_dir
    os.system(cmd)


def gen_conf():
    global pre_base
    global dbport
    pj_dir = "%s_%s" % (pre_base, dbport)
    sid = get_sid("eth0")

    conf_tpl = '''[mysql]
port={0}
prompt=\\u@\\d \\r:\\m:\\s>
character_set_server = utf8   
[mysqld]
port={0}
user = mysql
character_set_server = utf8   
basedir=/usr/local/mysql
datadir=/data/mysql/{1}/data
tmpdir=/data/mysql/{1}/tmp
socket=/data/mysql/{1}/mysql_{0}.sock
slave_load_tmpdir=/data/mysql/{1}/tmp
log-error=error.log
slow_query_log_file=slow.log
server-id={2}
relay_log_info_file=relay-log.info
master-info-file=master.info
log-bin=/data/mysql/{1}/logs/mysql-bin
relay-log=relay-log

#innodb
innodb_data_file_path=ibdata1:1024M:autoextend 
innodb_log_files_in_group=4
innodb_log_file_size=300M
innodb_buffer_pool_size=100M
innodb_open_files=65535
innodb_flush_log_at_trx_commit=2
innodb_max_dirty_pages_pct=50
innodb_io_capacity=1000
innodb_read_io_threads=16
innodb_write_io_threads=16
innodb_file_per_table=1
innodb_change_buffering=inserts
innodb_adaptive_flushing=1
innodb_stats_on_metadata=0
innodb_additional_mem_pool_size=20M
innodb_flush_method=O_DIRECT
innodb_log_buffer_size=8M
transaction-isolation=READ-COMMITTED

query_cache_type=0
#log_slow_verbosity=full
thread_stack=192K
table_definition_cache=2048
table_cache=2048
thread_cache_size=256
sync_binlog=0
max_binlog_size =500M
binlog_cache_size=1M
binlog-format=ROW
expire_logs_days=7
log-slave-updates
long_query_time=1
slow_query_log=1
skip-slave-start

#timeout
connect_timeout=30
delayed_insert_timeout =300
innodb_lock_wait_timeout=50
innodb_rollback_on_timeout=OFF
net_read_timeout=30
net_write_timeout=60
slave_net_timeout=30
skip-name-resolve
max_connect_errors=2048000
connect_timeout=30
max_allowed_packet=16M
max_connections=1000
max_user_connections=500

#myisam
concurrent_insert=2
key_buffer_size=8M
myisam_sort_buffer_size=20M
#session
sort_buffer_size=128K
join_buffer_size=128K
read_buffer_size=128K

#common
lower_case_table_names=1
skip-external-locking
open_files_limit=65535
read_rnd_buffer_size=4M
safe-user-create
local-infile=0

[mysqld_safe]
open_files_limit               = 8192                                
user                           = mysql
[client]
port= {0}
socket=/data/mysql/{1}/mysql_{0}.sock
'''
    return conf_tpl.format(dbport,pj_dir, sid)


def get_sid(ifname):
    global dbport
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    iplist =socket.inet_ntoa(fcntl.ioctl(
        s.fileno(),
        0x8915,
        struct.pack('256s',ifname[:15])
        )[20:24]).split('.')
    sid="%s%s"%(iplist[3],dbport)
    return sid
    

def mysql_islive():
    global dbport
    cmd="ps -ef | egrep -i \"mysqld\" | grep %s | egrep -iv \"mysqld_safe\" | grep -v grep | wc -l" % dbport
    mysqldNum = os.popen(cmd).read()
    if (int(mysqldNum) > 0):
        print "MySQL starting!!!"
    else:
        print "There may be some error ,please manual run　script" 
        return 1
    return 0

def make_slave():
    global mhost
    global dbport
    global pre_base

    if ( mhost == 'None'):
        print "Thist Master Node!"
        return 0

    mconn = "mysqladmin -h%s -P%s -uwubx -pwubxwubx 'ping'" %(mhost, dbport)
    sconn = "/usr/local/mysql/bin/mysql -S /data/mysql/%s_%s/mysql_%s.sock" %( pre_base, dbport, dbport)
 
    cmd = "change master to master_host='%s', master_port=%s, master_log_file='mysql-bin.000001', master_log_pos=107, master_user='repl', master_password='repl4slave';start slave;" %(mhost, dbport)
    os.system("echo \"%s\"|%s" %(cmd, sconn))
    return 0

if __name__ == "__main__":
    oscheck()
    shortargs='b:P:h:'
    opts, args=getopt.getopt(sys.argv[1:],shortargs)
    for opt, value in opts:
        if opt=='-b':
             pre_base=value
        elif opt=='-P':
            dbport=value
        elif opt=='-h':
            mhost=value
    print mhost 
    
    install_mysql()
    print "Wait for mysql start ..."
    os.system("sleep 10")
    t = 0
    while ( mysql_islive() == 1 and  t < 4):
        os.system("sleep 5")
	t=t+1

    make_slave()
    print "install ok"
