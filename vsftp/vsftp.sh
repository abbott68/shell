#!/bin/bash

SUCCESS="echo -en \\033[1;32m"  #绿色
FAILURE="echo -en \\033[1;31m"  #红色
WARNING="echo -en \\033[1;33m"  #黄色
NORMAL="echo -en \\033[1;39m"   #红色


#定义脚本的主菜单功能
menu(){
    clear 
    echo "--------------------------------------"
    echo "#    菜   单"
    echo "--------------------------------------"
    echo "1、安装配置"
    echo "2、创建FTP账户"
    echo "3、删除FTP账户"
    echo "4、配置匿名账户"
    echo "5、启动关闭vsftpd"
    echo "6、推出脚本"
    echo "--------------------------------------"
}

#定义配置匿名账户的子菜单

anon_sub_menu(){
    clear 
    echo "--------------------------------------"
    echo "#    菜   单"
    echo "--------------------------------------"
    echo "1、禁止匿名账户"
    echo "2、启用匿名登录"
    echo "3、允许匿名账户上传"
    echo "--------------------------------------"
    echo
}


#定义YUM是否可用

test_yum(){
    num=$(yum repolist | tail -l |sed 's/.*: *//;s/,//')
    if [ $num -le 0 ];then
        $FAILURE
        echo "没有可用的Yun源"
        $NORMAL
        exit
    else
        if ! yum list vsftpd &> /dev/null ;then
        $FAILURE
        echo "Yum 源 中没有vsftpd软件包"
        $NORMAL
        exit
    fi
fi
}

#安装部署vsftpd 软件包
install_vsftpd(){
    echo "test"
}

#初始化配置文件
install_config(){
    echo "config"
}


#创建FTP账户，如果账户已存在则直接退出脚本
create_ftpuser(){
    echo "creat ftpuser"
}

#删除FTP用户
delete_ftpUser(){
    echo "delet ftpUser"
}

#配置匿名用户
anon_config(){
    echo "配置匿名用户"
}

#服务管理
proc_manager(){
    echo "服务管理"
}
menu
read -p "请输入选项【1-6】：" input

case $input in
    1)
        test_yum
        ;;
    2)
        ;;
    3)
        ;;
    4)
        ;;
esac

