#/bin/bash
 modify_hostsname(){
    echo "#修改主机名"
    IP=$(ip ad  | egrep  inet | awk  '{print $2}'| grep  192 | gawk -F. '{print $4}' | gawk -F/ '{print $1}')
    if  [ $i   -eq 102 ]; then
        hostnamectl set-hostname k8s-master
        echo "刷新bash"
  
    elif [ $i  -eq  107 ]; then
        hostnamectl set-hostname k8s-node01
        echo "刷新bash"

    elif [ $i  -eq  108 ]; then
        hostnamectl set-hostname k8s-node02
        echo "刷新bash"

    elif [ $i  -eq  109 ]; then
        hostnamectl set-hostname k8s-node03
        echo "刷新bash"
    else
        echo "没有匹配到所有"
    fi  
    echo "修改完成主机名完成"
}

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

    echo "#关闭swap分区"
    cp /etc/fstab  /etc/fstab.bak  
    cat /etc/fstab.bak  | grep -v swap    >  /etc/fstab
}

modify_kernel() {
echo "#开启路由转发"
cat > /etc/sysctl.d/k8s.conf << EOF
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
echo    "#配置模块"
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
echo    "#加载模块"
modprobe overlay
modprobe br_netfilter
echo "#刷新内核"
sysctl --system
#查看模块是否加载
echo "#查看模块是否加载"
lsmod | grep br_netfilter
lsmod | grep overlay
}


upgrade_kernel() {
#升级内核
echo "#升级内核"
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
yum --disablerepo="*" --enablerepo="elrepo-kernel" list available
yum --enablerepo=elrepo-kernel install kernel-ml
grub2-editenv list
cat /boot/grub2/grub.cfg | grep 'menuentry'
grub2-set-default 'CentOS Linux (6.2.0-1.el7.elrepo.x86_64) 7 (Core)'

if [ $? -eq  0 ];then
    reboot
else
    echo "不能重启"
fi
}

read -p "是否初始化环境：" input
if [ $input = ok ];then
modify_hostsname
disable_firewall_selinux
modify_kernel
upgrade_kernel
fi
















