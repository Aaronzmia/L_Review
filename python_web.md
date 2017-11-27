## 动态URL规则：
eg:
    @app.route('/item/<id>/')
    def item(id):
        return 'Item: {}'.format(id)

格式：<convert:variable_name>
    * string：接受任何没有斜杠'/'的文本
    * int：接受整数
    * float：接受浮点数
    * path：和默认的相似，接受斜杠'/'
    * uuid：只接受uuid字符串
    * any：可以指定多种路径，但是需要传入参数；@app.route('/<any(a,b):page_name')

## HTTP方法
eg：
    @app.route('/login', methods=['GET', 'POST'])
HTTP方法：
    * GET：获取资源，GET操作应该是幂等
    * HEAD：获取头信息；应用应该像处理GET请求一样处理HEAD请求，但是不返回实际内容
    * POST：创建一个新的资源
    * PUT：完整地替换资源或者创建资源；PUT操作有副作用，但应该幂等
    * DELETE：删除资源，幂等
    * OPTIONS：获取资源支持的所有HTTP方法
    * PATCH：局部更新，修改某个已有的资源


## 构造url：url_for
用url_for构建url，接受函数名作为第一个参数，也接受对应URL规则的变量部分的命名参数，未知的变量部分会添加到URL结尾作为查询参数，优点：
    1. 未来更改的时候只需要一次性修改URL，而不用到处替换
    2. URL构建会转义特殊字符和Unicode数据
eg：
    @app.route('/item/1/')
    def item(id):
        pass
    with app.test_request_context():
        print(url_for('item', id='1'))
        print(url_for('item', id=2, next='/'))
    ==========================================
    /item/1/?id=1
    /item/1/?id=2&next=%2F


## 跳转和重定向：redirect
跳转：
    301：永久重定向，指定code=301
    302：临时重定向，默认302
    abort(xxx)：放弃请求返回xxx
eg：
    @app.route('/people/')                            # 访问/people的请求永久重定向到/people/
    def people():
        name = request.args.get('name')
        if not name:
            return redirect(url_for('login'))          # 重定向到/login/，302
        user_agent = request.headers.get('User-Agent')
        return 'Name: {}; UA: {}'.format(name, user_agent)


## 响应
视图函数的返回值会被自动转换为一个响应对象，转换的逻辑如下：
    * 如果返回的是一个合法的响应对象，会从视图直接返回
    * 如果返回的是一个字符串，会用字符串数据和默认参数创建以字符串为主体，状态码为200，MIME类型是text/html的werkzeug.wrappers.Response响应对象
    * 如果返回的是一个元组，且元组中的元素可以提供额外的信息，这样的元组必须是(response, status, headers)的形式，但是需要至少包含一个元素，status的值会覆盖状态代码，headers可以是一个列表或字典，作为额外的消息头；
    * 如果上述条件都不满足，Flask会假设返回值是一个合法的WSGI应用程序，并通过Response.force_type(rv,request.environ)转换为一个请求对象。

eg:
    @app.errorhandler(404)
    def not_found(error):
        resp = make_response(render_template('error.html'),404)
        return resp


## 静态文件管理
1. flask默认将静态文件css,js等放在static目录下，在应用中使用"/static/FILE"访问
2. 不要在模板中写死静态文件路径，使用url_for：url_for('static', filename='FILE')
3. 定制静态文件真实目录：app = Flask(__name__, static_folder='/tmp')


...



# jinja2

## 变量
    {{ foo.bar }}
    {{ foo['bar'] }}

## 过滤器
    变量可以通过 过滤器 修改。过滤器与变量用管道符号（ | ）分割，并且也 可以用圆括号传递可选参数。多个过滤器可以链式调用，前一个过滤器的输出会被作为 后一个过滤器的输入。
     {{ name|striptags|title }} 
     {{ list|join(', ') }}    
## Delimiters（分隔符）
    {% ... %} 语句（Statements）
    {{ ... }} 打印模板输出的表达式（Expressions）
    {# ... #} 注释
    # ... ## 行语句（Line Statements）

## 控制结构
    {% for ... %}
    {% endfor %}
## 模板继承
    <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
    <html lang="en">
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        {% block head %}
        <link rel="stylesheet" href="style.css" />
        <title>{% block title %}{% endblock %} - My Webpage</title>
        {% endblock %}
    </head>
    <body>
        <div id="content">{% block content %}{% endblock %}</div>
        <div id="footer">
            {% block footer %}
            &copy; Copyright 2008 by <a href="http://domain.invalid/">you</a>.
            {% endblock %}
        </div>
    </body>

    继承：
    {% extends "base.html" %}                  # 继承父模板
    {% block title %}Index{% endblock %}
    {% block head %}
        {{ super() }}
        <style type="text/css">
            .important { color: #336699; }
        </style>
    {% endblock %}
    {% block content %}
        <h1>Index</h1>
        <p class="important">
        Welcome on my awesome homepage.
        </p>
    {% endblock %}

## 赋值
    {% set a = 1 %}
    {% set a,b = range(2) %}

## import, 宏
macro.html
    {% macro hello(name) %}
        Hello {{ name }}
    {% endmacro %}
    {% macro strftime(time, fmt='%Y-%m-%d %H:%M:%S') %}
        {{ time.strftime(fmt) }}
    {% endmacro %}

    {% import 'macro.html' as macro %}
    {% from 'macro.html' import hello as _hello, strftime %}
    <p>{{ macro.hello('world') }}</p>
    <p>{{ strftime(time) }}</p>


# 数据库

## 常用方法：
    close(): 关闭连接
    commit()：提交，但如果数据库不支持事务，提交无效，关闭连接后如果还有未提交的事务，会隐式回滚(需要数据库支持)
    cursor：游标

    cur方法：游标是系统为用户开设的一个数据缓冲区，存放SQL语句的执行结果
        callproc(name[,params])：使用给定的名称和对象调用已命名的数据库程序
        close()：关闭游标
        execute(oper[,params])：执行SQL操作，可能使用参数
        executemany(oper, pseq)：对序列的每个参数执行SQL
        fetchone()：把查询的结果集中的下一行保存为序列，或者None
        fetchmany([size])：获取查询结果的多行，默认尺寸为arraysize，可以指定返回前N行
        fetchall()：将所有的行作为序列的序列，返回行的元组
        nextset()：跳至下一个应用的结果集
        setinputsizes(sizes)：为参数预定义内存区域
        setoutputsizes(size[,col])：为获取的大数据值设定设定缓冲区尺寸

## ORM
eg: 
    from sqlalchemy import create_engine, Column, Integer, String, ForeignKey
    from sqlalchemy.ext.declarative import declarative_base
    from sqlalchemy.orm import sessionmaker, relationship

    In [1]: from sqlalchemy import create_engine
    In [2]: engine = create_engine('sqlite://', echo=False)
    In [3]: with engine.connect() as con:
        ...:     rs = con.execute('SELECT 1')
        ...:     print(rs.fetchone())
        ...:     
    (1,)
    create_engine()用来初始化数据库连接。SQLAlchemy用一个字符串表示连接信息：
        '数据库类型+数据库驱动名称://用户名:口令@机器地址:端口号/数据库名'
    
    Base = declarative_base()     # 创建对象的基类
    Session = sessionmaker(bind=eng)   # 创建Session类型
    session = Session()   # 创建session
    



# Context

## 本地线程,Thread Local, 不同的线程对于内容的修改只在线程内发挥作用，线程之间互不影响
    import threading
    mydata = threading.local()

    Werkzeug




## 静态文件管理