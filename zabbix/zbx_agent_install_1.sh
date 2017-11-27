#!/bin/bash
# zabbix install for new meachine

ZbxHostname=`ip addr |grep 'inet\b' |grep -v 127 | awk -F "[ /]" '{print $6}'`

if [[ `rpm -qa zabbix-agent` -eq 0 ]]; then
    if [[ `cat /etc/redhat-release |awk -F "[ .]" '{print $3}'` -eq 6 ]]; then
        rpm -ivh http://repo.zabbix.com/zabbix/3.2/rhel/6/x86_64/zabbix-release-3.2-1.el6.noarch.rpm &> /dev/null
    elif [[ `cat /etc/redhat-release |awk -F "[ .]" '{print $4}'` -eq 7 ]]; then
        rpm -ivh http://repo.zabbix.com/zabbix/3.2/rhel/7/x86_64/zabbix-release-3.2-1.el7.noarch.rpm &> /dev/null
    else
        echo "NO such repo" 
    fi
    yum install -y zabbix-agent zabbix-sender &> /dev/null
    if [ $? == 0 ]; then
        rpm -e zabbix-release
    fi
fi


sed -i "s/^Server=.*/Server=192.168.10.111/" /etc/zabbix/zabbix_agentd.conf
sed -i "s/^Hostname=.*/Hostname=${ZbxHostname}/" /etc/zabbix/zabbix_agentd.conf

if [[ `cat /etc/redhat-release |awk -F "[ .]" '{print $4}'` -eq 6 ]]; then
    /etc/init.d/zabbix-agent start
elif [[ `cat /etc/redhat-release |awk -F "[ .]" '{print $4}'` -eq 7 ]]; then
    systemctl start zabbix-agent.service
else
    return 11       
fi 

