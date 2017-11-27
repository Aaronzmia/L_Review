#!/bin/bash
#添加epel外部yum扩展源
cd /usr/local/src
#wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
#rpm -ivh epel-release-6-8.noarch.rpm
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo
#安装gcc基础库文件及sysstat工具
yum -y install gcc gcc-c++ vim-enhanced unzip unrar sysstat
#配置ntpdate自动对时
yum -y install ntp
echo "01 01 * * * /usr/sbin/ntpdate ntp.api.bz    >> /dev/null 2>&1" >> /etc/crontab
ntpdate ntp.api.bz
service crond restart
#配置文件的ulimit值
ulimit -SHn 65534
echo "ulimit -SHn 65534" >> /etc/rc.local
cat >> /etc/security/limits.conf << EOF
*                     soft     nofile             65534
*                     hard     nofile             65534
EOF
#基础系统内核优化
cat >> /etc/sysctl.conf << EOF
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 36000
net.ipv4.route.gc_timeout = 100
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.core.somaxconn = 16384
net.core.netdev_max_backlog = 16384
net.ipv4.tcp_max_orphans = 16384
EOF
/sbin/sysctl -p
#禁用control-alt-delete组合键以防止误操作
sed -i 's@ca::ctrlaltdel:/sbin/shutdown -t3 -r now@#ca::ctrlaltdel:/sbin/shutdown -t3 -r now@' /etc/inittab
#关闭SElinux
sed -i 's@SELINUX=enforcing@SELINUX=disabled@' /etc/selinux/config
#关闭iptables
service iptables stop
chkconfig iptables off
#ssh服务配置优化,请保持机器中至少有一个具有sudo权限的用户, 下面的配置会禁止root远程登录
#sed -i 's@#PermitRootLogin yes@PermitRootLogin no@' /etc/ssh/sshd_config #禁止           root远程登录
sed -i 's@#PermitEmptyPasswords no@PermitEmptyPasswords no@' /etc/ssh/sshd_config           #禁止空密码登录
sed -i 's@#UseDNS yes@UseDNS no@' /etc/ssh/sshd_config /etc/ssh/sshd_config
service sshd restart
#禁用ipv6地址
echo "alias net-pf-10 off" >> /etc/modprobe.d/dist.conf
echo "alias ipv6 off" >> /etc/modprobe.d/dist.conf
chkconfig ip6tables off
#vim基础语法优化
echo "syntax on" >> /root/.vimrc
echo "set nohlsearch" >> /root/.vimrc#!/bin/bash
#精简开机自启动服务, 安装最小化服务的机器初始可以只保留crond、network、rsyslog、sshd这4个服务。
#for i in `chkconfig --list|grep 3:on|awk '{print $1}'`;do chkconfig --level 3 $i off;done
#for CURSRV  in crond rsyslog sshd network;do chkconfig --level 3 $CURSRV on;done
#重启服务器
reboot



# tomcat常用
CATALINA_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=192.168.10.51 -Dcom.sun.management.jmxremote.port=12345"

JAVA_OPTS="-server -Xms10240m -Xmx10240m -XX:PermSize=256M -XX:MaxPermSize=512M -Xmn320m"

         connectionTimeout="20000"
         URIEncoding="UTF-8"    
         minSpareThreads="25"   
         maxSpareThreads="75" 
         enableLookups="false"   
         disableUploadTimeout="true"   
         acceptCount="300"     
         maxThreads="500"   
         useURIValidationHack="false" 
         compression="on"   
         compressionMinSize="2048" 
         compressableMimeType="text/html,text/xml,text/javascript,text/css,text/plain" 


# nginx反代tomcat
        <Valve className="org.apache.catalina.valves.RemoteIpValve"
                  remoteIpHeader="x-forwarded-for"
                  remoteIpProxiesHeader="x-forwarded-by"
                  protocolHeader="x-forwarded-proto"
        />
        <!-- Access log processes all example.
             Documentation at: /docs/config/valve.html
             Note: The pattern used is equivalent to using pattern="common" -->
        <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
               prefix="localhost_access_log." suffix=".txt"
               pattern="%{X-Real-IP}i[%h] %l %u %t &quot;%r&quot; %s %b " resolveHosts="false"/>

#