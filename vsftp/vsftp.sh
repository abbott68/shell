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
#定义服务管理的子菜单
service_sub_menu(){
    clear
    echo "--------------------------------------"
    echo "#  服 务 管 理 子 菜 单  "
    echo "--------------------------------------"
    echo "1、启动 vsftpd"
    echo "2、关闭 vsftpd"
    echo "3、重启 vsftpd"
    echo "--------------------------------------"
    echo 
}

#定义配置匿名账户的子菜单
anon_sub_menu(){
    clear 
    echo "--------------------------------------"
    echo "# 匿 名 管 理 子 菜 单"
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
    if rpm -q vsftpd  &> /dev/null; then
        $WARNING
        echo "vsftpd 已安装"
        $NORMAL
        exit
    else 
        yum -y install vsftpd
    fi
}

#初始化配置文件
init_config(){
    [ ! -e $conf_file.bak ] && cp $conf_file{,.bak}

    [ ! -d /common/pub ] && mkdir -p /common/pub
    
    chmod a+w /common/pub
   
    grep -q local_root $conf_file || sed -i '$a local_root=/common' $conf_file 

    sed -i  's/^#chroot_local_user=YES/chroot_local_user=YES/' $conf_file
}


#创建FTP账户，如果账户已存在则直接退出脚本
create_ftpuser(){
    if id $1 &>  /dev/null; then
        $FAILURE
        echo "$1 账户已存在"
        $NORMAL
        exit

    else
        useradd $1
        echo "$2"  | passwd --stdin  $1 &>  /dev/null
    fi
}

#删除FTP用户
delete_ftpUser(){
    if  ! id $1 &> /dev/null; then
        $FAILURE
        echo "$1 账户不存在"
        $NORMAL
        exit
    else
        userdel $1
    fi
}

#配置匿名用户
anon_config(){
    if [ ! -f $conf_file ];then
        $FAILURE
        echo "配置文件不存在"
        $NORMAL
        exit
    fi

    case $1 in 
        1)
            sed -i 's/anonymous_enable=YES/anonymous_enable=NO/' $conf_file
            systemctl restart vsftpd;;
        2)
            sed -i 's/anonymous_enable=NO/anonymous_enable=YES/' $conf_file
            systemctl restart vsftpd;;
        3) 
            sed -i 's/^#anon_/anon_/' $conf_file
            chmod a+x  /var/ftp/pub
            systemctl restart vsftpd;;
    esac
}

#服务管理
proc_manager(){
    if ! rpm -q vsftpd &>  /dev/null; then
        $FAILURE
        echo "未安装vsftpd 软件包"
        $NORMAL
        exit
    fi
    
    case  $1 in 
        start)
            systemctl start vsftpd;;
        stop)
            systemctl stop vsftpd;;
        restart)
            systemctl restart vsftpd;;
    esac
}
menu
read -p "请输入选项【1-6】：" input

case $input in
    1)
        test_yum
        install_vsftpd
        init_config
        ;;
    2)
        read -p "请输入账户名称：" username
        read -s -p "请输入账户密码：" password
        echo
        create_ftpuser $username $password
        ;;
    3)
        read -p "请输入账户名称：" username
        delete_ftpUser $username $password
        ;;
    4)
        anon_sub_menu
        read -p "请输入选项【1-3】:" anon
        if [ $anon -eq 1 ];then
            anon_config 1
        elif [ $anon -eq 2 ];then
            anon_config 2
        elif [ $anon -eq 3 ];then
            anon_config 3 
        fi
        ;;
    5)  
        service_sub_menu
        read -p "请输入选项【1-3】：" proc
        if [ $proc -eq 1 ];then
            proc_manager   start
        elif [ $proc -eq 2 ];then
            proc_manager   stop 
        elif [ $proc -eq 3 ];then
            proc_manager restart
        fi
        ;;
    6)
        exit;;
    *)
        $FAILURE
        echo "您输入的有误"
        $NORMAL
        exit;;
esac

