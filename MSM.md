MSM(memcached session manager)是一款实现Tomcat话保持的管理组件,支持粘性和无粘性的配置, 目前可以在Tomcat6,7,8中使用,并且支持Memcached会话故障转移；

环境：
* 两个Tomcat节点：10.0.0.32、10.0.0.33
* 两个Memcached节点：10.0.0.32、10.0.0.33
* Nginx节点：10.0.0.34

## 准备：
### 下载MSM：https://github.com/magro/memcached-session-manager/wiki/SetupAndConfiguration
* memcached-session-manager-${version}.jar
* memcached-session-manager-tc${6,7,8}-${version}.jar
* spymemcached-${version}.jar
* msm-javolution-serializer-${version}.jar
* javolution-${version}.jar


### Tomcat 1 配置：
<Host name="localhost"  appBase="webapps"
    unpackWARs="true" autoDeploy="true">
<Context path="/test" docBase="/usr/local/tomcat/webapps/test" reloadable="true">        # 一定要是绝对路径，否则不能MSM
<Manager className="de.javakaffee.web.msm.MemcachedBackupSessionManager"
    memcachedNodes="n1:10.0.0.32:11211,n2:10.0.0.33:11211"
    failoverNodes="n2"
    requestUriIgnorePattern=".*\.(ico|png|gif|jpg|css|js)$"
    transcoderFactoryClass="de.javakaffee.web.msm.serializer.javolution.JavolutionTranscoderFactory"
/>
</Context>
<Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
    prefix="t_aztest_access_log" suffix=".txt"
    pattern="%h %l %u %t &quot;%r&quot; %s %b" />

# mkdir -pv /usr/local/tomcat/webapps/test/WEB-INF/{classes,lib}
# vim /usr/local/tomcat/webapps/test/index.jsp
添加如下内容：
<%@ page language="java" %>
<html>
  <head><title>TomcatA</title></head>
  <body>
    <h1><font color="red">TomcatA.aztest.com</font></h1>
    <table align="centre" border="1">
      <tr>
        <td>Session ID</td>
    <% session.setAttribute("aztest.com","aztest.com"); %>
        <td><%= session.getId() %></td>
      </tr>
      <tr>
        <td>Created on</td>
        <td><%= session.getCreationTime() %></td>
     </tr>
    </table>
  </body>
</html>

### 配置负载均衡
upstream msm_servers {
    server 10.0.0.32:8080;
    server 10.0.0.33:8080;
}

server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://msm_servers;
        proxy_set_header X-Forwarded-For $remote_addr;
    }
}

### 先启动memcached，再启动tomcat

### 检测
```
访问：http://10.0.0.34/test/

TomcatA.aztest.com
Session ID	D208E525F81A1D33A69BBDC8A2D8E799-n1.jvm1
Created on	1493375199613

TomcatB.aztest.com
Session ID	D208E525F81A1D33A69BBDC8A2D8E799-n1.jvm1
Created on	1493375199613
```