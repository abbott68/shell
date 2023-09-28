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

        elif [ $i  -eq  107 ]; then
            hostnamectl set-hostname k8s-node01
            echo "刷新bash"
            bash 
        elif [ $i  -eq  108 ]; then
            hostnamectl set-hostname k8s-node02
            echo "刷新bash"
     
        elif [ $i  -eq  109 ]; then
            hostnamectl set-hostname k8s-node03
            echo "刷新bash" 
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

# 函数：检查系统要求
function check_system_requirements() {
    # 检查操作系统版本
    os_version=$(cat /etc/os-release | grep '^VERSION_ID' | cut -d '"' -f 2)
    required_os_version="8"
    if [[ "$os_version" != "$required_os_version" ]]; then
        echo "错误：不支持的操作系统版本。需要 CentOS $required_os_version。"
        exit 1
    fi

    # 检查CPU和内存
    total_memory=$(free -g | awk '/^Mem/ {print $2}')
    total_cpu_cores=$(nproc)
    required_memory=4  # GB
    required_cpu_cores=2
    if ((total_memory < required_memory)); then
        echo "错误：内存不足。需要至少 $required_memory GB 内存。"
        exit 1
    fi
    if ((total_cpu_cores < required_cpu_cores)); then
        echo "错误：CPU核心数不足。需要至少 $required_cpu_cores 个CPU核心。"
        exit 1
    fi

    # 检查内核版本
    kernel_version=$(uname -r)
    required_kernel_version="5.4"  # Kubernetes要求的最低内核版本
    if [[ "$kernel_version" < "$required_kernel_version" ]]; then
        echo "错误：内核版本太低。需要至少内核版本 $required_kernel_version。"
        exit 1
    fi

    echo "系统要求检查通过。"
}

# 函数：安装Docker
function install_docker() {
    dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
    dnf install -y docker-ce
    systemctl enable --now docker
}

# 函数：安装Kubernetes工具
function install_kubernetes_tools() {
    cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

    dnf install -y kubelet kubeadm kubectl
    systemctl enable --now kubelet
}

# 函数：初始化Kubernetes Master节点
function initialize_kubernetes_master() {
    kubeadm init --pod-network-cidr=10.244.0.0/16

    # 配置kubectl
    mkdir -p $HOME/.kube
    cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    chown $(id -u):$(id -g) $HOME/.kube/config

    # 安装网络插件（这里以Calico为例）
    kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
}

# 函数：加入Kubernetes Worker节点
function join_kubernetes_worker() {
    # 在Master节点执行kubeadm init时，会输出一个加入集群的命令，类似于下面的格式：
    # kubeadm join <Master节点IP>:<Master节点端口> --token <令牌> --discovery-token-ca-cert-hash <哈希值>
    # 请将下面的命令替换为实际的kubeadm join命令
    kubeadm join <Master节点IP>:<Master节点端口> --token <令牌> --discovery-token-ca-cert-hash <哈希值>
}

# 主函数
function main() {
    check_system_requirements
    install_docker
    install_kubernetes_tools
    initialize_kubernetes_master
    join_kubernetes_worker

    echo "Kubernetes集群安装完成！"
}

# 调用主函数
main

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


