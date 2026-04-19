# server.py
from flask import Flask, jsonify, send_from_directory, request, g
import cx_Oracle
from flask_cors import CORS
import logging
from logging.handlers import TimedRotatingFileHandler
import time

app = Flask(__name__, static_folder='static')
CORS(app)

# 配置日志
if __name__ != '__main__':  # 防止重复日志
    gunicorn_logger = logging.getLogger('gunicorn.error')
    app.logger.handlers = gunicorn_logger.handlers
    app.logger.setLevel(gunicorn_logger.level)
else:
    # 移除所有默认处理器
    app.logger.handlers.clear()
    
    # 控制台处理器
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)

    # 文件处理器（保留60天）
    file_handler = TimedRotatingFileHandler(
        'app.log',
        when='midnight',
        interval=1,
        backupCount=60,
        encoding='utf-8'
    )
    file_handler.setLevel(logging.INFO)

    # 统一日志格式
    formatter = logging.Formatter(
        '%(asctime)s - %(levelname)s - %(message)s'
    )
    console_handler.setFormatter(formatter)
    file_handler.setFormatter(formatter)

    app.logger.addHandler(console_handler)
    app.logger.addHandler(file_handler)
    app.logger.setLevel(logging.INFO)

# 数据库配置
DB_CONFIG = {
    "user": "****", #oracle用户名
    "password": "****", #oracle密码
    "dsn": cx_Oracle.makedsn("数据库服务器IP", "1521", service_name="orcl")
}

pool = cx_Oracle.SessionPool(
    user=DB_CONFIG['user'],
    password=DB_CONFIG['password'],
    dsn=DB_CONFIG['dsn'],
    min=2,
    max=5,
    increment=1,
    threaded=True
)

@app.before_request
def record_start_time():
    """记录请求开始时间"""
    g.start_time = time.time()

@app.after_request
def log_request(response):
    """记录请求日志（优化版）"""
    # 过滤不需要记录的请求
    if request.path.startswith('/static/') or request.path == '/favicon.ico':
        return response

    # 过滤OPTIONS预检请求
    if request.method == 'OPTIONS':
        return response

    duration = time.time() - g.get('start_time', time.time())
    ip = request.headers.get('X-Forwarded-For', request.remote_addr)
    
    # 更精确的住院号提取
    hospital_no = 'N/A'
    if request.path.startswith('/api/treatment/'):
        hospital_no = request.view_args.get('hospital_no', 'N/A')

    # 构造精简日志
    app.logger.info(f"IP: {ip.split(',')[0].strip()}, 住院号: {hospital_no}, 耗时: {duration:.3f}s")
    return response

def get_treatment_data(hospital_no):
    conn = pool.acquire()
    cursor = conn.cursor()
    try:
        # 获取患者基本信息
        cursor.execute("""
            SELECT BINGRENXM,
                   SUM(化学治疗) AS 化学治疗,
                   SUM(分子靶向治疗) AS 分子靶向治疗,
                   SUM(免疫治疗) AS 免疫治疗,
                   SUM(内分泌治疗) AS 内分泌治疗,
                   SUM(其他治疗) AS 其他治疗
            FROM zy_wpypmx
            WHERE ZHUYUANHAO = :1
            GROUP BY ZHUYUANHAO, BINGRENXM""", [hospital_no])
        row = cursor.fetchone()
        if not row:
            return None

        data = {
            "hospitalNo": hospital_no,
            "patientName": row[0],
            "treatments": {
                "chemotherapy": bool(row[1]),
                "targeted": bool(row[2]),
                "immunotherapy": bool(row[3]),
                "endocrine": bool(row[4]),
                "other": bool(row[5])
            },
            "orders": []
        }

        # 获取医嘱信息（修正缩进的关键部分）
        cursor.execute("""
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
            WHERE ZHUYUANHAO = :1""", [hospital_no])

        # 正确缩进的数据处理部分
        data["orders"] = [{
            "DRUGTYPE": row[0],
            "YIZHUMC": row[1] or "",
            "YIZHUMS": row[2] or "",
            "SHULIANG": float(row[3]) if row[3] is not None else None,
            "JIESUANJE": float(row[4]) if row[4] is not None else None,
            "FYFS": row[5] or "",
            "FASHENGRQ":  row[6] or None,  # 修改点：日期空值用None
            "ISWP": row[7] or ""
        } for row in cursor]

        return data
    except cx_Oracle.DatabaseError as e:
        error, = e.args
        app.logger.error(f"数据库错误[{error.code}]: {error.message}")
        return {"error": "数据库查询失败"}
    finally:
        cursor.close()
        pool.release(conn)

@app.route('/')
def index():
    return send_from_directory('static', 'index.html')

@app.route('/<path:path>')
def catch_all(path):
    return send_from_directory('static', 'index.html')

@app.route('/api/treatment/<string:hospital_no>')
def get_treatment(hospital_no):
    data = get_treatment_data(hospital_no)
    return jsonify(data) if data else (jsonify({"error": "未找到患者信息"}), 404)

@app.errorhandler(Exception)
def handle_global_exception(e):
    """处理未捕获的全局异常"""
    hospital_no = 'N/A'
    if request.path.startswith('/api/treatment/'):
        hospital_no = request.path.split('/')[-1]
    
    app.logger.error(
        f"全局异常 - IP: {request.remote_addr}, "
        f"住院号: {hospital_no}, 错误: {str(e)}",
        exc_info=True
    )
    return jsonify({"error": "服务器内部错误"}), 500

if __name__ == '__main__':
    from waitress import serve
    serve(app, host="0.0.0.0", port=5000)
