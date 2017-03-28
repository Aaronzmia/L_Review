# 简介
    keepalived软件主要是通过VRRP协议(Virtual Router Redundancy Portocol)来实现高可用服务的方案，常见的LVS+Keepalived、Nginx+Keepalived、HAproxy+Keepalived等前端高可用；
    Keepalived主要有三个模块，分别是core、check和vrrp:
        core模块为keepalived的核心，负责主进程的启动、维护以及全局配置文件的加载和解析
        check负责健康检查，包括常见的各种检查方式
        vrrp模块是来实现VRRP协议的
# 工作原理
    两台服务器同时运行keepalived，由标识为master的主机获得所有资源并对用户提供服务，标识为BACKUP的主机作为MASTER的热备；
    MASTER会发送特定的心跳消息（多播）给BACKUP，当BACKUP主机收不到MASTER主机的心跳消息，即主机出现故障或宕机的时候，BACKUP主机接管MASTER的所有资源对外提供服务；当MASTER主机重新上线后，重新接管资源提供服务，重新恢复到主备状态；
    VRRP：
        VRRP的目的就是为了解决静态路由单点故障问题；
        VRRP通过一竞选(election)协议来动态的将路由任务交给LAN中虚拟路由器中的某台VRRP路由器；所有报文都是通过IP多播的方式(Multicast)包(默认多播地址224.0.0.18)形式发送；
        虚拟路由器由VRID(范围0-255)和一组IP地址组成，对外表现为一个周知的MAC地址。所以，在一个虚拟路由器中，不管谁是MASTER，对外都是相同的MAC和IP(称之为VIP)。客户端主机并不需要因为MASTER的改变而修改自己的路由配置，对客户端来说，这种主从的切换是透明的；
        在一个虚拟路由器中，只有作为MASTER的VRRP路由器会一直发送VRRP通告信息(VRRPAdvertisement message)，BACKUP不会抢占MASTER，除非它的优先级(priority)更高。当MASTER不可用时(BACKUP收不到通告信息)， 多台BACKUP中优先级最高的这台会被抢占为MASTER。这种抢占是非常快速的(<1s)，以保证服务的连续性。由于安全性考虑，VRRP包使用了加密协议进行加密，但不推荐使用加密；
# 脑裂
    正常情况下，（集群中的）NodeA 和 NodeB 会通过心跳检测以确认对方存在，在通过心跳检测确认不到对方存在时，就接管对应的（共享） resource 。如果突然间，NodeA 和 NodeB 之间的心跳不存在了（如网络断开），而 NodeA 和 NodeB 事实上却都处于 Active 状态，此时 NodeA 要接管 NodeB 的 resource ，同时 NodeB 要接管 NodeA 的 resource ，这时就是脑裂（split-brain）。
    脑裂（split-brain）会 引起数据的不完整性 ，并且可能会 对服务造成严重影响 。
    引起数据的不完整性主要是指，集群中节点（在脑裂期间）同时访问同一共享资源，而此时并没有锁机制来控制针对该数据访问（都脑裂了，咋控制哩），那么就存在数据的不完整性的可能。
## 常用解决方法
* 添加冗余的心跳线
* 设置仲裁机制
* 做好脑裂的监控
#  配置文件解析
```
[root@node3.azt.com ~]$vim /etc/keepalived/keepalived.conf 

! Configuration File for keepalived        # 注释
 
global_defs {                     # 全局配置
   notification_email {           # 定义服务故障报警的Email地址
     acassen@firewall.loc
     failover@firewall.loc
     sysadmin@firewall.loc
   }
   notification_email_from Alexandre.Cassen@firewall.loc      # 指定发送邮件的发送人
   smtp_server 192.168.200.1         # 发送邮件的SMTP服务器
   smtp_connect_timeout 30           # SMTP 超时时间
   router_id LVS_DEVEL               # 路由标识，在局域网内，这个标识应该是惟一的

   vrrp_mcast_group4 224.0.0.19      # 指定多播地址，默认为224.0.0.18
}

vrrp_instance VI_1 {                
# 定义一个叫VI_1的vrrp_instance实例，可以有多个，存在于MASTER的实例在备用节点中也要存在，才能进行故障切换
    state MASTER                    # 当前实例的角色，MASTER|BACKUP
    interface eth0                  # 对外提供服务的端口
    virtual_router_id 51            # 虚拟路由ID标识，在一个Keepalived配置文件中及主备节点中都要保持唯一，否则会脑裂
    priority 100                    # 优先级，MASTER应高于BACKUP
    advert_int 1                    # MASTER与BACKUP之间检查通信的时间间隔，单位为秒，默认为1S
    authentication {                # 权限认证配置
        auth_type PASS              # 认证类型，有PASS、AH两种
        auth_pass 1111              # 验证密码，明文，MASTER和BACKUP使用相同的密码才能正常通信
    }
    virtual_ipaddress {             # 虚拟IP地址，VIP
        192.168.200.16 dev eth0 label eth0:1
        192.168.200.17
        192.168.200.18
    }
}

virtual_server 192.168.200.100 443 { # 设定虚拟服务器，指定IP及PORT
    delay_loop 6                     # 健康检查时间间隔
    lb_algo rr                       # 调度算法，rr|wrr|lc|wlc|sh|dg|lblc
    lb_kind NAT                      # 转发规则，NAT|DR|TUN
    nat_mask 255.255.255.0           
    persistence_timeout 50           # 会话保持时间，50S内无操作，接下来的请求会分发到其它节点
    protocol TCP              

    real_server 192.168.201.100 443 {  # 配置服务节点，指定真实IP PORT
        weight 1                       # 设置权重
        SSL_GET {
            url {
              path /
              digest ff20ad2481f97b1754ef3e12ecd3a9cc
            }
            url {
              path /mrtg/
              digest 9b3a0c85a887a256d6939da88aabd8cd
            }
            connect_timeout 3      # 连接超时时间
            nb_get_retry 3         # 重新连接次数
            delay_before_retry 3   # 重连间隔时间
        }
    }
}
     
```   
# 配置keepalived日志
```
[root@node2.azt.com keepalived]$sed -i '14 s#KEEPALIVED_OPTIONS="-D"#KEEPALIVED_OPTIONS="-D -d -S 0"#g' /etc/sysconfig/keepalived 
[root@node2.azt.com keepalived]$sed -n "14p" /etc/sysconfig/keepalived
KEEPALIVED_OPTIONS="-D -d -S 0"
    -D：详细日志，--log-detail
    -d：导出备份配置数据 --dump-conf
    -S：指定本地的syslog设备，编号0-7(default=LOG_DAEMON)，--log-facility

[root@node2.azt.com keepalived]$vim /etc/rsyslog.conf 
*.info;mail.none;authpriv.none;cron.none;local0.none               /var/log/messages
# keepalived
local0.*    /var/log/keepalived.log
```
# 检测脑裂脚本
    在备节点上执行脚本，如果可以ping通主节点并且备节点有VIP就报警
```bash
#! /bin/bash
#
lb01_vip = 10.0.0.44
lb01_ip = 10.0.0.31

while true; do
    ping -c 2 -W 3 $lb01_ip &> /dev/null
    if [ $? -eq 0 -a `ip addr |grep "$lb01_vip"|wc -l` -eq 1 ]; then
        echo "ha is split brain.warning"
    else
        echo "ha is ok"
    fi
    sleep 5
done
```

# 配置实例
1. 单实例单IP自动漂移
```
lb-01配置：
$ vim /etc/keepalived.conf 
    global_defs {
    notification_email {
            xxx@qq.com
    }
    notification_email_from Alexandre.Cassen@firewall.loc
    smtp_server 127.0.0.1
    smtp_connect_timeout 30
    router_id lb_01          
    }
    
    vrrp_instance VI_1 {
        state MASTER
        interface eth0
        virtual_router_id 51
        priority 100
        advert_int 1
        authentication {
            auth_type PASS
            auth_pass 1111
        }
        virtual_ipaddress {
            10.0.0.44/24 dev eth0 label eth0:1
        }
[root@node2.azt.com keepalived]$ip addr show eth0
3: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 00:0c:29:96:00:38 brd ff:ff:ff:ff:ff:ff
    inet 10.0.0.32/24 brd 10.0.0.255 scope global eth0
    inet 10.0.0.44/24 scope global secondary eth0:1        # eth0:1 已开启监听
    inet6 fe80::20c:29ff:fe96:38/64 scope link 
       valid_lft forever preferred_lft forever

lb-02配置
global_defs {
   notification_email {
     acassen@firewall.loc
     failover@firewall.loc
     sysadmin@firewall.loc
   }
   notification_email_from Alexandre.Cassen@firewall.loc
   smtp_server 127.0.0.1
   smtp_connect_timeout 30
   router_id lb_02
}
 
vrrp_instance VI_1 {
    state BACKUP
    interface eth0
    virtual_router_id 51
    priority 90
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        10.0.0.44/24 dev eth0 label eth0:1
    }
}
[root@node3.azt.com keepalived]$ip addr show eth0
3: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 00:0c:29:02:04:57 brd ff:ff:ff:ff:ff:ff
    inet 10.0.0.33/24 brd 10.0.0.255 scope global eth0       # 作为backup, 不接管44的地址
    inet6 fe80::20c:29ff:fe02:457/64 scope link 
       valid_lft forever preferred_lft forever

测试：停止主节点
[root@node2.azt.com keepalived]$/etc/init.d/keepalived stop
Stopping keepalived:                                       [  OK  ]
[root@node2.azt.com keepalived]$ip addr show |grep eth0:1

[root@node3.azt.com ~]$ip addr show | grep eth0:1 
    inet 10.0.0.44/24 scope global secondary eth0:1       # 备节点已经接管

[root@node2.azt.com keepalived]$/etc/init.d/keepalived start          # 主节点重新上线，重新接管VIP
Starting keepalived:                                       [  OK  ]
[root@node2.azt.com keepalived]$ip addr show |grep eth0:1
[root@node2.azt.com keepalived]$ip addr show |grep eth0:1
    inet 10.0.0.44/24 scope global secondary eth0:1
```
2) 双主模式的配置，两个节点互为主备
```
lb-01配置：
$ vim /etc/keepalived.conf 
    global_defs {
    notification_email {
            xxx@qq.com
    }
    notification_email_from Alexandre.Cassen@firewall.loc
    smtp_server 127.0.0.1
    smtp_connect_timeout 30
    router_id lb_01          
    }
    
    vrrp_instance VI_1 {
        state MASTER
        interface eth0
        virtual_router_id 51
        priority 100
        advert_int 1
        authentication {
            auth_type PASS
            auth_pass 1111
        }
        virtual_ipaddress {
            10.0.0.44/24 dev eth0 label eth0:1
        }
    
    vrrp_instance VI_2 {                # 不能与实例1名相同
    state BACKUP                        # 在实例2作为备节点
    interface eth0
    virtual_router_id 55                # 与主节点一致，于本地不同
    priority 90                         # 优先级要低于主节点
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
          10.0.0.45/24 dev eth0 label eth0:2
    }
}
[root@node2.azt.com keepalived]$ip addr show |grep "eth0:[12]"
    inet 10.0.0.44/24 scope global secondary eth0:1

lb-02配置：
$ vim keepalived.com
global_defs {
   notification_email {
         xxx@qq.com
   }
   notification_email_from Alexandre.Cassen@firewall.loc
   smtp_server 127.0.0.1
   smtp_connect_timeout 30
   router_id lb_01
}
 
vrrp_instance VI_1 {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
          10.0.0.44/24 dev eth0 label eth0:1
    }
}
 
vrrp_instance VI_2 {
    state BACKUP
    interface eth0
    virtual_router_id 55
    priority 90
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
          10.0.0.45/24 dev eth0 label eth0:2
    }
}

[root@node2.azt.com keepalived]$ip addr show |grep "eth0:[12]"
    inet 10.0.0.44/24 scope global secondary eth0:1

问题：
nginx: [emerg] bind() to 10.0.0.44:80 failed (99: Cannot assign requested address)  # 在keepalived启动后启动Nginx出现
解决：
[root@node3.azt.com conf]$echo 'net.ipv4.ip_nonlocal_bind = 1' >> /etc/sysctl.conf 
# 忽略配置中监听的VIP是否存在
```
3）配置keepalived监控Nginx脚本
```
1）编写相关脚本
[root@node2.azt.com keepalived]$vim chk_nginx_proxy.sh
    #!/bin/bash
    #
    if [ `netstat -lntup | grep nginx | wc -l` -ne 1 ]; then
      /etc/init.d/keepalived stop
    fi
[root@node2.azt.com keepalived]$chmod +x chk_nginx_proxy.sh 
2）添加到配置文件
global_defs {
   notification_email {
         xxx@qq.com
   }
   notification_email_from Alexandre.Cassen@firewall.loc
   smtp_server 127.0.0.1
   smtp_connect_timeout 30
   router_id lb_01
}
 
vrrp_script chk_nginx_proxy {                 # 定义脚本
    script "/etc/keepalived/chk_nginx_proxy.sh"
    interval 2
    weight 2
}
 
vrrp_instance VI_1 {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
          10.0.0.44/24 dev eth0 label eth0:1
    }
    track_script {
        chk_nginx_proxy                 # 触发检查
    }
}
3）在Lb02上执行同样操作
4）检测
[root@node2.azt.com keepalived]$ip addr show |grep eth0:1
    inet 10.0.0.44/24 scope global secondary eth0:1
[root@node3.azt.com keepalived]$ip addr show | grep eth0:1

[root@node2.azt.com keepalived]$/usr/local/nginx/sbin/nginx -s stop
[root@node2.azt.com keepalived]$ip addr show |grep eth0:1
[root@node3.azt.com keepalived]$ip addr show | grep eth0:1
    inet 10.0.0.44/24 scope global secondary eth0:1

```




