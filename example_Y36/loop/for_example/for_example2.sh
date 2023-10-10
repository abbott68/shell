#!/bin/bash
a=1
for var in {1..5}
do
    b=$((a++))
    echo "第 $b 次值：$var"
done