#/bin/bash
#功能描述
#安装kubernets

#菜单功能
menu(){
    clear 
    echo "--------------------------------------"
    echo "#    菜   单"
    echo "--------------------------------------"
    echo "1. 初始化环境"
    echo "2. 安装kubernets"
    echo "3. 退出安装"
    echo "--------------------------------------"
}
#初始化环境
init(){
    clear 
    echo "--------------------------------------"
    echo "#    菜   单"
    echo "--------------------------------------"
    echo "1. 修改主机名"
    echo "2. 关闭防火墙/selinux/swap"
    echo "3. 升级系统内核"
    echo "--------------------------------------"
    
}



#部署kukbernets
#
modify_hostsname(){
    echo "#修改主机名"
    IP=$(ip ad  | egrep  inet | awk  '{print $2}'| grep  192 | gawk -F. '{print $4}' | gawk -F/ '{print $1}')
    for  i in $IP 
    do 
        if  [ $i   -eq 102 ]; then
            hostnamectl set-hostname k8s-master
            echo "刷新bash"
            bash 
        elif [ $i  -eq  107 ]; then
            hostnamectl set-hostname k8s-node01
            echo "刷新bash"
            bash 
        elif [ $i  -eq  108 ]; then
            hostnamectl set-hostname k8s-node02
            echo "刷新bash"
            bash 
        elif [ $i  -eq  109 ]; then
            hostnamectl set-hostname k8s-node03
            echo "刷新bash"
            bash 
        else
            echo "没有匹配到所有"
        fi
    done  
    echo "修改完成主机名完成"
}
#关闭防火墙和selinux
disable_firewall_selinux(){
    echo "#关闭防火墙"
    status=running
    state=$(firewall-cmd --state)
    if [ $state =  $status ];then
            systemctl disable --now firewalld
        else
            echo "无需修改:" $state
    fi

    echo "#关闭selinux"
    Selinux_status=$getenforce 
    if [ $Selinux_status = Enforcing ];then
        echo "===========临时关闭=============="
        setenforce 0
        echo "===========永久关闭=============="
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
    fi
    echo "关闭swap分区"
    swap_status=$(free  -m  | grep Swap | awk '{print $2}')
    if  [ $swap_status -ne 0 ]; then
         cp /etc/fstab  /etc/fstab.bak  
         cat /etc/fstab.bak  | grep -v swap    >  /etc/fstab
    else
        echo "swap的状态"$swap_status"无需修改"
    fi

    
}



#主要操作菜单
menu
read -p "请输入以下选项的操作：" input 
case $input in
1)
init
;;
2)
;;
3)
;;
esac


