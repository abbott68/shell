#!/bin/bash

#!/bin/bash

# 获取本地信息
TIME=$(date "+%Y-%m-%d %H:%M:%S")
HOSTNAME=$(hostname)
IP=$(hostname -I | awk '{print $1}')

cat >/web/site1/index.html <<EOF
<!DOCTYPE html>
<html lang="zh">
<head>
  <meta charset="UTF-8">
  <title>本地主机信息</title>
  <style>
    body {
      font-family: "Segoe UI", sans-serif;
      background: #f2f6fc;
      color: #333;
      display: flex;
      align-items: center;
      justify-content: center;
      height: 100vh;
      margin: 0;
    }
    .card {
      background: #fff;
      border-radius: 16px;
      padding: 30px 40px;
      box-shadow: 0 8px 20px rgba(0,0,0,0.1);
      text-align: center;
    }
    h1 {
      margin-bottom: 20px;
      color: #2c3e50;
    }
    p {
      font-size: 18px;
      margin: 10px 0;
    }
    .label {
      font-weight: bold;
      color: #555;
    }
  </style>
</head>
<body>
  <div class="card">
    <h1> This is Site 1</h1>
    <h2>🌐 本地主机信息</h12>
    <p><span class="label">🕒 本地时间：</span>$TIME</p>
    <p><span class="label">💻 主机名：</span>$HOSTNAME</p>
    <p><span class="label">📡 内网 IP：</span>$IP</p>
  </div>
</body>
</html>
EOF

echo -e "\e[32m✅ 已生成 iindex.html，可以使用浏览器或者curl $IP 打开即可查看 \e[0m"


