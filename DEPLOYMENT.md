# 生产环境部署指南 (Production Deployment Guide)

## 📋 目录

1. [部署前检查清单](#部署前检查清单)
2. [Linux服务器部署](#linux服务器部署)
3. [Windows服务器部署](#windows服务器部署)
4. [Nginx反向代理配置](#nginx反向代理配置)
5. [系统监控与维护](#系统监控与维护)
6. [备份与恢复](#备份与恢复)
7. [故障恢复](#故障恢复)
8. [性能优化](#性能优化)

---

## 部署前检查清单

### 硬件要求

| 组件 | 最小要求 | 推荐配置 |
|------|---------|---------|
| CPU | 2核 | 4核+ |
| 内存 | 2GB | 8GB+ |
| 存储 | 10GB | 50GB+（日志） |
| 网络 | 100Mbps | 1Gbps |

### 软件要求

- [ ] Python 3.7+ 已安装
- [ ] Oracle Client 已安装
- [ ] Nginx / Apache（反向代理）
- [ ] Supervisor / systemd（进程管理）
- [ ] 防火墙配置完成

### 安全检查

- [ ] 数据库密码已更改为强密码
- [ ] 应用运行用户权限最小化
- [ ] HTTPS/SSL证书已准备
- [ ] 防火墙规则已配置
- [ ] 日志审计已启用

### 数据库检查

- [ ] Oracle数据库已启动
- [ ] `zy_wpypmx` 表已创建并包含数据
- [ ] 备份策略已制定
- [ ] 用户账户和权限已配置

---

## Linux服务器部署

### 1. 系统准备

```bash
# 更新系统
sudo apt-get update
sudo apt-get upgrade -y

# 安装Python和基本工具
sudo apt-get install -y python3 python3-pip python3-venv git
sudo apt-get install -y curl wget vim

# 安装Oracle Instant Client
wget https://download.oracle.com/otn_software/linux/instantclient/...
unzip instantclient-basic-linux.x64-*.zip
sudo mv instantclient_* /opt/oracle/

# 配置环境变量
echo 'export LD_LIBRARY_PATH=/opt/oracle/instantclient_19_3:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc
```

### 2. 项目部署

```bash
# 创建应用目录
sudo mkdir -p /var/www/tumor-card-app
sudo chown -R $USER:$USER /var/www/tumor-card-app
cd /var/www/tumor-card-app

# 拷贝项目文件
git clone https://github.com/your-repo/tumor-info-card.git .

# 创建虚拟环境
python3 -m venv venv
source venv/bin/activate

# 安装依赖
pip install -r requirements.txt
pip install gunicorn
```

### 3. 配置应用

```bash
# 编辑配置文件
nano server.py
```

修改数据库连接信息：
```python
DB_CONFIG = {
    "user": "your_prod_user",
    "password": "your_strong_password",
    "dsn": cx_Oracle.makedsn("prod-db.example.com", "1521", service_name="prod")
}
```

### 4. 使用Gunicorn启动

```bash
# 启动Gunicorn（4个worker进程）
gunicorn -w 4 -b 0.0.0.0:5000 server:app

# 更好的方式：使用socket文件
gunicorn -w 4 --bind unix:/tmp/tumor_card.sock server:app
```

### 5. 使用Systemd管理

创建 `/etc/systemd/system/tumor-card.service`：

```ini
[Unit]
Description=Tumor Information Card System
After=network.target

[Service]
Type=notify
User=www-data
Group=www-data
WorkingDirectory=/var/www/tumor-card-app
Environment="PATH=/var/www/tumor-card-app/venv/bin"
ExecStart=/var/www/tumor-card-app/venv/bin/gunicorn \
    --workers 4 \
    --bind unix:/tmp/tumor_card.sock \
    --timeout 60 \
    --access-logfile /var/log/tumor-card/access.log \
    --error-logfile /var/log/tumor-card/error.log \
    server:app

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

启动服务：
```bash
# 创建日志目录
sudo mkdir -p /var/log/tumor-card
sudo chown www-data:www-data /var/log/tumor-card

# 启用和启动服务
sudo systemctl enable tumor-card
sudo systemctl start tumor-card
sudo systemctl status tumor-card
```

---

## Windows服务器部署

### 1. 环境设置

```cmd
# 作为管理员打开PowerShell
# 安装Python（若未安装）
# 从 https://www.python.org/downloads/ 下载并安装

# 检查Python
python --version

# 创建应用目录
mkdir C:\apps\tumor-card-app
cd C:\apps\tumor-card-app
```

### 2. 部署应用

```cmd
# 创建虚拟环境
python -m venv venv
call venv\Scripts\activate.bat

# 安装依赖
pip install -r requirements.txt
pip install pywin32
pip install python-service-wrapper
```

### 3. 创建Windows服务

```cmd
# 安装NSSM（Non-Sucking Service Manager）
# 从 https://nssm.cc/download 下载

# 配置服务
nssm install TumorCard "C:\apps\tumor-card-app\venv\Scripts\python.exe" "C:\apps\tumor-card-app\server.py"

# 设置环境变量
nssm set TumorCard AppEnvironmentExtra PATH=C:\Oracle\instantclient_19_3;%PATH%

# 启动服务
nssm start TumorCard

# 检查服务状态
nssm status TumorCard
```

### 4. 使用批处理脚本启动

编辑 `startup.bat`：
```batch
@echo off
cd /d C:\apps\tumor-card-app
call venv\Scripts\activate.bat
title Tumor Card System
python server.py
pause
```

---

## Nginx反向代理配置

### 1. 安装Nginx

**Linux**：
```bash
sudo apt-get install -y nginx
```

**Windows**：从 http://nginx.org/en/download.html 下载

### 2. 配置文件

编辑 `/etc/nginx/sites-available/tumor-card`：

```nginx
# Upstream定义
upstream tumor_card_backend {
    server unix:/tmp/tumor_card.sock fail_timeout=0;
    # 或使用TCP：server 127.0.0.1:5000;
}

# HTTP重定向到HTTPS
server {
    listen 80;
    server_name tumor-card.example.com;
    return 301 https://$server_name$request_uri;
}

# 主服务器配置
server {
    listen 443 ssl http2;
    server_name tumor-card.example.com;
    
    # SSL证书配置
    ssl_certificate /etc/letsencrypt/live/tumor-card.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/tumor-card.example.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    # 日志
    access_log /var/log/nginx/tumor-card-access.log;
    error_log /var/log/nginx/tumor-card-error.log;
    
    # 客户端上传大小限制
    client_max_body_size 10M;
    
    # 反向代理配置
    location / {
        proxy_pass http://tumor_card_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # 静态文件缓存
    location /static/ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
    
    # 日志不记录某些请求
    location = /favicon.ico {
        access_log off;
    }
    location = /robots.txt {
        access_log off;
    }
}
```

### 3. 启用配置

```bash
# 创建符号链接
sudo ln -s /etc/nginx/sites-available/tumor-card /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重启Nginx
sudo systemctl restart nginx
```

### 4. SSL证书（使用Let's Encrypt）

```bash
# 安装Certbot
sudo apt-get install -y certbot python3-certbot-nginx

# 申请证书
sudo certbot certonly --standalone -d tumor-card.example.com

# 自动续期
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

---

## 系统监控与维护

### 1. 日志监控

```bash
# 实时查看应用日志
tail -f /var/log/tumor-card/error.log

# 实时查看Nginx日志
tail -f /var/log/nginx/tumor-card-access.log

# 查看特定时间的日志
grep "2026-04-19" /var/log/tumor-card/error.log
```

### 2. 性能监控

```bash
# 使用top监看进程
top

# 查看内存使用
free -h

# 查看磁盘使用
df -h

# 查看网络连接
netstat -tulpn | grep :5000
```

### 3. 定期清理日志

创建 `/etc/logrotate.d/tumor-card`：

```
/var/log/tumor-card/*.log {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    create 0640 www-data www-data
    sharedscripts
    postrotate
        systemctl reload tumor-card > /dev/null 2>&1 || true
    endscript
}
```

### 4. 监控脚本

创建 `monitor.sh`：

```bash
#!/bin/bash

# 检查应用是否运行
if ! pgrep -f "gunicorn.*server:app" > /dev/null; then
    echo "应用已停止！正在重启..."
    systemctl restart tumor-card
    echo "应用已重启"
fi

# 检查数据库连接
if ! curl -s "http://localhost:5000/api/treatment/001" > /dev/null; then
    echo "数据库连接失败！"
    # 发送告警邮件
    echo "数据库连接问题" | mail -s "告警" admin@example.com
fi

# 检查磁盘空间
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 90 ]; then
    echo "磁盘使用率过高：${DISK_USAGE}%"
fi
```

设置crontab定期运行：
```bash
# 每5分钟运行一次
*/5 * * * * /var/www/tumor-card-app/monitor.sh
```

---

## 备份与恢复

### 1. 数据库备份(Oracle)

```bash
# 创建备份目录
mkdir -p /backups/oracle

# 每日全量备份
BACKUP_DATE=$(date +%Y%m%d)
expdp jcjk/password \
    DIRECTORY=backupdir \
    DUMPFILE=zy_wpypmx_${BACKUP_DATE}.dmp \
    LOGFILE=zy_wpypmx_${BACKUP_DATE}.log \
    TABLES=zy_wpypmx
```

### 2. 应用文件备份

```bash
#!/bin/bash
# 每天备份一次应用

BACKUP_DIR="/backups/tumor-card"
APP_DIR="/var/www/tumor-card-app"
DATE=$(date +%Y%m%d)

mkdir -p $BACKUP_DIR
tar -czf $BACKUP_DIR/app_${DATE}.tar.gz $APP_DIR

# 保留30天的备份
find $BACKUP_DIR -name "app_*.tar.gz" -mtime +30 -delete
```

### 3. 自动备份计划

```bash
# crontab配置
# 每天凌晨2点执行备份
0 2 * * * /usr/local/bin/backup_tumor_card.sh >> /var/log/backup.log 2>&1
```

---

## 故障恢复

### 问题1：应用崩溃

```bash
# 检查日志
systemctl status tumor-card
journalctl -u tumor-card -n 50

# 重启应用
systemctl restart tumor-card

# 如果仍未恢复，检查Python环境
source /var/www/tumor-card-app/venv/bin/activate
python /var/www/tumor-card-app/server.py
```

### 问题2：数据库连接失败

```bash
# 测试Oracle连接
sqlplus jcjk/password@192.168.120.110:1521/orcl

# 检查网络连接
ping 192.168.120.110
telnet 192.168.120.110 1521

# 检查防火墙
sudo ufw status
```

### 问题3：磁盘空间满

```bash
# 清理日志
sudo truncate -s 0 /var/log/tumor-card/*.log

# 删除旧备份
find /backups -mtime +60 -delete

# 压缩旧日志
find /var/log -name "*.log" -type f -mtime +30 | xargs gzip
```

### 问题4：性能下降

```bash
# 检查数据库连接数
SELECT COUNT(*) FROM v$session WHERE username = 'JCJK';

# 增加应用worker数（在systemd服务文件中修改）
--workers 8

# 检查是否有慢查询
SELECT * FROM v$sql WHERE elapsed_time > 1000000;
```

---

## 性能优化

### 1. 数据库优化

```sql
-- 创建索引以加快查询
CREATE INDEX idx_zhuyuanhao_bingrenxm ON zy_wpypmx(ZHUYUANHAO, BINGRENXM);
CREATE INDEX idx_fashengrq ON zy_wpypmx(FASHENGRQ);

-- 查看执行计划
EXPLAIN PLAN FOR 
SELECT * FROM zy_wpypmx WHERE ZHUYUANHAO = '001';

-- 更新统计信息
ANALYZE TABLE zy_wpypmx COMPUTE STATISTICS;
```

### 2. 应用优化

```python
# 在server.py中增加缓存
from flask_caching import Cache

cache = Cache(app, config={'CACHE_TYPE': 'simple'})

@app.route('/api/treatment/<string:hospital_no>')
@cache.cached(timeout=300)  # 缓存5分钟
def get_treatment(hospital_no):
    # ... 代码
```

### 3. 连接池优化

```python
# 增加连接池大小
pool = cx_Oracle.SessionPool(
    ...
    min=5,      # 最小连接
    max=20,     # 最大连接
    increment=2,
    ...
)
```

### 4. 前端优化

```html
<!-- 启用GZIP压缩 -->
<!-- 在Nginx中配置 -->
gzip on;
gzip_vary on;
gzip_types text/plain text/css application/json;

<!-- 使用CDN -->
<!-- 缓存静态文件 -->
```

---

## 监控和告警

### Prometheus + Grafana 监控

**prometheus.yml**：
```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'tumor-card'
    static_configs:
      - targets: ['localhost:5000']
```

### 告警规则

```yaml
groups:
  - name: tumor_card
    rules:
    - alert: AppDown
      expr: up{job="tumor-card"} == 0
      for: 5m
      annotations:
        summary: "应用已停止"
        
    - alert: HighErrorRate
      expr: rate(errors_total[5m]) > 10
      annotations:
        summary: "错误率过高"
```

---

## 安全加固

### 1. 防火墙配置

```bash
# 只允许HTTPS
sudo ufw allow 443/tcp
sudo ufw allow 80/tcp  # 仅用于重定向
sudo ufw deny 5000/tcp  # 禁止直接访问应用端口
```

### 2. 应用安全

```python
# 在server.py中添加安全头
@app.after_request
def set_security_headers(response):
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    return response
```

---

## 灾难恢复计划

### RTO / RPO 目标

| 指标 | 目标 |
|------|------|
| RTO（恢复时间目标） | 1小时 |
| RPO（恢复点目标） | 1小时 |

### 恢复步骤

1. **15分钟内**：启用备用服务器
2. **30分钟内**：恢复数据库备份
3. **60分钟内**：完整系统在线

---

**定期测试备份以确保可恢复性！**

