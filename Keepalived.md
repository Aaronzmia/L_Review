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
#     

