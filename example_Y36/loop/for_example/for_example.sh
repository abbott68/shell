#!/bin/bash
for var in 1 2 3 4 5 
do
       
       b=`expr $a - 1`
       a=5
       #b=$((a++))	
       echo "第 $b 次值：$var" 
done