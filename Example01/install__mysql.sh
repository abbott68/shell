#!/bin/bash
MEM_Capacity=$(free -h | grep Mem | awk '{print "总内存:" $2 "n" "剩余内存:" $4}')
fdisk_Capacity=$(df -h | grep /$ | awk '{print "磁盘总容量:" $2, "\n" "磁盘已使用:" $5, "\n" "磁盘剩余:"$4}')
menu() {
  echo =======主 菜 单=======
  echo =======1. 获取主机信息=======
  echo =======2. 选择安装方式=======
  echo =======3. 初 始 化=======
  echo =======4. 管 理 服 务=======
  echo =======5. 退出菜单程序=======
}

get_host_info() {
  echo =======1.系统版本 =======
  echo =======2.内核版本 =======
  echo =======3.内存信息 =======
  echo =======4.磁盘剩余=======
  echo =======5.返回主菜单 =======
  while
    true
    read -p "请输入你要查询的信息：" num
  do
    case $num in
    1)
      clear
      cat /etc/redhat-release
      ;;
    2)
      clear
      hostnamectl | grep Kernel | awk -F: '{print $2}'
      ;;
    3)
      clear
      echo $MEM_Capacity
      ;;
    4)
      clear
      echo $fdisk_Capacity
      ;;
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

Installation_Methods() {
  echo "======1、 源吗安装========="
  echo "======2、yum|dnf安装========="
  echo "======3、预编译二进制安装======"
  echo "======4、输入错误请重新输入======"
  read -p "请输入您需要安装的方式：" num
  case $num in
  1)
    read -p "是否使用源码部署Y/N" n
    if [ $n = y ]; then
      printf "先决条件，检查是否满足安装环境... \n 内存满足4G以上,磁盘空间大于30G以上 \n"
      fdisk_total=$(df -h | grep /$ | awk '{print "磁盘总容量:" $2}' | awk -F: '{print $2}' | grep -oP '\d*\.\d+')
      MEM_total=$(free -h | grep Mem | awk '{print "总内存:" $2}' | awk -F: '{print $2}' | grep -oP '\d*\.\d+')
      if
        [ $fdisk_total 30 ] >= && [ $MEM_total 4 ] >=
      then
        echo "恭喜您满足环境可以执行安装......."
      else
        echo "磁盘总容量" $fdisk_total
        echo "内存总容量" $MEM_total
        echo "不满足基本环境.... 退出程序！"
      fi
    fi
    ;;
  2)
    #选择要您所需要安装的版本
    read -p "选择您所需要的版本版本：例如mysql、mariadb数据库： " string
    case $string in
    mysql)
      echo -e "\033[34m install mysql-server \033[0m"
      OS_vresion=$(cat /etc/redhat-release | awk -F. '{print $1}' | awk '{print $4}')
      if [ $OS_vresion == 7 ]; then
        if [ -f /etc/yum.repos.d/mysql* ]; then
          echo -e "\033[34m install mysql \033[0m"
          yum -y install mysql-server mysql
          echo "已安装完成！请初始化mysql并设置密码"
        else
          yum -y install https://dev.mysql.com/get/mysql80-community-release-el7-11.noarch.rpm
          yum -y install mysql*
        fi
      elif [ $OS_vresion == 8 ];then
        if [ -f /etc/yum.repos.d/mysql* ]; then
          echo -e "\033[34m install mysql \033[0m"
          yum -y install mysql-server mysql
          echo "已安装完成！请初始化mysql并设置密码"
        else
          yum -y install https://dev.mysql.com/get/mysql80-community-release-el8-9.noarch.rpm
          yum -y install mysql*
          echo "已安装完成！请初始化mysql并设置密码"
        fi
      else
        echo "对不起系统不兼容"
      fi
      ;;
    mariadb)
      if [ $OS_vresion == 7 ]; then
        if [ -f /etc/yum.repos.d/mariadb* ]; then
          echo "正在安装......"
          yum -y install MariaDB-server MariaDB-client >/dev/null
          echo “安装完成”
        fi
        echo "正在配置源......."
        cat >/etc/yum.repos.d/mariadb.repo <<EOF
# MariaDB 11.1 CentOS repository list - created 2023-11-04 10:26 UTC
# https://mariadb.org/download/
[mariadb]
name = MariaDB
# rpm.mariadb.org is a dynamic mirror if your preferred mirror goes offline. See https://mariadb.org/mirrorbits/ for details.
# baseurl = https://rpm.mariadb.org/11.1/centos/\$releasever/\$basearch
baseurl = https://mirrors.neusoft.edu.cn/mariadb/yum/11.1/centos/\$releasever/\$basearch
module_hotfixes = 1
# gpgkey = https://rpm.mariadb.org/RPM-GPG-KEY-MariaDB
gpgkey = https://mirrors.neusoft.edu.cn/mariadb/yum/RPM-GPG-KEY-MariaDB
gpgcheck = 1
EOF
        echo "正在安装......"
        yum -y install MariaDB-server MariaDB-client >/dev/null
        echo “安装完成”
      elif [ $OS_vresion == 8 ]; then
        if [ -f /etc/yum.repos.d/mariadb* ]; then
          echo "正在安装......"
          yum -y install MariaDB-server MariaDB-client >/dev/null
          echo “安装完成”
        fi
        echo "正在配置源......."
        cat >/etc/yum.repos.d/mariadb.repo <<EOF
# MariaDB 11.1 CentOS repository list - created 2023-11-04 10:33 UTC
# https://mariadb.org/download/
[mariadb]
name = MariaDB
# rpm.mariadb.org is a dynamic mirror if your preferred mirror goes offline. See https://mariadb.org/mirrorbits/ for details.
# baseurl = https://rpm.mariadb.org/11.1/centos/\$releasever/\$basearch
baseurl = https://mirrors.neusoft.edu.cn/mariadb/yum/11.1/centos/\$releasever/\$basearch
# gpgkey = https://rpm.mariadb.org/RPM-GPG-KEY-MariaDB
gpgkey = https://mirrors.neusoft.edu.cn/mariadb/yum/RPM-GPG-KEY-MariaDB
gpgcheck = 1
EOF
        echo "正在安装......"
        dnf -y install MariaDB-server MariaDB-client >/dev/null
        echo “安装完成”
      fi
      echo "install mariadb-server"
      ;;
    *)
      echo "输入错误"
      ;;
    *)
      echo "输入错误,请重新输入...."
      ;;
    esac
    ;;
  esac
}
init_Safety() {
  read -p "please  Enter What kind of installation: " num1
  case $num1 in
  1)
    echo "源码安装"
    echo "抱歉还没上线。。。。"
    ;;
  2)
    echo "二进制安装"
    mysql_secure_installation
    if [ $? ！= 0 ]; then
      printf "初始化错误...未找到mysql.sock文件，请启动mysql服务...\n 你可以使用systemctl  start mysqld 或者systemctl status mysqld"
    fi
    ;;
  3)
    echo "预编译二进制安装"
    ;;
  *)
    echo "输入错误请重新输入"
    ;;
  esac
  echo ""
}
service_Manager() {
  echo "======1、 运行服务======="
  echo "======2、 停止服务======="
  echo "======3、 重启服务======="
  echo "======4、 输入错误======="
  read -p "请输入您要执行服务:" string
  case $string in
  start)
    systmectl start mysqld
    ;;
  stop)
    systmectl stop mysqld
    ;;
  restart)
    systmectl restart mysqld
    ;;
  status)
    systmectl status mysqld
    ;;
  *)
    echo -e "\033[31m Error输入错误；请重新输入.. start|stop| restart| status \033[0m"
    ;;
  esac
}
Exit_Program() {
  echo "======退出程序====="
  exit 1
}
menu
read -p "please Enter Option[1-5]: " num
case $num in
1)
  get_host_info
  ;;
2)
  Installation_Methods
  ;;
3)
  init_Safety
  ;;
4)
  service_Manager
  ;;
5)
  Exit_Program
  ;;
*)
  echo "输入错误；请重新输入...."
  ;;
esac
