# 贡献指南 (Contributing Guide)

## 😊 欢迎贡献

感谢你对肿瘤信息卡片系统的兴趣！本指南将帮助你理解如何修改和扩展此项目。

---

## 📚 代码结构速览

```
├── server.py                    # Flask后端应用（主程序）
├── static/
│   └── index.html              # 前端Web界面
├── app.log                      # 应用日志文件（自动生成）
├── README.md                    # 完整用户指南
├── QUICKSTART.md               # 快速启动指南
├── requirements.txt            # Python依赖列表
└── 启动肿瘤信息卡服务.bat      # Windows启动脚本
```

---

## 🛠️ 开发环境设置

### 1. 克隆或下载项目
```bash
git clone https://github.com/your-username/tumor-info-card.git
cd tumor-info-card
```

### 2. 创建虚拟环境
```bash
# Windows
python -m venv venv
venv\Scripts\activate

# Linux/macOS
python3 -m venv venv
source venv/bin/activate
```

### 3. 安装依赖
```bash
pip install -r requirements.txt
```

### 4. 本地测试
```bash
python server.py
```

访问 `http://localhost:5000` 验证

---

## 🔄 修改类型与指南

### 类型A：配置修改（推荐初学者）

#### A1. 修改数据库连接信息

**文件位置**：[server.py](server.py#L45-L50)

**修改前**：
```python
DB_CONFIG = {
    "user": "****", #oracle用户名
    "password": "****", #oracle密码
    "dsn": cx_Oracle.makedsn("数据库服务器IP", "1521", service_name="orcl")
}
```

**修改后**：
```python
DB_CONFIG = {
    "user": "你的用户名",
    "password": "你的密码",
    "dsn": cx_Oracle.makedsn("你的IP地址", "1521", service_name="你的服务名")
}
```

**验证方法**：
```python
# 在server.py中临时添加测试代码
try:
    conn = pool.acquire()
    cursor = conn.cursor()
    cursor.execute("SELECT 1 FROM dual")
    print("✓ 数据库连接成功")
    cursor.close()
    pool.release(conn)
except Exception as e:
    print(f"✗ 连接失败: {e}")
```

#### A2. 修改日志级别

**文件位置**：[server.py](server.py#L17-L42)

```python
# 更改为DEBUG级别（记录更详细信息）
console_handler.setLevel(logging.DEBUG)
file_handler.setLevel(logging.DEBUG)
app.logger.setLevel(logging.DEBUG)
```

### 类型B：数据库模式修改（中级）

#### B1. 更改表名和字段名

**场景**：你的数据库表结构不同

**修改步骤**：

1. **找到第一条SQL语句** [server.py](server.py#L93-L100)

**原始**：
```sql
FROM zy_wpypmx
WHERE ZHUYUANHAO = :1
GROUP BY ZHUYUANHAO, BINGRENXM
```

**修改为**（如表名改为patient_treatments）：
```sql
FROM patient_treatments
WHERE admission_number = :1
GROUP BY admission_number, patient_name
```

2. **更新Python字段映射** [server.py](server.py#L104-L114)

**原始**：
```python
data = {
    "hospitalNo": hospital_no,
    "patientName": row[0],
    "treatments": {
        "chemotherapy": bool(row[1]),
        "targeted": bool(row[2]),
```

**修改为**：
```python
data = {
    "hospitalNo": hospital_no,
    "patientName": row[0],  # 确保与SQL SELECT顺序匹配
    "treatments": {
        "chemotherapy": bool(row[1]),
        "targeted": bool(row[2]),
```

#### B2. 添加新的治疗类型

**目标**：系统中原有5种治疗类型，现在要添加第6种"放疗"

**步骤**：

1. **修改SQL查询** [server.py](server.py#L93-L100)

```python
# 原始
SUM(化学治疗) AS 化学治疗,
SUM(分子靶向治疗) AS 分子靶向治疗,
...
SUM(其他治疗) AS 其他治疗

# 修改为（添加放疗）
SUM(化学治疗) AS 化学治疗,
SUM(分子靶向治疗) AS 分子靶向治疗,
...
SUM(其他治疗) AS 其他治疗,
SUM(放疗) AS 放疗
```

2. **更新Python数据结构** [server.py](server.py#L108-114]

```python
# 原始
"treatments": {
    "chemotherapy": bool(row[1]),
    "targeted": bool(row[2]),
    "immunotherapy": bool(row[3]),
    "endocrine": bool(row[4]),
    "other": bool(row[5])
}

# 修改为
"treatments": {
    "chemotherapy": bool(row[1]),
    "targeted": bool(row[2]),
    "immunotherapy": bool(row[3]),
    "endocrine": bool(row[4]),
    "other": bool(row[5]),
    "radiotherapy": bool(row[6])  # 新增
}
```

3. **修改医嘱类型判断** [server.py](server.py#L120-L126)

```python
# 原始CASE语句
CASE
    WHEN 化学治疗=1 THEN '化疗药'
    WHEN 分子靶向治疗=1 THEN '靶向药'
    WHEN 免疫治疗=1 THEN '免疫药'
    WHEN 内分泌治疗=1 THEN '内分泌药'
    ELSE '其他类'
END

# 修改为
CASE
    WHEN 化学治疗=1 THEN '化疗药'
    WHEN 分子靶向治疗=1 THEN '靶向药'
    WHEN 免疫治疗=1 THEN '免疫药'
    WHEN 内分泌治疗=1 THEN '内分泌药'
    WHEN 放疗=1 THEN '放疗'        # 新增
    ELSE '其他类'
END
```

4. **修改前端HTML** [static/index.html](static/index.html)

找到治疗状态显示部分，添加新的治疗类型框：
```html
<!-- 原始 -->
<div class="status-item true" data-treatment-type="immunotherapy">
    <span>免疫治疗</span>
</div>

<!-- 添加新的 -->
<div class="status-item true" data-treatment-type="radiotherapy">
    <span>放疗</span>
</div>
```

5. **修改CSS样式** [static/index.html](static/index.html#L24-L30)

```css
:root {
    --chemotherapy: #e8f5e9;
    --targeted: #fff3e0;
    --immunotherapy: #e3f2fd;
    --endocrine: #fce4ec;
    --other: #f5f5f5;
    --radiotherapy: #ffe0b2;  /* 新增：放疗使用橙灰色 */
}
```

### 类型C：API功能扩展（高级）

#### C1. 添加新的API端点：按患者名称查询

**目标**：增加 `/api/patient/<name>` 端点，支持按患者名称模糊查询

**修改步骤**：

1. **在 server.py 中添加新函数** [server.py](server.py#L140)后添加：

```python
@app.route('/api/patient/<string:patient_name>')
def search_patient_by_name(patient_name):
    """
    按患者名称查询
    
    参数:
        patient_name (str): 患者名称（支持模糊查询）
    
    返回:
        JSON: 匹配的患者列表 [{"hospitalNo": "001", "patientName": "张三"}]
    """
    conn = pool.acquire()
    cursor = conn.cursor()
    try:
        # 使用LIKE进行模糊查询，%用作通配符
        cursor.execute("""
            SELECT DISTINCT ZHUYUANHAO, BINGRENXM
            FROM zy_wpypmx
            WHERE BINGRENXM LIKE :1
            ORDER BY BINGRENXM
        """, ['%' + patient_name + '%'])
        
        results = [{
            "hospitalNo": row[0],
            "patientName": row[1]
        } for row in cursor.fetchall()]
        
        if results:
            return jsonify(results)
        else:
            return jsonify({"error": f"未找到名字包含'{patient_name}'的患者"}), 404
            
    except cx_Oracle.DatabaseError as e:
        error, = e.args
        app.logger.error(f"数据库错误[{error.code}]: {error.message}")
        return jsonify({"error": "数据库查询失败"}), 500
    finally:
        cursor.close()
        pool.release(conn)
```

2. **在前端添加搜索功能** [static/index.html](static/index.html)

在搜索框后添加搜索类型选择：
```html
<select id="searchType">
    <option value="hospital">按住院号</option>
    <option value="name">按患者名称</option>
</select>
```

3. **修改JavaScript搜索逻辑** [static/index.html](static/index.html)

```javascript
async function handleSearch(event) {
    if (event.key !== 'Enter') return;
    
    const searchValue = document.getElementById('hospitalNoInput').value.trim();
    const searchType = document.getElementById('searchType').value;
    
    let url;
    if (searchType === 'hospital') {
        url = `/api/treatment/${searchValue}`;
    } else if (searchType === 'name') {
        url = `/api/patient/${searchValue}`;
    }
    
    try {
        const response = await fetch(url);
        const data = await response.json();
        displayResults(data);
    } catch (error) {
        console.error('查询错误:', error);
    }
}
```

#### C2. 添加日期范围查询端点

**目标**：新增 `/api/treatment/<hospital_no>/range?start=YYYY-MM-DD&end=YYYY-MM-DD` 端点

```python
@app.route('/api/treatment/<string:hospital_no>/range')
def get_treatment_range(hospital_no):
    """
    按日期范围查询患者用药信息
    
    查询参数:
        start: 开始日期 (YYYY-MM-DD)
        end: 结束日期 (YYYY-MM-DD)
    
    示例:
        GET /api/treatment/001/range?start=2026-01-01&end=2026-12-31
    """
    start_date = request.args.get('start', '')
    end_date = request.args.get('end', '')
    
    if not start_date or not end_date:
        return jsonify({"error": "缺少日期参数"}), 400
    
    conn = pool.acquire()
    cursor = conn.cursor()
    try:
        cursor.execute("""
            SELECT YIZHUMC, SHULIANG, TO_CHAR(FASHENGRQ, 'YYYY-MM-DD')
            FROM zy_wpypmx
            WHERE ZHUYUANHAO = :1
              AND FASHENGRQ BETWEEN TO_DATE(:2, 'YYYY-MM-DD') 
                                AND TO_DATE(:3, 'YYYY-MM-DD')
            ORDER BY FASHENGRQ DESC
        """, [hospital_no, start_date, end_date])
        
        results = [{
            "drugName": row[0],
            "quantity": row[1],
            "date": row[2]
        } for row in cursor.fetchall()]
        
        return jsonify(results) if results else (jsonify({"error": "无数据"}), 404)
    finally:
        cursor.close()
        pool.release(conn)
```

### 类型D：前端UI级定制（设计师友好）

#### D1. 更改颜色主题

**文件位置**：[static/index.html](static/index.html#L24-L35)

```css
:root {
    /* 修改这些颜色变量来改变整个系统的主题 */
    --primary-color: #4A90E2;        /* 蓝色主色 */
    --chemotherapy: #e8f5e9;         /* 化疗：绿色 */
    --targeted: #fff3e0;             /* 靶向：橙色 */
    --immunotherapy: #e3f2fd;        /* 免疫：蓝色 */
    --endocrine: #fce4ec;            /* 内分泌：粉色 */
    --success-color: #2e7d32;        /* 成功：深绿 */
    --error-color: #c62828;          /* 错误：红色 */
}
```

#### D2. 修改页面标题和医院信息

**文件位置**：[static/index.html](static/index.html)

```html
<!-- 修改网页标题 -->
<title>肿瘤治疗信息卡片系统 - 你的医院名称</title>

<!-- 修改医院水印（在背景显示） -->
<style>
    .card::after {
        content: "你的医院名称";  /* 修改此处 */
    }
</style>

<!-- 修改页面内显示的医院名称 -->
<h1>你的医院名称 - 肿瘤治疗信息卡片系统</h1>
```

---

## 🧪 测试修改

### 本地测试流程

1. **启动开发服务器**
```bash
python server.py
```

2. **打开浏览器开发工具** (F12)
   - Network 标签：查看API请求和响应
   - Console 标签：查看JavaScript错误
   - Storage 标签：查看浏览器缓存

3. **测试数据库查询**
```bash
# 在另一个终端中直接测试API
curl http://localhost:5000/api/treatment/001
```

4. **查看日志输出**
```bash
# app.log 文件将记录所有请求和错误
tail -f app.log  # 实时查看日志
```

### 单元测试示例

创建 `test_api.py`：
```python
import unittest
import json
from server import app

class TestTumorCardAPI(unittest.TestCase):
    
    def setUp(self):
        self.app = app.test_client()
        self.app.testing = True
    
    def test_get_treatment_success(self):
        """测试成功查询"""
        response = self.app.get('/api/treatment/001')
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertIn('hospitalNo', data)
        self.assertIn('patientName', data)
        self.assertIn('treatments', data)
    
    def test_get_treatment_not_found(self):
        """测试患者不存在"""
        response = self.app.get('/api/treatment/999999')
        self.assertEqual(response.status_code, 404)
    
    def test_treatments_structure(self):
        """测试数据结构"""
        response = self.app.get('/api/treatment/001')
        data = json.loads(response.data)
        self.assertIsInstance(data['treatments'], dict)
        self.assertIn('chemotherapy', data['treatments'])
        self.assertIn('targeted', data['treatments'])

if __name__ == '__main__':
    unittest.main()
```

运行测试：
```bash
python -m unittest test_api.py
```

---

## 📋 代码审核检查清单

在提交修改前，请检查以下内容：

- [ ] 代码能否正常运行，没有语法错误
- [ ] 新增的功能已在本地测试过
- [ ] 不包含个人数据库连接信息（密码等）
- [ ] 代码注释清晰，易于他人理解
- [ ] 遵循Python PEP8代码规范
  ```bash
  pip install flake8
  flake8 server.py
  ```
- [ ] 没有引入新的安全漏洞（SQLi、XSS等）
- [ ] 更新了相关文档（README、注释等）
- [ ] 日志记录适度，不过度打印

---

## 🚀 提交修改

### 如果你在GitHub上fork了此项目

1. **创建你的修改分支**
```bash
git checkout -b feature/你的功能名
git add .
git commit -m "描述你的修改"
git push origin feature/你的功能名
```

2. **创建Pull Request**
   - 清晰描述你的修改内容
   - 说明为什么需要这个修改
   - 附上测试结果（截图等）

3. **等待审核**
   - 注意有没有拼写或逻辑错误的反馈
   - 根据反馈进行调整

### 如果你只是本地使用

直接修改 `server.py` 和 `static/index.html` 即可，无需提交。

---

## 📖 最佳实践

### 1. 安全性
- ✅ 使用参数化查询防止SQL注入 (已使用 `:1` 参数)
- ✅ 验证用户输入
- ✅ 不要在代码中硬编码密码（使用配置文件）
- ✅ 定期更新依赖包

### 2. 性能
- ✅ 使用数据库连接池（已实现）
- ✅ 为频繁查询的字段添加数据库索引
- ✅ 避免在循环中执行数据库查询
- ✅ 缓存不经常变化的数据

### 3. 可维护性
- ✅ 使用有意义的变量名
- ✅ 添加函数和类的文档字符串
- ✅ 模块化代码，避免一个函数过长
- ✅ 及时更新文档

### 4. 用户体验
- ✅ 提供清晰的错误提示
- ✅ 响应时间控制在1秒以内
- ✅ 页面加载时显示加载指示器
- ✅ 支持键盘快捷键（Enter搜索等）

---

## 🆘 需要帮助？

1. **查看日志** - `app.log` 文件包含详细的错误信息
2. **查看文档** - `README.md` 中有完整的API和配置说明
3. **快速参考** - `QUICKSTART.md` 有常见问题和解决方案

---

感谢你的贡献！🎉
