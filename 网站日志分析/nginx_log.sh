#!/bin/bash
# 功能描述
# 统计信息包括：
# 1. 页面访问量PV
# 2. 用户量 UV
# 3. 人均访问量
# 4. 每个IP 的访问次数
# 5. HTTP 状态码统计
# 6. 累计页面字节流量
# 7. 热点数据

GREEN_COL='\033[32M'

NONE_COL='\033[0M'
line='echo ++++++++++++++++++++++++++++++++++++++++++++++++'

read -p "请输入日志文件：" logfile

echo 

# 统计页面访问量（PV）
PV=$(cat $logfile | wc -l)

# 统计用户数量（UV）

UV=$(cut -fl -d'' $logfile | sort | uniq | wc -l)

# 统计人均访问次量
Average_PV=$(echo "scale=2;$PV/$UV" | bc)

#统计每个IP的访问次数
declare -A IP
while  read ip other
do
    let IP[$ip] +=1
    
done < $logfile

# 5. HTTP 状态码统计

declare -A STATUS
while  read ip dash user time zone method file portocol code size other
do
    let $STATUS[$code]++
done < $logfile

# 累计页面累计访问字节大小
while read ip dash user time zone mothod file protocol coe size other
do
    let Body_size+=$size

done < $logfile


# 统计热点数据
declare -A URI 
while read ip dash user time zone mothod file protocol coe size other
do
    let URI[$file]++
done < $logfile

echo -e "\033[91m\t日志分析数据报表、033[0m"


#显示PV与UV 访问量，平均用户访问量
$line
echo -e "累计PV量：$GREEN_COL$PV$NONE_COL"
echo -e "累计UV量：$GREEN_COL$UV$NONE_COL"
echo -e "平均用户访问量：$GREEN_COL$Average_PV$UV$NONE_COL"

#显示网页累计访问字节数
$line

echo -e "累计访问字节数： $GREEN_COL $Body_size$NONE_COL Byte"


#显示指定的HTTP状态码数量
$line

for  i in 200 404 500
do
    if [ ${STATUS[$i]} ];then
        echo -e "$i状态码次数：$GREEN_COL$Body_size$NONE_COL Byte"
    else
        echo -e "$i状态码次数：$GREEN_COL 0 $NONE_COL"
    fi
done

#显示每个IP的访问次数
$line
for i in "${ ! IP [@] }"
do
    printf "%-15s的访问次数为：$GREEN_COL%s$NONE_COL\n"  $i ${ IP [ $i ] }
done
echo 

#显示访问量大于500 的URI
echo -e "$GREEN_COL 访问量大于500 的URI：$NONE_COL"
for i in "${ ! URI[@] }"
do
    if [ ${URI ["$i"]} -gt 500 ];then
        echo "-----------------------------"
        echo "$i"
        echo "${URI[$i]}次"
        echo "-----------------------------"
    fi
done