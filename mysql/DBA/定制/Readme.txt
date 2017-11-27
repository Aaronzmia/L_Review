巡检平台布署
client端:
如是mysql需要监控创建用户 :  ('patrol_user', 'patrol_user');
大致如下:
 GRANT SELECT, PROCESS, SUPER, REPLICATION CLIENT ON *.* TO 'patrol_user'@'192.168.XXXX' IDENTIFIED BY PASSWORD '*A5903248944BB583CED1E91EFB75A0C56EB5BC32' 

安装nrpe
在配置nrpe.conf中添加:
包括
#add by wubx 
command[get_load]=/usr/local/nagios/libexec/get_load
command[get_cpu]=/usr/local/nagios/libexec/get_cpu
command[get_mem]=/usr/local/nagios/libexec/get_mem
command[get_traffic]=/usr/local/nagios/libexec/get_traffic eth0
command[get_diskinfo]=/usr/local/nagios/libexec/get_diskinfo sda
command[get_diskstatus]=/usr/local/nagios/libexec/get_diskstatus
#add by  hzy
command[get_log_wr]=/usr/local/nagios/libexec/get_log_wr -i $ARG1$ -d $ARG2$ -p $ARG3$

抓包支持:


server端:
环境最少需要nrpe, 一般情况下把nagis也安装上去
安装mysql创建patrol_db 初始化脚本取192.168.110.18上的patrol_db的schema
mkdir /usr/local/nagios/patrol/
然后把svn 中的patrol目录copy上去.

加入定时任务:
*/5 * * * * /usr/local/nagios/patrol/bin/cron_5_min.sh
00 00 * * * /usr/local/nagios/patrol/bin/get_day_info.pl
