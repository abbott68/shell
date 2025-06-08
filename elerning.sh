#!/bin/bash

# Java Jar 程序启动管理脚本
# 使用方法: ./runjar.sh {start|stop|restart|status}

# 应用名称(用于显示)
APP_NAME="e-lerning"

# 应用配置文件
APP_CONFIG="./config/application-local.yml"

# Jar 文件名称(确保此jar文件与脚本在同一目录，或指定完整路径)
JAR_FILE="./boot/exam-api.jar"

# Java 命令路径(如果不在PATH中，请指定完整路径)
JAVA_CMD="java"

# JVM 参数
JVM_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC -Dspring.profiles.active=prod"

# 工作目录(脚本会先cd到这个目录)
WORK_DIR=$(dirname "$0")

# 日志文件(输出重定向到该文件)
LOG_FILE="$WORK_DIR/logs/app.log"

# PID 文件(用于存储应用程序进程ID)
PID_FILE="$WORK_DIR/bin/app.pid"

# 检查并创建必要的目录
mkdir -p "$WORK_DIR/logs"
mkdir -p "$WORK_DIR/bin"

# 进入工作目录
cd "$WORK_DIR" || exit 1

# 检查Jar文件是否存在
if [ ! -f "$JAR_FILE" ]; then
    echo "Error: Jar file $JAR_FILE not found!"
    exit 1
fi

# 启动应用
start() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "$APP_NAME is already running (pid: $PID)"
            return 1
        else
            # 删除无效的PID文件
            rm -f "$PID_FILE"
        fi
    fi
    
    echo "Starting $APP_NAME..."
    #nohup $JAVA_CMD $JVM_OPTS -jar "$JAR_FILE" --spring.config.location="$APP_CONFIG"  &
    nohup $JAVA_CMD $JVM_OPTS -jar "$JAR_FILE" --spring.config.location="$APP_CONFIG" > /dev/null 2>&1 &    

    PID=$!
    echo $PID > "$PID_FILE"
    echo "$APP_NAME started with pid $PID"
    # echo "Log output: $LOG_FILE"
}

# 停止应用
stop() {
    if [ ! -f "$PID_FILE" ]; then
        echo "$APP_NAME is not running (pid file not found)"
        return 1
    fi
    
    PID=$(cat "$PID_FILE")
    echo "Stopping $APP_NAME (pid: $PID)..."
    
    if ! ps -p "$PID" > /dev/null 2>&1; then
        echo "$APP_NAME is not running (process not found)"
        rm -f "$PID_FILE"
        return 1
    fi
    
    kill "$PID"
    for i in $(seq 1 10); do
        if ! ps -p "$PID" > /dev/null 2>&1; then
            break
        fi
        echo -n "."
        sleep 1
    done
    echo
    
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "Force killing $APP_NAME (pid: $PID)"
        kill -9 "$PID"
        sleep 1
    fi
    
    rm -f "$PID_FILE"
    echo "$APP_NAME stopped"
}

# 查看应用状态
status() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "$APP_NAME is running (pid: $PID)"
            # 显示进程信息
            ps -fp "$PID"
            return 0
        else
            echo "$APP_NAME pid file exists but process not found"
            return 1
        fi
    else
        echo "$APP_NAME is not running"
        return 3
    fi
}

# 重启应用
restart() {
    stop
    sleep 2
    start
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac

exit 0
