# 肿瘤信息卡片系统 - 用户指南

## 📋 目录
1. [系统概述](#系统概述)
2. [快速开始](#快速开始)
3. [环境配置](#环境配置)
4. [数据库设置](#数据库设置)
5. [运行系统](#运行系统)
6. [API接口文档](#api接口文档)
7. [使用示例](#使用示例)
8. [SQL语句参考](#sql语句参考)
9. [代码修改指南](#代码修改指南)
10. [FAQ与故障排除](#faq与故障排除)

---

## 系统概述

### 项目目标
肿瘤信息卡片系统是一个为肿瘤内科医疗编码员设计的Web应用程序。通过将患者的治疗数据以数据框视图格式呈现，帮助编码员准确识别和编码患者的肿瘤治疗信息。

### 系统功能
- 🔍 **查询患者信息**：根据住院号查询患者基本信息和治疗情况
- 💊 **治疗展示**：清晰展示五类治疗方式的运用情况：
  - 化学治疗（化疗药）
  - 分子靶向治疗（靶向药）
  - 免疫治疗（免疫药）
  - 内分泌治疗（激素类药）
  - 其他治疗
- 📋 **医嘱详情**：展示详细的医嘱用药清单，包括：
  - 药物名称和规格
  - 用量和用法
  - 药物来源（自费/外配）
  - 用药日期

### 技术栈
| 组件 | 技术 |
|------|------|
| 后端 | Python Flask |
| 数据库 | Oracle |
| 前端 | HTML5 + CSS3 + JavaScript |
| 服务器 | Waitress WSGI |
| 数据库接口 | cx_Oracle |

### 系统架构
```
┌─────────────────────────────────────────────────┐
│               Web浏览器 (前端)                    │
│          HTML/CSS/JavaScript UI界面              │
└──────────────────┬──────────────────────────────┘
                   │ HTTP/REST
                   ↓
┌─────────────────────────────────────────────────┐
│          Flask应用服务器 (后端)                   │
│  ├─ 路由处理 (/api/treatment/<hospital_no>)     │
│  ├─ 数据处理和转换                               │
│  └─ 日志记录和错误处理                           │
└──────────────────┬──────────────────────────────┘
                   │ SQL查询
                   ↓
┌─────────────────────────────────────────────────┐
│          Oracle数据库服务器                      │
│  ├─ zy_wpypmx 表 (患者用药信息)                  │
│  └─ 其他医院信息系统表                          │
└─────────────────────────────────────────────────┘
```

---

## 快速开始

### 系统要求
- **操作系统**：Windows / Linux / macOS
- **Python**：3.7 或更新版本
- **Oracle数据库**：11g 或更新版本
- **网络访问**：可访问Oracle数据库服务器

### 最小化安装步骤

#### 1️⃣ 安装Python依赖
```bash
pip install flask flask-cors cx-Oracle waitress
```

#### 2️⃣ 配置数据库连接
编辑 `server.py` 第45-49行，修改数据库连接参数：
```python
DB_CONFIG = {
    "user": "你的用户名",           # Oracle用户名
    "password": "你的密码",         # Oracle密码
    "dsn": cx_Oracle.makedsn("数据库服务器IP", "1521", service_name="orcl")
}
```

#### 3️⃣ 运行应用
```bash
python server.py
```
应用将在 `http://localhost:5000` 启动

#### 4️⃣ 访问系统
在浏览器中输入：`http://localhost:5000`，然后输入住院号查询

---

## 环境配置

### 详细安装步骤

#### A. Python环境准备

**Windows用户：**
```bash
# 1. 创建虚拟环境（推荐）
python -m venv venv

# 2. 激活虚拟环境
venv\Scripts\activate

# 3. 升级pip
python -m pip install --upgrade pip

# 4. 安装依赖包
pip install -r requirements.txt
```

**Linux/macOS用户：**
```bash
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

#### B. 需要的Python包
创建 `requirements.txt` 文件：
```
Flask==2.3.0
Flask-CORS==4.0.0
cx-Oracle==8.3.0
waitress==2.1.2
```

#### C. Oracle客户端配置

**Windows：**
1. 下载Oracle Client（与数据库版本匹配）
2. 安装Oracle Client
3. 配置 `tnsnames.ora` 文件（通常在 `ORACLE_HOME\network\admin\`）：
```
ORCL =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.120.110)(PORT = 1521))
    (CONNECT_DATA =
      (SERVICE_NAME = orcl)
    )
  )
```

**Linux：**
```bash
# 安装Oracle Instant Client
apt-get install oracle-instantclient-basic
apt-get install oracle-instantclient-devel

# 设置环境变量
export LD_LIBRARY_PATH=/usr/lib/oracle/12.2/client64/lib:$LD_LIBRARY_PATH
```

---

## 数据库设置

### 数据库连接配置

#### 1. 连接参数说明

[server.py](server.py#L45-L50) 中的数据库配置：

```python
DB_CONFIG = {
    "user": "你的用户名",              # 数据库用户名
    "password": "你的密码",            # 数据库密码（请勿使用默认值）
    "dsn": cx_Oracle.makedsn(          # 生成DSN字符串
        "192.168.120.110",             # 数据库服务器IP
        "1521",                        # 数据库端口
        service_name="orcl"            # 服务名
    )
}
```

#### 2. 连接池配置

[server.py](server.py#L51-L58) 中使用了Session Pool连接池机制：
```python
pool = cx_Oracle.SessionPool(
    user=DB_CONFIG['user'],
    password=DB_CONFIG['password'],
    dsn=DB_CONFIG['dsn'],
    min=2,              # 最小连接数
    max=5,              # 最大连接数
    increment=1,        # 每次增加连接数
    threaded=True       # 线程安全
)
```

#### 3. 必需的数据库表

系统需要以下表及字段：

##### 表名：zy_wpypmx（患者用药信息表）

| 字段名 | 数据类型 | 说明 |
|--------|---------|------|
| ZHUYUANHAO | VARCHAR2(20) | **主键** - 住院号 |
| BINGRENXM | VARCHAR2(100) | 患者名称 |
| 化学治疗 | NUMBER(1,0) | 是否进行化学治疗（0/1） |
| 分子靶向治疗 | NUMBER(1,0) | 是否进行靶向治疗（0/1） |
| 免疫治疗 | NUMBER(1,0) | 是否进行免疫治疗（0/1） |
| 内分泌治疗 | NUMBER(1,0) | 是否进行内分泌治疗（0/1） |
| 其他治疗 | NUMBER(1,0) | 是否进行其他治疗（0/1） |
| YIZHUMC | VARCHAR2(200) | 医嘱名称（药物名称） |
| YIZHUMS | VARCHAR2(100) | 医嘱规格（药物规格） |
| SHULIANG | NUMBER(10,2) | 数量 |
| JIESUANJE | NUMBER(1,0) | 结算类别（NULL=自费, 0=外配）|
| FYFS | VARCHAR2(50) | 费用方式 |
| FASHENGRQ | DATE | 发生日期 |

#### 4. 创建测试数据

如需测试系统，可运行以下SQL创建示例数据：

```sql
-- 创建患者用药信息表
CREATE TABLE zy_wpypmx (
    ZHUYUANHAO VARCHAR2(20) NOT NULL,
    BINGRENXM VARCHAR2(100),
    YIZHUMC VARCHAR2(200),
    YIZHUMS VARCHAR2(100),
    SHULIANG NUMBER(10,2),
    JIESUANJE NUMBER(1,0),
    FYFS VARCHAR2(50),
    FASHENGRQ DATE,
    化学治疗 NUMBER(1,0) DEFAULT 0,
    分子靶向治疗 NUMBER(1,0) DEFAULT 0,
    免疫治疗 NUMBER(1,0) DEFAULT 0,
    内分泌治疗 NUMBER(1,0) DEFAULT 0,
    其他治疗 NUMBER(1,0) DEFAULT 0,
    PRIMARY KEY (ZHUYUANHAO)
);

-- 插入测试数据
INSERT INTO zy_wpypmx VALUES (
    '001' ,                        -- 住院号
    '张三',                        -- 患者名称
    '顺铂注射液',                  -- 医嘱名称
    '10ml*0.5mg',                  -- 规格
    2,                             -- 数量
    0,                             -- 结算类别
    '普通费用',                    -- 费用方式
    SYSDATE,                       -- 发生日期
    1,                             -- 化学治疗
    0,                             -- 靶向治疗
    1,                             -- 免疫治疗
    0,                             -- 内分泌治疗
    0                              -- 其他治疗
);
COMMIT;
```

---

## 运行系统

### 启动方式

#### 方式1：直接Python运行（开发模式）
```bash
# 确保已激活虚拟环境
python server.py
```
访问：`http://localhost:5000`

#### 方式2：使用批处理文件（Windows）
双击 `启动肿瘤信息卡服务.bat` 文件，自动启动Flask服务

#### 方式3：生产环境部署
```bash
# 使用Gunicorn + Nginx
pip install gunicorn
gunicorn -w 4 -b 0.0.0.0:5000 server:app
```

### 系统访问

1. **打开浏览器**，访问系统地址
2. **输入住院号**，例如："001"
3. **点击查询**或按Enter键
4. **系统显示**患者信息和治疗详情

### 日志管理

系统自动生成日志文件 `app.log`，包含：
- 每次API请求的详细记录
- 数据库操作日志
- 错误和异常信息

**日志位置**：`./app.log`

**日志保留期限**：自动保留60天的日志文件

---

## API接口文档

### 主接口：获取患者治疗信息

#### 请求
```http
GET /api/treatment/<hospital_no>
```

#### 参数
| 参数名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| hospital_no | String | 住院号（路径参数） | 001 |

#### 成功响应 (200)
```json
{
  "hospitalNo": "001",
  "patientName": "张三",
  "treatments": {
    "chemotherapy": true,         // 化学治疗
    "targeted": false,            // 靶向治疗
    "immunotherapy": true,        // 免疫治疗
    "endocrine": false,           // 内分泌治疗
    "other": false                // 其他治疗
  },
  "orders": [
    {
      "DRUGTYPE": "化疗药",
      "YIZHUMC": "顺铂注射液",
      "YIZHUMS": "10ml*0.5mg",
      "SHULIANG": 2,
      "JIESUANJE": 0,
      "FYFS": "普通费用",
      "FASHENGRQ": "2026-04-19 10:30:00",
      "ISWP": "外配"
    }
  ]
}
```

#### 错误响应 (404)
```json
{
  "error": "未找到患者信息"
}
```

#### 错误响应 (500)
```json
{
  "error": "服务器内部错误"
}
```

#### curl示例
```bash
curl -X GET "http://localhost:5000/api/treatment/001"
```

#### JavaScript示例
```javascript
// 查询患者信息
async function searchTreatment(hospitalNo) {
  try {
    const response = await fetch(`/api/treatment/${hospitalNo}`);
    const data = await response.json();
    
    if (response.ok) {
      console.log('患者信息:', data);
      displayPatientInfo(data);
    } else {
      console.error('查询失败:', data.error);
    }
  } catch (error) {
    console.error('网络错误:', error);
  }
}
```

---

## 使用示例

### 场景1：查询患者治疗情况

**步骤：**
1. 打开系统主页
2. 在搜索框输入住院号（如："001"）
3. 按回车或点击查询按钮
4. 系统显示患者的治疗信息卡片

**预期结果：**
- 显示患者基本信息（姓名、住院号）
- 显示五类治疗方式的运用情况
- 以表格形式展示所有医嘱用药详情

### 场景2：医疗编码人员规范编码

**编码流程：**
1. 操作人员访问系统
2. 输入患者住院号查询
3. 根据呈现的治疗信息卡片准确填写编码：
   - 根据"化学治疗"标记，编码化疗相关项
   - 根据"靶向治疗"标记，编码靶向治疗项
   - 根据"免疫治疗"标记，编码免疫治疗项
   - 根据医嘱详情，编码具体的医学程序代码
4. 完成编码并提交

### 场景3：查询医嘱用药详情

系统自动显示所有用药信息，包括：
- 药物类型和名称
- 药物规格和数量
- 费用来源（自费/外配）
- 用药日期

---

## SQL语句参考

### 系统使用的核心SQL语句

#### 1. 获取患者基本信息和治疗类型统计

[server.py](server.py#L90-L100)中第一条SQL：
```sql
SELECT BINGRENXM,
       SUM(化学治疗) AS 化学治疗,
       SUM(分子靶向治疗) AS 分子靶向治疗,
       SUM(免疫治疗) AS 免疫治疗,
       SUM(内分泌治疗) AS 内分泌治疗,
       SUM(其他治疗) AS 其他治疗
FROM zy_wpypmx
WHERE ZHUYUANHAO = :1
GROUP BY ZHUYUANHAO, BINGRENXM
```

**说明：**
- 根据住院号查询患者名称
- 统计各类治疗是否进行（任何值>0即表示进行该治疗）
- 使用`:1`作为绑定参数来防止SQL注入
- GROUP BY 确保返回单行结果

#### 2. 获取医嘱用药详情

[server.py](server.py#L108-L128)中第二条SQL：
```sql
SELECT
    CASE
        WHEN 化学治疗=1 THEN '化疗药'
        WHEN 分子靶向治疗=1 THEN '靶向药'
        WHEN 免疫治疗=1 THEN '免疫药'
        WHEN 内分泌治疗=1 THEN '内分泌药'
        ELSE '其他类'
    END AS DRUGTYPE,
    YIZHUMC,
    YIZHUMS,
    SHULIANG,
    JIESUANJE,
    FYFS,
    TO_CHAR(FASHENGRQ, 'YYYY-MM-DD HH24:MI:SS') AS FASHENGRQ,
    CASE
        WHEN JIESUANJE=0 THEN '外配'
        WHEN JIESUANJE IS NULL THEN '自费'
        ELSE ''
    END AS ISWP
FROM JCJK.zy_wpypmx
WHERE ZHUYUANHAO = :1
```

**说明：**
- 使用CASE语句将治疗标记转换为易读的药物类型
- 使用TO_CHAR格式化日期字符串
- ISWP字段标记医保状态（外配/自费）

### 常用查询示例

#### 查询某患者的所有化疗用药
```sql
SELECT YIZHUMC, YIZHUMS, SHULIANG, FASHENGRQ
FROM zy_wpypmx
WHERE ZHUYUANHAO = '001'
  AND 化学治疗 = 1
ORDER BY FASHENGRQ DESC;
```

#### 统计患者使用的治疗类型数量
```sql
SELECT 
    CASE WHEN 化学治疗=1 THEN 1 ELSE 0 END +
    CASE WHEN 分子靶向治疗=1 THEN 1 ELSE 0 END +
    CASE WHEN 免疫治疗=1 THEN 1 ELSE 0 END +
    CASE WHEN 内分泌治疗=1 THEN 1 ELSE 0 END AS 治疗类型数
FROM zy_wpypmx
WHERE ZHUYUANHAO = '001';
```

#### 查询特定日期范围内的用药
```sql
SELECT YIZHUMC, SHULIANG, FASHENGRQ
FROM zy_wpypmx
WHERE ZHUYUANHAO = '001'
  AND FASHENGRQ BETWEEN TO_DATE('2026-01-01', 'YYYY-MM-DD') 
                    AND TO_DATE('2026-12-31', 'YYYY-MM-DD')
ORDER BY FASHENGRQ;
```

#### 查询自费和外配药物
```sql
SELECT 
    CASE WHEN JIESUANJE IS NULL THEN '自费'
         WHEN JIESUANJE=0 THEN '外配'
         ELSE '其他' END AS 费用类别,
    YIZHUMC,
    COUNT(*) AS 药物数量
FROM zy_wpypmx
WHERE ZHUYUANHAO = '001'
GROUP BY JIESUANJE, YIZHUMC;
```

---

## 代码修改指南

### 修改1：更改数据库连接信息

**修改位置**：[server.py](server.py#L45-L50)

**原始代码**：
```python
DB_CONFIG = {
    "user": "原始用户名",
    "password": "原始密码",
    "dsn": cx_Oracle.makedsn("192.168.120.110", "1521", service_name="orcl")
}
```

**修改步骤**：
1. 将 `"user"` 改为你的Oracle用户名
2. 将 `"password"` 改为你的Oracle密码
3. 将IP地址（"192.168.120.110"）改为你的数据库服务器IP
4. 根据实际情况修改服务名（默认为"orcl"）

**示例**：
```python
DB_CONFIG = {
    "user": "medical_user",
    "password": "MySecurePassword123",
    "dsn": cx_Oracle.makedsn("10.0.0.5", "1521", service_name="prod_db")
}
```

### 修改2：更改表名和字段名

**场景**：如果数据库表结构不同，需要修改SQL语句

**修改位置1**：[server.py](server.py#L93-L100) - 患者信息查询
```python
# 修改前
cursor.execute("""
    SELECT BINGRENXM,
           SUM(化学治疗) AS 化学治疗,
           ...
    FROM zy_wpypmx
    WHERE ZHUYUANHAO = :1
    GROUP BY ZHUYUANHAO, BINGRENXM"""

# 修改后（假设表名改为patient_treatment_info）
cursor.execute("""
    SELECT patient_name,
           SUM(chemo) AS chemo,
           ...
    FROM patient_treatment_info
    WHERE admission_no = :1
    GROUP BY admission_no, patient_name"""
```

**修改位置2**：[server.py](server.py#L108-L125) - 医嘱详情查询
```python
# 修改前
cursor.execute("""
    SELECT YIZHUMC, YIZHUMS, SHULIANG, ...
    FROM JCJK.zy_wpypmx
    
# 修改后
cursor.execute("""
    SELECT drug_name, drug_spec, quantity, ...
    FROM your_schema.your_table_name
```

### 修改3：添加新的治疗类型

**场景**：需要添加第6种治疗类型（如"中医治疗"）

**修改步骤**：

1. **修改SQL查询** [server.py](server.py#L97-L99)：
```python
# 原始查询
SUM(化学治疗) AS 化学治疗,
SUM(分子靶向治疗) AS 分子靶向治疗,
...

# 添加新字段
SUM(中医治疗) AS 中医治疗,
```

2. **修改Python数据处理** [server.py](server.py#L109-L114)：
```python
# 原始数据结构
data = {
    ...
    "treatments": {
        "chemotherapy": bool(row[1]),
        "targeted": bool(row[2]),
        ...
    }

# 添加新字段
"treatments": {
    "chemotherapy": bool(row[1]),
    "targeted": bool(row[2]),
    ...
    "chinese_medicine": bool(row[6])  # 新增
}
```

3. **修改医嘱类型判断** [server.py](server.py#L120-L126)：
```python
# 在CASE语句中添加
CASE
    WHEN 化学治疗=1 THEN '化疗药'
    ...
    WHEN 中医治疗=1 THEN '中医药'  # 新增
    ELSE '其他类'
END AS DRUGTYPE
```

### 修改4：更改前端样式和颜色

**修改位置**：[static/index.html](static/index.html#L24-L30) 中的CSS变量

```css
:root {
    --chemotherapy: #e8f5e9;        /* 化疗：绿色 */
    --targeted: #fff3e0;            /* 靶向：橙色 */
    --immunotherapy: #e3f2fd;       /* 免疫：蓝色 */
    --endocrine: #fce4ec;           /* 内分泌：粉色 */
    --other: #f5f5f5;               /* 其他：灰色 */
    --false-bg: #f5f5f5;            /* 未进行：浅灰 */
}
```

**修改示例**：将化疗颜色改为红色
```css
--chemotherapy: #ffebee;  /* 浅红色 */
```

### 修改5：更改页面标题和医院名称

**修改位置1**：[static/index.html](static/index.html#L4) - 网页标题
```html
<!-- 原始 -->
<title>住院号：</title>

<!-- 修改为 -->
<title>肿瘤治疗信息卡片系统</title>
```

**修改位置2**：[static/index.html](static/index.html#L33) - 医院水印名称
```css
.card::after {
    content: "宁波大学附属第一医院";  /* 修改为你的医院名称 */
    ...
}
```

### 修改6：调整日志保留时间

**修改位置**：[server.py](server.py#L27-L30)

```python
# 原始：保留60天
file_handler = TimedRotatingFileHandler(
    'app.log',
    when='midnight',
    interval=1,
    backupCount=60,  # 修改此数字
    encoding='utf-8'
)

# 修改为保留30天
backupCount=30

# 修改为保留180天
backupCount=180
```

### 修改7：添加新的API端点（高级）

**场景**：需要添加新的查询功能，如按患者名称查询

```python
# 在server.py中添加新的路由处理器
@app.route('/api/patient/<string:patient_name>')
def get_patient_by_name(patient_name):
    """按患者名称查询"""
    conn = pool.acquire()
    cursor = conn.cursor()
    try:
        cursor.execute("""
            SELECT DISTINCT ZHUYUANHAO, BINGRENXM
            FROM zy_wpypmx
            WHERE BINGRENXM LIKE :1
        """, ['%' + patient_name + '%'])
        
        results = [{
            "hospitalNo": row[0],
            "patientName": row[1]
        } for row in cursor]
        
        return jsonify(results) if results else (jsonify({"error": "未找到患者"}), 404)
    finally:
        cursor.close()
        pool.release(conn)
```

然后在JavaScript中调用：
```javascript
async function searchByName(patientName) {
    const response = await fetch(`/api/patient/${patientName}`);
    const data = await response.json();
    console.log(data);
}
```

---

## FAQ与故障排除

### Q1: 无法连接到数据库，报错"ORA-12514"

**原因**：服务名或数据库服务未启动

**解决方案**：
```bash
# 1. 检查数据库是否在线
sqlplus 用户名/密码@192.168.120.110:1521/orcl

# 2. 检查服务名是否正确
# 3. 重启Oracle监听服务
lsnrctl start  # Linux/Unix
# 或在Windows服务中重启 OracleOraDb11g_home1TNSListener
```

### Q2: 导入cx_Oracle时报错

**原因**：未安装Oracle客户端或环境变量未配置

**解决方案**：
```bash
# Windows
# 下载并安装 Oracle Instant Client
# 设置环境变量 ORACLE_HOME

# Linux
export LD_LIBRARY_PATH=/usr/lib/oracle/12.2/client64/lib:$LD_LIBRARY_PATH
pip install cx-Oracle
```

### Q3: 系统加载缓慢

**原因**：
- 数据库查询时间过长
- 网络延迟
- Python GIL限制

**解决方案**：
```python
# 在server.py中增加数据库连接池
pool = cx_Oracle.SessionPool(
    ...
    min=5,      # 从2增加到5
    max=10,     # 从5增加到10
    ...
)
```

### Q4: 显示"未找到患者信息"

**原因**：
- 住院号输入错误
- 患者不在数据库中
- 数据库权限不足

**解决方案**：
```bash
# 1. 验证住院号是否存在
sqlplus> SELECT DISTINCT ZHUYUANHAO FROM zy_wpypmx;

# 2. 检查用户权限
sqlplus> SELECT * FROM user_tables WHERE table_name='ZY_WPYPMX';
```

### Q5: 日志文件过大

**原因**：日志记录过于详细

**解决方案**：
```python
# 在server.py中修改日志级别
console_handler.setLevel(logging.WARNING)  # 只记录警告以上
file_handler.setLevel(logging.WARNING)
```

### Q6: 前端页面样式错乱

**原因**：
- 浏览器缓存
- CSS文件未正确加载

**解决方案**：
```javascript
// 清除浏览器缓存
// 按 Ctrl+Shift+Delete 打开清除浏览历史记录对话框
// 或在开发者工具中禁用缓存：
// F12 → 设置 → 禁用缓存
```

### Q7: 如何修改服务器端口

**修改位置**：[server.py](server.py#L199)

```python
# 原始：5000端口
serve(app, host="0.0.0.0", port=5000)

# 修改为8080端口
serve(app, host="0.0.0.0", port=8080)
```

然后访问：`http://localhost:8080`

### Q8: 如何在生产环境部署

**使用Gunicorn + Nginx：**

```bash
# 1. 安装Gunicorn
pip install gunicorn

# 2. 启动Gunicorn服务
gunicorn -w 4 -b 127.0.0.1:5000 server:app

# 3. 配置Nginx反向代理
# /etc/nginx/sites-available/default
server {
    listen 80;
    server_name your_domain.com;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

# 4. 重启Nginx
sudo systemctl restart nginx
```

---

## 技术支持资源

- **Python Flask官方文档**：https://flask.palletsprojects.com/
- **cx_Oracle文档**：https://cx-oracle.readthedocs.io/
- **Oracle SQL参考**：https://docs.oracle.com/

## 版本信息

- **系统版本**：1.0
- **生成日期**：2026年4月19日
- **基础框架**：DeepSeekR1 670B
- **最后更新**：2026年4月19日

## 许可证

本项目仅供医疗教学和实际应用使用。

---

**如有任何问题，请检查日志文件 `app.log` 或参考FAQ部分。**
