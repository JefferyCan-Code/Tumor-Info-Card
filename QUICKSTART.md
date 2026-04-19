# 快速参考卡 (Quick Start Card)

## 🚀 30秒快速启动

### 1. 安装依赖
```bash
pip install flask flask-cors cx-Oracle waitress
```

### 2. 配置数据库
编辑 `server.py` 第45-50行：
```python
DB_CONFIG = {
    "user": "your_username",
    "password": "your_password",
    "dsn": cx_Oracle.makedsn("your_db_ip", "1521", service_name="orcl")
}
```

### 3. 运行应用
```bash
python server.py
```

### 4. 打开浏览器
访问 `http://localhost:5000`，输入住院号查询

---

## 📋 常用SQL命令

### 查询患者信息
```sql
SELECT * FROM zy_wpypmx WHERE ZHUYUANHAO = '001';
```

### 查询化疗用药
```sql
SELECT YIZHUMC, YIZHUMS FROM zy_wpypmx 
WHERE ZHUYUANHAO = '001' AND 化学治疗 = 1;
```

### 统计治疗类型
```sql
SELECT COUNT(DISTINCT 化学治疗 + 分子靶向治疗 + 免疫治疗) FROM zy_wpypmx;
```

---

## 🔧 常见代码修改

### 更改服务器端口
在 `server.py` 最后一行：
```python
serve(app, host="0.0.0.0", port=8080)  # 改为8080
```

### 更改医院名称
在 `static/index.html` CSS中：
```css
.card::after {
    content: "你的医院名称";
}
```

### 添加新的治疗类型
在SQL中添加新字段，在Python中更新CASE语句：
```python
CASE
    WHEN 新治疗类型=1 THEN '新药物类'
    ELSE '其他'
END
```

---

## ⚠️ 故障排除

| 问题 | 解决方案 |
|------|--------|
| 数据库连接失败 | 检查IP、端口、用户名、密码 |
| 页面显示"未找到"患者 | 验证住院号是否存在，检查数据库权限 |
| 加载缓慢 | 增加连接池大小：`min=5, max=10` |
| 样式错乱 | 清除浏览器缓存：Ctrl+Shift+Delete |

---

## 📊 系统架构图

```
患者端访问
    ↓
Web浏览器 (HTML/CSS/JS)
    ↓ HTTP请求 /api/treatment/<hospital_no>
Flask服务器 (Python)
    ↓ SQL查询
Oracle数据库
    ↓ 返回患者信息
Flask服务器处理
    ↓ JSON格式
Web浏览器渲染显示
```

---

## 📞 联系方式与支持

- **文档**：查看 README.md
- **问题**：检查 app.log 日志文件
- **修改**：参考 README.md 中的"代码修改指南"

Generated with ❤️ using DeepSeekR1 670B
