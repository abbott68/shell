#!/bin/bash

echo "选择需要安装的环境:"
echo "1) LAMP"
echo "2) LNMP"
read choice

# 检测发行版
OS=""
if grep -qi "ubuntu" /etc/os-release || grep -qi "debian" /etc/os-release; then
    OS="debian"
elif grep -qi "centos" /etc/os-release || grep -qi "red hat" /etc/os-release; then
    OS="redhat"
else
    echo "不支持的操作系统"
    exit 1
fi

# 基于选择和操作系统进行安装
if [ "$choice" == "1" ]; then
    echo "开始安装 LAMP..."

    if [ "$OS" == "debian" ]; then
        sudo apt-get update
        sudo apt-get install -y apache2 mysql-server php libapache2-mod-php php-mysql
    elif [ "$OS" == "redhat" ]; then
        sudo yum install -y httpd mariadb-server php php-mysql
        sudo systemctl start httpd
    fi

    echo "LAMP 安装完成!"

elif [ "$choice" == "2" ]; then
    echo "开始安装 LNMP..."

    if [ "$OS" == "debian" ]; then
        sudo apt-get update
        sudo apt-get install -y nginx mysql-server php-fpm php-mysql
        sudo systemctl restart nginx
        sudo systemctl restart php7.4-fpm
    elif [ "$OS" == "redhat" ]; then
        sudo yum install -y nginx mariadb-server php-fpm php-mysql
        sudo systemctl start nginx
        sudo systemctl start php-fpm
    fi

    echo "LNMP 安装完成!"

else
    echo "无效选择!"
fi
