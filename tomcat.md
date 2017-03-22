Tomcat性能调优
  Tomcat 优化分为系统优化，Java虚拟机调优Tomcat本身的优化。
系统优化
  对于操作系统优化来说，是尽可能的增大可使用的内存容量、提高CPU的频率，保证文件系统的读写速率等。经过压力测试验证，在并发连接很多的情况下，CPU的处理能力越强，系统运行速度越快。
 
Java虚拟机调优
  应该选择SUN的JVM，在满足项目需要的前提下，尽量选用版本较高的JVM，一般来说高版本产品在速度和效率上比低版本会有改进。
JDK1.4比JDK1.3性能提高了近10%-20%，JDK1.5比JDK1.4性能提高25%-75%。
因此对性能要求较高的情况推荐使用 JDK1.6。
  启动原始参数，未加调优状态
    TOMCAT_HOME=/home/web/apache-tomcat-6.0.20
    JAVA_HOME=/usr/local/SDK/jdk
    CLASSPATH=$CLASSPATH:$JAVA_HOME/lib:$JAVA_HOME/jre/lib
    PATH=$PATH:$HOME/bin:./:$JAVA_HOME/bin:$JAVA_HOME/jre/bin
    export TOMCAT_HOME JAVA_HOME CLASSPATH CATALINA_OPTS PATH

# JVM参数调优：-Xms<size> 表示JVM初始化堆的大小，-Xmx<size>表示JVM堆的最大值。
    这两个值的大小一般根据需要进行设置。当应用程序需要的内存超出堆的最大值时虚拟机就会提示内存
  溢出，并且导致应用服务崩溃。
    因此一般建议堆的最大值设置为可用内存的最大值的80%,设置JAVA_OPTS='-Xms6g -Xmx6g'，表示初始
  化内存为6GB，可以使用的最大内存为6GB。
  Heap Size 最大不要超过可用物理内存的80％，一般的要将-Xms和-Xmx选项设置为相同
  
  堆内存分配
    JVM初始分配的内存由-Xms指定，默认是物理内存的1/64；JVM最大分配的内存由-Xmx指定，默认是物理
  内存的1/4。默认空余堆内存小于40%时，JVM就会增大堆直到-Xmx的最大限制；空余堆内存大于70%时，
  JVM会减少堆直到-Xms的最小限制。因此服务器一般设置-Xms、-Xmx相等避免在每次GC 后调整堆的大小。
  
  非堆内存分配
    JVM使用-XX:PermSize设置非堆内存初始值，默认是物理内存的1/64；由XX:MaxPermSize设置最大非堆
  内存的大小，默认是物理内存的1/4。
  
  JVM内存限制(最大值)
    首先JVM内存限制于实际的最大物理内存，假设物理内存无限大的话，JVM内存的最大值跟操作系统有很
  大的关系。简单的说就32位处理器虽然可控内存空间有4GB,但是具体的操作系统会给一个限制，这个限制
  一般是2GB-3GB（一般来说Windows系统下为1.5G-2G，Linux系统下为2G-3G），而64bit以上的处理器就不
  会有限制了。
  JAVA_OPTS="-server -Xms2048M -Xmx2048M -Xss256k -XX:+AggressiveOpts -XX:+UseParallelGC
    -XX:+UseBiasedLocking"
  配置示例：JAVA_OPTS="-server -XX:PermSize=128M -XX:MaxPermSize=256M -XX:MaxNewSize=256M"
            JAVA_OPTS="$JAVA_OPTS -Xms2048M -Xmx2048M -Xss128K"
  2. 禁用DNS查询
　  当web应用程序向要记录客户端的信息时，它也会记录客户端的IP地址或者通过域名服务器查找机器名
  转换为IP地址。
    DNS查询需要占用网络，并且包括可能从很多很远的服务器或者不起作用的服务器上去获取对应的IP的
  过程，这样会消耗一定的时间。
  修改server.xml文件中的enableLookups参数值: enableLookups="false"
  3. 调整线程数
    通过应用程序的连接器（Connector）进行性能控制的的参数是创建的处理请求的线程数。
    Tomcat使用线程池加速响应速度来处理请求。在Java中线程是程序运行时的路径，是在一个程序中与其
  它控制线程无关的、能够独立运行的代码段。它们共享相同的地址空间。多线程帮助程序员写出CPU最
  大利用率的高效程序，使空闲时间保持最低，从而接受更多的请求。
  示例如下：
    <Connector port="80" protocol="HTTP/1.1"
        maxThreads="600" 最多运行线程数  
        minSpareThreads="100" 初始化创建的线程数
        maxSpareThreads="500"
          最多能创建的线程数,一旦创建的线程超过这个值，Tomcat就会关闭不再需要socket线程.
        acceptCount="700" 指定当所有可以使用的处理请求的线程数都被使用时
          可以放到处理队列中的请求数，超过这个数的请求将不予处理
        connectionTimeout="20000"
        enableLookups="false"
        redirectPort="8443" />
  4.加速JSP编译速度
    在元素中定义一个名字叫“compiler”，并且在value中有一个支持编译的编译器名字.
    示例如下： vi web.xml
      <init-param>
      <param-name>compiler</param-name>
      <param-value>jikes</param-value>
      </init-param>
 
  5.Tomcat6线程池(Executor Thread pool)的配置 
    第一步，打开共享的线程池
        <Executor name="tomcatThreadPool" namePrefix="catalina-exec-" 
            maxThreads="1000" minSpareThreads="50" maxIdleTime="600000"/>
      name 这个是线程池的名字，必须唯一，后面的配置里要用到这个东西 
      namePrefix 线程的名字前缀，用来标记线程名字，每个线程就用这个前缀加上线程编号了，比如 
        catalina-exec-1 
        catalina-exec-2 
      maxThreads 允许的最大线程池里的线程数量，默认是200
        大的并发应该设置的高一些，只是限制而已，不占用资源 
      minSpareThreads 最小的保持活跃的线程数量，默认是25.
        要根据负载情况自行调整了:太小影响反应速度，太大占用资源。 
      maxIdleTime 超过最小活跃线程数量的线程，空闲时间超过这个设置后，会被关闭,默认是1分钟。 
      threadPriority 线程的等级。默认是Thread.NORM_PRIORITY 
    第二步 在Connector里指定使用共享线程池
      <Connector port="8009" ... maxThreads="5000" executor="tomcatThreadPool" ... />
      注意，一旦使用了线程池，则其它的线程属性，比如 maxThreads等将被忽略

  6.在tomcat中设置session过期时间
    在\conf\web.xml中通过参数指定：
    <session-config>   
        <session-timeout>180</session-timeout>     
    </session-config> 单位为分钟。

 Apr插件提高Tomcat性能
  Tomcat可以使用APR来提供超强的可伸缩性和性能，更好地集成本地服务器技术.
  APR(Apache Portable Runtime)是一个高可移植库，它是Apache HTTP Server 2.x的核心。APR有很多用途，包括访问高级IO功能(例如sendfile,epoll和OpenSSL)，OS级别功能(随机数生成，系统状态等等)，本地进程管理(共享内存，NT管道和UNIX sockets)。这些功能可以使Tomcat作为一个通常的前台WEB服务器，能更好地和其它本地web技术集成，总体上让Java更有效率作为一个高性能web服务器平台而不是简单作为后台容器。
  在产品环境中，特别是直接使用Tomcat做WEB服务器的时候，应该使用Tomcat Native来提高其性能  
  要测APR给tomcat带来的好处最好的方法是在慢速网络上（模拟Internet），将Tomcat线程数开到300以上的水平，然后模拟一大堆并发请求。
  如果不配APR，基本上300个线程狠快就会用满，以后的请求就只好等待。但是配上APR之后，并发的线程数量明显下降，从原来的300可能会马上下降到只有几十，新的请求会毫无阻塞的进来。
  在局域网环境测，就算是400个并发，也是一瞬间就处理/传输完毕，但是在真实的Internet环境下，页面处理时间只占0.1%都不到，绝大部分时间都用来页面传输。如果不用APR，一个线程同一时间只能处理一个用户，势必会造成阻塞。所以生产环境下用apr是非常必要的。
  (1)安装APR tomcat-native
    apr-1.3.8.tar.gz   安装在/usr/local/apr
    #tar zxvf apr-1.3.8.tar.gz
    #cd apr-1.3.8
    #./configure;make;make install
    
    apr-util-1.3.9.tar.gz  安装在/usr/local/apr/lib
    #tar zxvf apr-util-1.3.9.tar.gz
    #cd apr-util-1.3.9  
    #./configure --with-apr=/usr/local/apr ----with-java-home=JDK;make;make install
    
    #cd apache-tomcat-6.0.20/bin  
    #tar zxvf tomcat-native.tar.gz  
    #cd tomcat-native/jni/native  
    #./configure --with-apr=/usr/local/apr;make;make install
    
  (2)设置 Tomcat 整合 APR
    修改 tomcat 的启动 shell （startup.sh），在该文件中加入启动参数：
      CATALINA_OPTS="$CATALINA_OPTS -Djava.library.path=/usr/local/apr/lib" 。
 
  (3)判断安装成功:
    如果看到下面的启动日志，表示成功。
