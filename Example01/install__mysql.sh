#!/bin/bash
MEM_Capacity=$(free -h | grep  Mem |awk '{print "总内存:" $2 "n" "剩余内存:" $4}')
fdisk_Capacity=$(df -h | grep /$   | awk '{print "磁盘总容量:" $2, "\n" "磁盘已使用:" $5, "\n" "磁盘剩余:"$4}')
menu() {
    echo  =======主    菜    单=======
    echo  =======1. 获取主机信息=======
    echo  =======2. 选择安装方式=======
    echo  =======3.  初  始  化=======
    echo  =======4. 管 理 服 务=======
    echo  =======5. 退出菜单程序=======
}

get_host_info() {
  echo  =======1.系统版本 ======= 
  echo  =======2.内核版本 ======= 
  echo  =======3.内存信息 ======= 
  echo  =======4.磁盘剩余======= 
  echo  =======5.返回主菜单 ======= 
  while true
  read -p "请输入你要查询的信息：" num
  do
      case $num in 
      1) 
      clear
      cat /etc/redhat-release ;;
      2) 
      clear
      hostnamectl   | grep  Kernel  | awk -F: '{print $2}';;
      3) 
      clear
      echo $MEM_toal;;
      4) 
      clear
      echo $fdisk_Capacity;;
      5)
      menu
      break
      ;;
      *)
      echo "输入错误;"
      exit 1 
      ;;
      esac 
  done
}

Installation_Methods(){
  echo "======1、 源吗安装========="
  echo "======2、yum|dnf安装========="
  echo "======3、预编译二进制安装======"
  echo "======4、输入错误请重新输入======"
  read  -p "请输入您需要安装的方式：" num
  case $num in 
  1)
    read  -p  "是否使用源码部署Y/N" n
    if [ $n  == y ];then
    printf  "先决条件，检查是否满足安装环境... \n 内存满足4G以上,磁盘空间大于30G以上 \n"
    fdisk_total=$(df -h | grep /$   | awk '{print "磁盘总容量:" $2}'| awk -F: '{print $2}'|grep -oP '\d*\.\d+')
    MEM_total=$(free -h | grep  Mem |awk '{print "总内存:" $2}'| awk -F: '{print $2}'|grep -oP '\d*\.\d+') 
      if [ $fdisk_total -ge  30 ] & [$MEM_total -ge  4 ];then 
        echo "恭喜您满足环境可以执行安装......."
      else 
        echo "磁盘总容量" $fdisk_total
        echo "内存总容量" $MEM_total
        echo "不满足基本环境.... 退出程序！" 
      fi  
    fi
  ;;
  2)
  echo "使用yum|dnf 安装" 
  ;;
  *)
  echo "输入错误"
  ;;
  esac
}
init_Safety(){
  read  -p "please  Enter What kind of installation: " num1
  case $num1 in
  1) 
  echo "源码安装";;
  2) 
  echo "二进制安装";;
  3) 
  echo "预编译二进制安装";;
  *) 
  echo "输入错误请重新输入";;
  esac
  echo ""
}
service_Manager(){
  echo "======1、 运行服务======="
  echo "======2、 停止服务======="
  echo "======3、 重启服务======="
  echo "======4、 输入错误======="
  read -p  "请输入您要执行服务:" n
  case $n  in
  1) start;;
  2) stop ;;
  3) restart ;;
  *) Error;;
  esac
}
Exit_Program(){
  echo "======退出程序====="
  exit 1
}
menu
read -p "please Enter Option[1-5]: " num
case  $num in 
        1)
        get_host_info
        ;;
        2)
        Installation_Methods
        ;;
        3)
        init_Safety ;;
        4)
        service_Manager;;
        5)
        Exit_Program;;
        *)
        echo "输入错误；请重新输入"
        ;;
esac
