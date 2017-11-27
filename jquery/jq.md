fadeOut() 淡出
fadeToggle() 切换淡入淡出
hide() 隐藏元素
show() 显示元素
toggle() 依次展示或隐藏某个元素
slideDown() 向下展开
slideUp() 向上卷起
slideToggle() 依次展开或卷起某个元素

$("#div1").addClass("divClass2") //为id为div1的对象追加样式divClass2
$("#div1").removeClass("divClass")  //移除id为div1的对象的class名为divClass的样式
$("#div1").removeClass("divClass divClass2") //移除多个样式
$("#div1").toggleClass("anotherClass") //重复切换anotherClass样式

$(document) //选择整个文档对象
$('li') //选择所有的li元素
$('#myId') //选择id为myId的网页元素
$('.myClass') // 选择class为myClass的元素
$('input[name=first]') // 选择name属性等于first的input元素
$('#ul1 li span') //选择id为为ul1元素下的所有li下的span元素

$('#ul1 li:first') //选择id为ul1元素下的第一个li
$('#ul1 li:odd') //选择id为ul1元素下的li的奇数行
$('#ul1 li:eq(2)') //选择id为ul1元素下的第3个li
$('#ul1 li:gt(2)') // 选择id为ul1元素下的前三个之后的li
$('#myForm :input') // 选择表单中的input元素
$('div:visible') //选择可见的div元素

$('div').has('p'); // 选择包含p元素的div元素
$('div').not('.myClass'); //选择class不等于myClass的div元素
$('div').filter('.myClass'); //选择class等于myClass的div元素
$('div').first(); //选择第1个div元素
$('div').eq(5); //选择第6个div元素

$('div').prev('p'); //选择div元素前面的第一个p元素
$('div').next('p'); //选择div元素后面的第一个p元素
$('div').closest('form'); //选择离div最近的那个form父元素
$('div').parent(); //选择div的父元素
$('div').children(); //选择div的所有子元素
$('div').siblings(); //选择div的同级元素
$('div').find('.myClass'); //选择div内的class等于myClass的元素


尺寸相关、滚动事件
    1、获取和设置元素的尺寸
        width()、height()    获取元素width和height  
        innerWidth()、innerHeight()  包括padding的width和height  
        outerWidth()、outerHeight()  包括padding和border的width和height  
        outerWidth(true)、outerHeight(true)   包括padding和border以及margin的width和height
    2、获取元素相对页面的绝对位置
        offset()
    3、获取可视区高度
        $(window).height();
    4、获取页面高度
        $(document).height();
    5、获取页面滚动距离
        $(document).scrollTop();  
        $(document).scrollLeft();
    6、页面滚动事件
        $(window).scroll(function(){  
            ......  
        })


jquery动画：
    $(selector).animate(styles,speed,easing,callback)
        speed:
            毫秒 （比如 1500）
            "slow"
            "normal"
            "fast"
        easing:
            swing
            linear


事件冒泡：

事件委托：
    delegrade/undelegrade

节点操作：
    在现成的元素内部后面插入元素：append/appendTo
    在现有元素内部前面插入元素：prepend()/prependTo()
    外部后面插入：after()/insertAfter()
    外部前面插入：before()/insertBefore()
