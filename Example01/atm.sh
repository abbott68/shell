#!/bin/bash

balance=1000  # 初始余额设为1000元

while true; do
    echo "欢迎使用银行取款机!"
    echo "请选择操作:"
    echo "1. 查询余额"
    echo "2. 存款"
    echo "3. 取款"
    echo "4. 退出"
    read choice

    case $choice in
        1)
            echo "您的余额为: $balance 元"
            ;;
        2)
            echo "请输入存款金额:"
            read deposit
            if [[ "$deposit" =~ ^[0-9]+$ ]] && [ "$deposit" -gt 0 ]; then
                balance=$(($balance + $deposit))
                echo "存款成功! 当前余额为: $balance 元"
            else
                echo "无效的存款金额!"
            fi
            ;;
        3)
            echo "请输入取款金额:"
            read withdrawal
            if [[ "$withdrawal" =~ ^[0-9]+$ ]] && [ "$withdrawal" -le $balance ] && [ "$withdrawal" -gt 0 ]; then
                balance=$(($balance - $withdrawal))
                echo "取款成功! 当前余额为: $balance 元"
            else
                echo "取款失败! 请确保输入的是有效金额并且不超过当前余额。"
            fi
            ;;
        4)
            echo "谢谢使用，再见!"
            break
            ;;
        *)
            echo "无效选择，请重新输入!"
            ;;
    esac
done
