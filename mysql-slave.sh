#!/bin/bash

# 安装MySQL 8.0
echo "Installing MySQL 8.0..."
sudo dnf install -y https://dev.mysql.com/get/mysql80-community-release-el8-1.noarch.rpm
sudo dnf install -y mysql-server

# 启动MySQL并设置开机自启
sudo systemctl start mysqld
sudo systemctl enable mysqld

# 配置MySQL安全性
mysql_secure_installation <<EOF

y
your-root-password
your-root-password
y
y
y
y
EOF

# 停止MySQL服务
sudo systemctl stop mysqld

# 配置从服务器复制
echo "Configuring MySQL replication on slave server..."
cat <<EOL | sudo tee -a /etc/my.cnf
server-id = 2
log_bin = /var/log/mysql/mysql-bin.log
relay_log = /var/log/mysql/mysql-relay-bin.log
log_slave_updates = 1
read_only = 1
EOL

# 启动MySQL服务
sudo systemctl start mysqld

# 连接到主服务器并开始复制
mysql -u root -p"your-root-password" <<EOF
CHANGE MASTER TO
  MASTER_HOST='master-server-ip',
  MASTER_PORT=3306,
  MASTER_USER='repl_user',
  MASTER_PASSWORD='repl_password',
  MASTER_LOG_FILE='$binlog_file',
  MASTER_LOG_POS=$binlog_position;
START SLAVE;
EOF

echo "Slave MySQL server setup is complete."
