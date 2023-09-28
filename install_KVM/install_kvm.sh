#!/bin/bash

# 定义虚拟机名称、磁盘路径、操作系统镜像和Kickstart文件路径
read -p "请输入虚拟机的名称：" VM_NAME
#VM_NAME="myvm"
VM_DISK_PATH="/home/xuni/${VM_NAME}.qcow2"
#read -p "请输入您安装系统镜像的位置：" ISO_IMAGE
ISO_IMAGE="/home/ISO/CentOS-Stream-8-x86_64-latest-dvd1.iso"
KICKSTART_FILE="/root/ks.cfg"
#read -p "请指定KS文件位置" KICKSTART_FILE

# 创建虚拟机磁盘
qemu-img create -f qcow2 "${VM_DISK_PATH}" 20G

# 使用virt-install启动虚拟机安装过程
virt-install \
--name "${VM_NAME}" \
--memory 2048 \
--vcpus 2 \
--disk path="${VM_DISK_PATH}",format=qcow2 \
--os-type=linux \
--cdrom "${ISO_IMAGE}" \
--network network=default \
#--initrd-inject="${KICKSTART_FILE}"
--extra-args "ks=file://${KICKSTART_FILE}"
# 等待虚拟机安装完成
echo "等待安装完成..."
while ! virsh list --all | grep -q "${VM_NAME}"; do
  sleep 5
done

# 获取虚拟机的IP地址
VM_IP=$(virsh domifaddr "${VM_NAME}" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")

echo "虚拟机 ${VM_NAME} 的IP地址为：${VM_IP}"
echo "完成安装！"