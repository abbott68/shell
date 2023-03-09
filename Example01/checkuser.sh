#!/bin/bash
#功能描述 检查用户是否为root的用户

if [ $UID -ne 0 ]; then
    echo "不是root用户，情使用root用户登录" 
else
    echo "是root用户"
fi
