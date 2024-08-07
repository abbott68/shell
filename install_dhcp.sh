#!/bin/bash

# 函数：获取活动的网络接口名称
get_interface_name() {
    local interface_name
    interface_name=$(ip -o -4 route show to default | awk '{print $5}')
    echo "$interface_name"
}

# 函数：配置主机的静态IP地址
configure_static_ip() {
    local interface_name="$1"
    local ip_address="192.168.18.254"
    local netmask="255.255.255.0"

    sudo nmcli con mod "$interface_name" ipv4.addresses "$ip_address/$netmask"
    sudo nmcli con mod "$interface_name" ipv4.method manual
    sudo nmcli con up "$interface_name"
}

# 函数：安装并配置DHCP服务器
configure_dhcp_server() {
    # 安装DHCP服务器
    sudo yum update -y
    sudo yum install -y dhcp

    # 配置DHCP服务器
    cat <<EOL | sudo tee /etc/dhcp/dhcpd.conf
# DHCP Server Configuration file.
# see /usr/share/doc/dhcp*/dhcpd.conf.sample

subnet 192.168.18.0 netmask 255.255.255.0 {
    range 192.168.18.10 192.168.18.100;
    option routers 192.168.18.254;
    option subnet-mask 255.255.255.0;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
    option domain-name "example.com";
}

default-lease-time 600;
max-lease-time 7200;

authoritative;
EOL

    # 设置DHCP服务器监听的网络接口
    echo "DHCPDARGS=$1;" | sudo tee /etc/sysconfig/dhcpd

    # 启动并启用DHCP服务
    sudo systemctl start dhcpd
    sudo systemctl enable dhcpd
}

# 主程序
main() {
    local interface_name
    interface_name=$(get_interface_name)

    if [ -z "$interface_name" ]; then
        echo "未找到有效的网络接口。请检查网络配置。"
        exit 1
    fi

    echo "网络接口：$interface_name"

    configure_static_ip "$interface_name"
    configure_dhcp_server "$interface_name"

    # 检查DHCP服务状态
    sudo systemctl status dhcpd

    echo "DHCP服务器配置完成。"
}

# 执行主程序
main
