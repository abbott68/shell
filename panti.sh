# 创建判题脚本框架，涵盖磁盘管理、YUM、httpd、nginx、Tomcat 等检查点
# 输出为字符串脚本内容

lvm_check = """
#!/bin/bash
echo "=== 检查 LVM 配置 ==="
VG=$(vgs | grep vg_data)
LV=$(lvs | grep lv_web)
MOUNTED=$(mount | grep /webdata)
FSTAB=$(grep /webdata /etc/fstab)
TESTFILE=$(cat /webdata/test.txt 2>/dev/null)

if [[ -n "$VG" && -n "$LV" && -n "$MOUNTED" && -n "$FSTAB" && "$TESTFILE" == "LVM OK" ]]; then
  echo "[+] LVM 配置正确"
else
  echo "[-] LVM 配置有误"
fi
"""

yum_check = """
echo "=== 检查 YUM 源配置 ==="
YUM_REPO=$(ls /etc/yum.repos.d/ | grep .repo)
HTTPD_INSTALLED=$(yum list installed httpd 2>/dev/null | grep httpd)

if [[ -n "$YUM_REPO" && -n "$HTTPD_INSTALLED" ]]; then
  echo "[+] YUM 源配置正确，httpd 已安装"
else
  echo "[-] YUM/YUM 安装检查失败"
fi
"""

httpd_check = """
echo "=== 检查 Apache 配置 ==="
HTTPD_RUNNING=$(ss -tnlp | grep :80 | grep httpd)
FIREWALL_RULE=$(firewall-cmd --list-all | grep services | grep http)
PAGE_CONTENT=$(curl -s http://localhost | grep -i "apache")

if [[ -n "$HTTPD_RUNNING" && -n "$FIREWALL_RULE" && -n "$PAGE_CONTENT" ]]; then
  echo "[+] Apache 配置正常"
else
  echo "[-] Apache 配置错误"
fi
"""

nginx_check = """
echo "=== 检查 Nginx 配置 ==="
NGINX_RUNNING=$(ss -tnlp | grep :80 | grep nginx)
HOSTS1=$(grep www.site1.com /etc/hosts)
HOSTS2=$(grep www.site2.com /etc/hosts)
SITE1=$(curl -s http://www.site1.com | grep "website1")
SITE2=$(curl -s http://www.site2.com | grep "website2")

if [[ -n "$NGINX_RUNNING" && -n "$HOSTS1" && -n "$HOSTS2" && -n "$SITE1" && -n "$SITE2" ]]; then
  echo "[+] Nginx 虚拟主机配置正常"
else
  echo "[-] Nginx 配置或站点访问失败"
fi
"""

tomcat_check = """
echo "=== 检查 Tomcat 配置 ==="
TOMCAT_RUNNING=$(ss -tnlp | grep :8080 | grep java)
JENKINS_PAGE=$(curl -s http://localhost:8080/jenkins | grep -i jenkins)
FIREWALL_RULE=$(firewall-cmd --list-ports | grep 8080)

if [[ -n "$TOMCAT_RUNNING" && -n "$JENKINS_PAGE" && -n "$FIREWALL_RULE" ]]; then
  echo "[+] Tomcat 启动并部署成功"
else
  echo "[-] Tomcat 启动失败或访问失败"
fi
"""

full_script = f"""#!/bin/bash
# Linux 上机判题脚本

{lvm_check}
{yum_check}
{httpd_check}
{nginx_check}
{tomcat_check}
"""

# 保存为脚本文件
with open("/mnt/data/judge_script.sh", "w") as f:
    f.write(full_script)

"/mnt/data/judge_script.sh"
