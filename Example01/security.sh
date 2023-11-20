#!/bin/bash

# 安全审计和漏洞扫描脚本

# 设置输出文件
output_file="security_scan_report.txt"

# 执行系统信息收集
echo "收集系统信息..." > $output_file
date >> $output_file
echo "---------------------------" >> $output_file
uname -a >> $output_file
df -h >> $output_file
echo "" >> $output_file
for ip  in {1..254}
do
    ping  -c 3 192.168.218.$ip > /dev/null 
    if [ $? -eq 0 ]; then  
    # 执行漏洞扫描
    echo "执行漏洞扫描..." >> $output_file
    echo "---------------------------" >> $output_file

    # 在这里使用适合你的漏洞扫描工具，例如：Nmap、OpenVAS、Nessus等
    nmap -p 1-65535 -T4 -A -v 192.168.218.$ip >> $output_file
    echo "" >> $output_file

    # 执行安全审计
    echo "执行安全审计..." >> $output_file
    echo "---------------------------" >> $output_file
    # 在这里使用适合你的审计工具，例如 Lynis 或其他自定义脚本
    yum -y install lynis > /dev/null
    lynis audit system >> $output_file
    echo "" >> $output_file
   else
        echo 192.168.218.$ip down
   fi
done
# 结束脚本
echo "安全审计和漏洞扫描已完成。报告保存在 $output_file。"