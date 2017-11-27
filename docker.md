# 从容器到容器云
## 云计算平台
    经典云计算架构：
        IaaS层：Infrastructure as a Service，基础设施即服务；为基础设施运维人员服务，提供计算、存储、网络及其它基础资源，云平台的使用者可以在上面部署和运行包括操作系统和应用程序在内的任意软件，无需再为基础设施的管理分心
        Paas层：Platform as a Service，平台即服务；为应用开发人员服务，提供支撑应用运行所需的软件运行环境、相关工具与服务，如数据库服务、日志服务、监控服务等，让应用开发者可以专注于核心业务的开发
        SaaS层：Software as a Service，软件即服务；为一般用户服务，提供了一套完整可用的软件系统，让一般用户无需关注技术细节，只要通过浏览器、应用客户端的方式就能部署在云上的服务；

## 容器：Docker
    Docker是以Docker容器为资源分割和调度的基本单位，封装整个软件运行时环境，为开发和系统管理员设计，用于构建、发布和运行分布式应用的平台
    Docker是一个跨平台、可移植且简单易用的容器解决方案，基于GO开发并遵循Apache 2.0协议；Docker可以在容器内快速自动化的部署应用，并通过操作系统内核技术（namespaces, cgroups等）为容器提供资源隔离和安全保障
## 容器云
    以容器为资源分割和调度的基本单位，封装整个软件运行时环境，为开发者和系统管理员提供用于构建、发布和运行分布式应用的平台。当容器云专注于资源共享与隔离，容器编排与部署时，它更接近于传统的Iaas；当容器去渗透到应用支撑与运行时环境时，更接近于传统的Paas；


# Docker基本概念
* 镜像(Image)
* 容器(Container)
* 仓库(Repository)
## 镜像
    Docker镜像是一个特殊的文件系统，除了提供容器运行时所需要的程序、库、资源、配置等文件外，还包含了一些为运行时准备的一些配置参数(如匿名卷、环境、变量、用户等)，镜像不包含任何动态数据，其内容在构建之后也不会被改变； 
    Docker采用Union FS技术，设计成为分层存储的架构；所以严格来说，Docker镜像不是一个像ISO那样的打包文件，只是一个虚拟的概念，其实际体现并非由一个文件组成，而是由一组文件系统组成，或者说，由多层文件系统联合组成； 
    镜像构建时，会一层层的构建，前一层是后一层的基础；每一层构建完就不会再发生改变，后一层上的任何改变只发生在自己这一层；比如，删除前一层文件的操作，实际不是真的删除前一层的文件，而是仅在当前层标记为该文件已删除，在最终容器运行的时候，虽然不会看到此文件，但是实际上该文件会一直跟随镜像；因此，在构建镜像的时候，需要额外小心，每层尽量只包含该层需要添加的东西，任何额外的东西应该在该层构建结束前清理掉；
    分层存储的特征使得镜像的复用、定制变的更为容易；甚至可以用之前构建好的镜像作为基础曾，然后进一步添加新的曾，以定制自己所需的内容，构建新的镜像；
## 容器
    容器的实质是进程，是运行时的镜像实体；容器进程运行于属于自己的独立的命名空间，因此容器可以拥有自己的root文件系统、网络配置、进程空间、用户ID空间；容器内的进程是与你运行在一个隔离的环境里，使用起来，就好像是在一个独立于宿主的系统下操作一样，比直接在宿主机运行更安全；
    每一个容器运行时，是以镜像为基础层，在其上创建一个当前容器的存储层，我们可以称之为容器运行时读写而准备的存储层为容器存储层；
    容器存储层的生存周期和容器一样，容器消亡时，容器存储层也随之消亡，因此，任何保存于容器存储曾的信息都会随容器的删除而丢失；
    容器不应当向其存储层内写入任何数据，容器存储层要保持无状态化；所有的文件写入操作，都应该使用数据卷(Volume)、或者绑定宿主目录，在这些位置的读写会跳过容器存储层，直接对宿主(或网络存储)发生读写，其性能和稳定性更高；数据卷的生存周期独立于容器，容器消亡，数据卷不会，因此使用数据卷后，容器可以随意删除、重新run，数据不会丢失；
## 仓库
    一个Docker Registry中可以包含多个仓库Repository，每个仓库可以包含多个标签Tag，每个标签对应一个镜像；
    <仓库名>:<标签>的方式具体是这个软件的哪个版本的镜像，如果不给出标签，默认为latest；


# 命令分类
* 环境信息：info, version
* 容器生命周期管理：create, exec, kill, pause, restart, rm, run, start, stop, unpause
* 镜像仓库命令：login, logout, pull, push, search
* 镜像管理：build, images, import, load, rmi, save, tag, commit
* 容器运维操作：attach, export, inspect, port, ps, rename, stats, top, wait, cp, diff
* 容器日志信息：events, history, logs

# Docker的安装使用
## 基本要求：
* 64位CPU
* 建议内核在3.10及以上
* Linux内核需开启cgroups和namespace功能
* 非Linux内核的平台，如Windows和OS X，需要安装Boot2Docker工具
## Centos安装
>       [root@docker tools]# curl -SsL https://get.docker.com/ | sh
>       或者直接yum install
## 镜像操作：
### 获取镜像：
```
docker pull [OPTIONS] [Docker Registry Addr]<仓库名>:<标签>
    Addr：地址的统一格式一般是<域名/IP>[:PORT]，默认地址是Docker HUb
    仓库名：<用户名>/<软件名>，如果不给出用户名，默认libray，即官方镜像
    docker pull ubuntu：14.04 命令相当于 docker pull registry.hub.docker.com/ubuntu：14.04 命令，即从默认的注册服务器 Docker Hub Registry 中的ubuntu仓库来下载标记为14.04的镜像

```
### 查看已pull的镜像
```
[root@docker tools]# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
centos              latest              a8493f5f50ff        11 days ago         192MB
```
### 添加镜像标签tag
```
[root@docker ~]# docker tag centos:latest mycts:latest

[root@docker ~]# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
centos              latest              a8493f5f50ff        6 months ago        192MB
mycts               latest              a8493f5f50ff        6 months ago        192MB
```
### 查看镜像详细信息：inspect
```
[root@docker ~]# docker inspect ubuntu:14.04
    -f：指定查看其中一项内容
        [root@docker ~]# docker inspect -f {{".Os"}} ubuntu:14.04
        linux
    
```
### 查看镜像历史：将列出各层的创建信息
```
[root@docker ~]# docker history ubuntu:14.04
IMAGE               CREATED             CREATED BY                                      SIZE                COMMENT
dea1945146b9        3 weeks ago         /bin/sh -c #(nop)  CMD ["/bin/bash"]            0B                  
<missing>           3 weeks ago         /bin/sh -c mkdir -p /run/systemd && echo '...   7B                  
<missing>           3 weeks ago         /bin/sh -c sed -i 's/^#\s*\(deb.*universe\...   2.75kB              
<missing>           3 weeks ago         /bin/sh -c rm -rf /var/lib/apt/lists/*          0B                  
<missing>           3 weeks ago         /bin/sh -c set -xe   && echo '#!/bin/sh' >...   195kB               
<missing>           3 weeks ago         /bin/sh -c #(nop) ADD file:8f997234193c2f5...   188MB   
    --no-trunc选项来输出完整命令
```
### 搜寻镜像: search
    使用docker search命令可以搜索远端仓库中共享的镜像，默认搜索官方仓库中的镜像。
    docker search TERM，支持的参数主要包括：
        ·--automated=true|false：仅显示自动创建的镜像，默认为否；
        ·--no-trunc=true|false：输出信息不截断显示，默认为否；
        ·-s，--stars=X：指定仅显示评价为指定星级以上的镜像，默认为0，即输出所有镜像

### 导入镜像象
```
docker save [] > /PATH/[].tar.gz  或  docker save -o /PATH/[].tar.gz []
docker load < /PATH/[].tar.gz   或  docker load --input /PATH/[].tar.gz
```
### 删除镜像
```
docker rmi [IMAGE ID]
    -f：删除正在运行的镜像
[root@docker ~]# docker rm 2d986b70df9f
2d986b70df9f
```
### 上传镜像：push
```
docker push NAME[:TAG] | [REGISTRY_HOST[:REGISTRY_PORT]/]NAME[:TAG]

```
### 创建镜像
1. 基于已有镜像的容器创建
```
docker commit[OPTIONS]CONTAINER[REPOSITORY[：TAG]]，
    -a, --author=""：作者信息；
    -c, --change=[]: 提交的时候执行DockerFile命令，包括CMD|ENTRYPOINT|ENV|EXPOSE|LABEL|ONBUILD|USER|VOLUME|WORKDIR等；
    -m, --message="": 提交消息
    -p, --pause=true: 提交时暂停容器运行
[root@docker ~]# docker run -it ubuntu:14.04 /bin/bash
root@ee634d03fb5d:/# touch test
root@ee634d03fb5d:/# exit
exit
[root@docker ~]# docker commit -m "Add a test file" -a "AZ" ee634d03fb5d test:0.1
sha256:0cc1e527affa5b024fae3de86e3eb12a4e446b6cbb8b6c0a53b9ef716ae56313
[root@docker ~]# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
test                0.1                 0cc1e527affa        6 seconds ago       188MB
```
2. 基于本地模板导入
```
docker import[OPTIONS]file|URL|-[REPOSITORY[:TAG]]
$ cat ubuntu-14.04-x86_64-minimal.tar.gz | docker import - ubuntu:14.04
 
```
3. 基于DockerFile创建

### 搭建本地docker仓库
1. 使用registry镜像创建本地私有仓库
```
[root@docker ~]# docker run -d -p 5000:5000 registry
    -v：指定将镜像文件存放在本地的指定路径；-v /opt/data/registry:/tmp/registry
    默认会存放在registry的/tmp/registry目录下
```















## 操作容器相关

### 新建容器
```
$ docker create -it ubuntu:latest
af8f4f922dafee22c8fe6cd2ae11d16e25087d61f1b1fa55b36e94db7ef45178
$ docker ps -a
CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAME
Saf8f4f922daf ubuntu:latest "/bin/bash" 17 seconds ago Created silly_euler 
```

### 运行容器
```
docker run [OPTIONS] IMAGE [COMMAND] [ARG...]
    随机分配一个container id，用于标识
    --name：指定容器名称
    -t：分配一个伪终端tty并绑定到容器的标准输入上
    -i：让容器的标准输入保持打开的状态，与-t一起使用，使用交互模式
    /bin/bash：执行的命令
    --rm：容器停止就自动删除
    -d：daemon，守护进程运行
    -c：给运行在容器中的所有进程分配CPU的SHARES值，相对权重
    -m：限制为容器中所有进程分配的内存总量，B/K/M/G
    -v：用于挂载一个volume，可以用多个-v参数同时挂载多个volume，[host-dir]:[container-dir]:[rw|ro]
    -p：指定端口，hostPort:containerPort

[root@docker ~]# docker run --name mydocker -t -i centos /bin/bash
[root@6c584c04f22a /]# 

docker start ：启动已经存在的容器,-i开启交互模式
```
#### docker run时后台进行的操作
1. 检查本地是否存在指定的镜像，不存在就从公有仓库下载；
2. 利用镜像创建一个容器，并启动该容器；
3. 分配一个文件系统给容器，并在只读的镜像层外面挂载一层可读写层；
4. 从宿主主机配置的网桥接口中桥接一个虚拟接口到容器中；
5. 从网桥的地址池配置一个IP地址给容器；
6. 执行用户指定的应用程序；
7. 执行完毕后容器被自动终止
#### docker run常见错误
* 125: Docker Daemon执行出错，例如指定了不支持的Docker命令参数
* 126：所指定命令无法执行，如权限出错
* 127：容器内命令无法找到


### 停止容器
```
docker stop CONTAINER ID
docker kill ($docker ps -a)
```
### 查看容器
```
docker ps -a -l
```
### 进入容器：不推荐的方式
```
docker exec | docker attach 
    
[root@docker ~]# docker attach 6c584c04f22a
[root@6c584c04f22a /]#  
    attach：操作同步，exit后，会直接停止容器
[root@6c584c04f22a /]# exit
exit
[root@docker ~]# docker ps 
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
```
### docker日志
```
docker logs [ID]
```
### nsenter
```
Usage:
 nsenter [options] <program> [<argument>...]

Run a program with namespaces of other processes.

Options:
 -t, --target <pid>     target process to get namespaces from
 -m, --mount[=<file>]   enter mount namespace
 -u, --uts[=<file>]     enter UTS namespace (hostname etc)
 -i, --ipc[=<file>]     enter System V IPC namespace
 -n, --net[=<file>]     enter network namespace
 -p, --pid[=<file>]     enter pid namespace
 -U, --user[=<file>]    enter user namespace
 -S, --setuid <uid>     set uid in entered namespace
 -G, --setgid <gid>     set gid in entered namespace
     --preserve-credentials do not touch uids or gids
 -r, --root[=<dir>]     set the root directory
 -w, --wd[=<dir>]       set the working directory
 -F, --no-fork          do not fork before exec'ing <program>
 -Z, --follow-context   set SELinux context according to --target PID
 
[root@docker ~]# docker inspect --format "{{.State.Pid}}" 6c584c04f22a  # 获取PID
11385
[root@docker ~]# nsenter -t 11385 -u -i -n -p      # 进入容器
[root@6c584c04f22a ~]# 
```



## Docker数据管理
### 数据卷：特殊的容器，可以共享data给容器；容器内数据直接映射到本地主机环境
* 可以在容器之间共享和重用
* 对数据卷的修改会立马生效，无论是在容器内操作还是本地操作
* 对数据卷的更新，不会影响镜像，解耦应用和数据
* 数据卷默认会一直存在，及时容器删除也会存在

1. 创建数据卷
```
-v /data
-v src:dst      => 指定挂载一个本地主机目录到容器中去，src必须为绝对路径，DockerFile不支持此用法
-v src:dst:ro   => 指定为只读；默认为rw
-v ~/.bash_history:/.bash_history    => 可以从主机挂载单个文件到容器中作为数据卷（不推荐）

[root@Docker docker]# docker run -d -P --name web -v /webapp training/webapp python app.py
[root@Docker docker]# docker run -d -P --name web -v /src/webapp:/opt/webapp training/webapp python app.py
[root@Docker docker]# ll /src/
total 0
drwxr-xr-x. 2 root root 6 Apr 19 18:42 webapp            # 自动创建
```

### 数据卷容器
* 实质就是一个正常的容器，专门用来提供数据卷供其它容器挂载；如果删除了挂载的容器，数据卷不会自动被删除，如果要删除一个数据卷，必须在删除最后一个还挂载着它的容器时显式使用docker rm-v命令来指定同时删除关联的容器
```
--volume-from [卷名]      => 可以使用多个来指定从多个容器挂载不同的数据卷，也可以从其它已经挂载了数据卷的容器来级联挂载数据卷；不需要在运行状态
```

### 利用数据卷备份
```
# 创建dbdata数据卷
[root@Docker docker]# docker run -d -v /dbdata --name dbdata training/postgres echo Data-only container for postgres
# 备份，注意selinux
[root@Docker ~]# docker run --volumes-from dbdata -v $(pwd):/backup ubuntu tar cvf /backup/backup.tar /dbdata
tar: Removing leading `/' from member names        # selinux会导致失败
/dbdata/ 
    --volumes-from dbdata 让worker容器挂载dbdata容器的数据卷（即dbdata数据卷）
    -v $(pwd):/backup 挂载本地的当前目录到worker容器的/backup目录
    worker容器启动后，使用了tar cvf/backup/backup.tar/dbdata命令来将/dbdata下内容备份为容器内的/backup/backup.tar，即宿主主机当前目录下的backup.tar

[root@Docker ~]# ls
anaconda-ks.cfg  backup.tar  Projects
```
### 恢复
```
# 要恢复数据到一个容器，首先创建一个带有空数据卷的容器
[root@Docker ~]# docker run -v /dbdata --name dbdata2 ubuntu /bin/bash
# 恢复，创建另一个容器，一站式在dbdata2容器卷中的数据卷，并使用Untar解压备份文件到挂载的容器卷中
[root@Docker ~]# docker run --volumes-from dbdata2 -v $(pwd):/backup busybox tar xvf /backup/backup.tar
dbdata/   
```



## 容器互联

### 端口映射
    -P：Docker会随机映射一个49000~49900的端口到内部容器开放的网络端口
    -p：指定要映射的端口，并且，在一个指定端口上只可以绑定一个容器。
        -p hostPort:containerPort        
        -p ip:hostPort:containerPort        127.0.0.1:5000:5000
        -p ip::containerPort                => 随机端口，xxx.xxx.xxx.xxx::5000
        -p hostPort:cotainerPort:udp        => 指定协议 127.0.0.1:5000:5000/udp
    查看映射端口配置
       docker port <容器名称> [PRIVATE_PORT[/PROTO]]
       ```shell
        [root@docker ~]# docker port thirsty_davinci
        5000/tcp -> 0.0.0.0:32769
       ```
### 互联机制
容器的互联（linking）是一种让多个容器中应用进行快速交互的方式。它会在源和接收容器之间创建连接关系，接收容器可以通过容器名快速访问到源容器，而不用指定具体的IP地址。
    --link name:alias：name是要连接的容器名，alias是连接别名
    
        



















```
--link name:alias       => name是要链接的容器的名称，alias是这个连接的别名

docker run -d -P --name web --link db:db training/webapp python app.py

```

## 高级网络配置
    当Docker启动时，会自动柱塞同上创建一个 docker0 虚拟网桥，实际上是Linux的一个bridge，可以理解为一个软件交换机，它会在挂载到它的网口之间进行转发；
    Docker随机分配一个本地未占用的私有网段中的一个地址给docker0接口，此后启动的容器内的网口也会自动分配一个同一网段的地址； 
    当创建一个Docker容器的时候，同时会创建了一对veth pair接口(当数据包发送到一个接口时，另一个接口也可以收到相同的数据包)。这对接口一端在容器内，另一端在本地并被挂载到docker0网桥，名称以veth开头；通过这种方式，主机可以跟容器通信，容器之间也可以相互通信；Docker就创建了在主机和所有容器之间的一个虚拟共享网络
### 相关命令
Docker服务启动的时候配置，不能马上生效
* -b BRIDGE/--bridge=BRIDGE：指定容器挂载的网桥
* --bip=CIDR：定制dcoker0的掩码
* -H SOCKET.../--host=SOCKET...：Docker服务端接收命令的通道
* --icc=true|false：是否支持容器之间通信
* --ip-forward=true|false：转发
* --iptables=true|false：是否允许Docker添加Iptables规则
* --mtu=BYTES：容器网络中的MTU

可以在启动服务时指定，也可以在Docker容器启动时候指定，docker run的时候会覆盖
* --dns=IP_ADDRESS...：使用指定的DNS服务器
* --dns-search=DOMAIN...：指定DNS搜索域

只有在docker run执行时使用
* -h HOSTNAME/--hostname=HOSTNAME：配置容器主机名
* --link=CONTAINER_NAME:ALIAS：添加到另一个容器的连接
* --net=bridge|none|container:NAME_OR_ID|host：配置容器的桥接模式
* -p SPEC/--publish=SPEC：映射容器端口到宿主主机
* -P/--publish-all=true|false：映射容器所有端口到宿主主机

### 配置DNS
* 修改配置文件
```
[root@b6523b0329a2 /]# mount
...
/dev/sda3 on /etc/resolv.conf type xfs (rw,relatime,seclabel,attr2,inode64,noquota)
/dev/sda3 on /etc/hostname type xfs (rw,relatime,seclabel,attr2,inode64,noquota)
/dev/sda3 on /etc/hosts type xfs (rw,relatime,seclabel,attr2,inode64,noquota)
...
当宿主机的DNS信息发生更新后，所有Docker容器的dns配置通过/etc/resolv.conf文件立即得到更新
```
* 手动指定
```
-h HOSTNAME/--hostname=HOSTNAME：设定容器主机名，会被写道容器内的/etc/hostname和/etc/hosts，但在容器外看不到，不会在docker ps中显示，也不会在其它容器的/etc/hosts显示
--link=CONTAINER_NAME:ALIAS：选项会在读取容器的时候，添加一个其他容器的主机名到/etc/hosts文件中，让新容器的进程可以使用主机名ALIAS就可以连接它；
--dns=IP_ADDRESS：添加DNS服务器到容器的/etc/resolv.conf中，让容器用这个服务器来解析所有不在/etc/hosts中的主机名
--dns-search=DOMAIN：设定容器的搜索域，未指定--dns,--dns-search会使用主机上的/etc/resolv.conf配置容器；
```

### 容器访问外部网络
* 容器要访问外部网络，需要本地系统的转发支持
```
[root@b6523b0329a2 ~]# sysctl net.ipv4.ip_forward
net.ipv4.ip_forward = 1
0：未开启转发
1：开启转发

手动打开：
# sysctl -w net.ipv4.ip_forward=1
启动容器时设定：
添加参数--ip-forward=true
```

### 容器之间访问
* 检查容器的网络拓扑是否已经互联，默认都会被连接到docker0网桥上
* 检查本地系统的防火墙软件是否允许通过
```
访问所有端口：
    当启动Docker的时候，默认会添加一个转发策略到Iptables的FORWARD链上，策略为通过(ACCEPT)还是禁止(DROP)取决于配置 --icc=true(默认)还是
    --icc=false，如果手动制定--iptables=false则不会添加iptables规则；
    默认情况，不同容器间允许网络胡同

访问指定端口：
    --link=CONTAINER_NAME:ALIAS：可以访问容器的开放端口，Docker会在iptable中为两个容器分别添加一条ACCEPT规则，允许相互访问开发的端口，取决于Docker中的EXPOSE行
```

### 配置docker0网桥
    Docker服务默认会创建一个 docker0 网桥(其上有一个docker0内部接口)，它在内核层联通了其他的物理或虚拟网卡，将所有容器和本地主机都放到同一个物理网络
```
[root@docker ~]# brctl show
bridge name	bridge id		STP enabled	interfaces
docker0		8000.0242eb3e737d	no		veth71d8f9a
```
    docker默认指定了docker0接口的IP地址和子网掩码，也可以在启动时指定：
```
--bip=CIDR：192.168.x.x/xx
--mtu=BYTES
```
    默认配置
```
[root@b6523b0329a2 ~]# ip addr show eth0
13: eth0@if14: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP 
    link/ether 02:42:ac:11:00:02 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 172.17.0.2/16 scope global eth0
       valid_lft forever preferred_lft forever
[root@b6523b0329a2 ~]# ip route
default via 172.17.0.1 dev eth0 
172.17.0.0/16 dev eth0  proto kernel  scope link  src 172.17.0.2 
```

### 自定义网桥
```
[root@b6523b0329a2 ~]# systemctl stop docker
Killed
[root@docker ~]# ip link set dev docker0 down
[root@docker ~]# brctl delbr docker0

[root@docker ~]# brctl addbr bridge0
[root@docker ~]# ip addr add 172.16.20.1/24 dev bridge0
[root@docker ~]# ip link set dev bridge0 up
[root@docker ~]# ip addr show bridge0
16: bridge0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN qlen 1000
    link/ether 76:28:01:38:e0:db brd ff:ff:ff:ff:ff:ff
    inet 172.16.20.1/24 scope global bridge0
       valid_lft forever preferred_lft forever
    inet6 fe80::7428:1ff:fe38:e0db/64 scope link 
       valid_lft forever preferred_lft forever

配置docker服务，连接到创建的网桥上
[root@docker ~]# echo 'DOCKER_OPTS="-b=bridge0"' >> /etc/default/docker
[root@docker ~]# systemctl start docker
```



















应用示例：
# 启动redis
[root@docker ~]# docker run -it --name redis-master redis /bin/bash
[root@docker ~]# docker run -it --name redis-slave1 --link redis-master:master redis /bin/bash

# 启动django

# 启动HAPorxy



sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://y2n4p7sr.mirror.aliyuncs.com"]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker

