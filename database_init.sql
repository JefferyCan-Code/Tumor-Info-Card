-- ============================================================================
-- 肿瘤信息卡片系统 - Oracle数据库初始化脚本
-- 创建患者用药信息表及示例数据
-- ============================================================================
-- 执行此脚本前，请确保：
-- 1. 已连接到对应的Oracle数据库
-- 2. 具有CREATE TABLE权限
-- 3. 备份现有数据库

-- ============================================================================
-- 第一步：创建表结构
-- ============================================================================

-- 如果表存在，先删除（谨慎！）
-- DROP TABLE zy_wpypmx;

-- 创建患者用药信息表
CREATE TABLE zy_wpypmx (
    ZHUYUANHAO VARCHAR2(20) NOT NULL,          -- 住院号（主键）
    BINGRENXM VARCHAR2(100),                   -- 患者名称
    YIZHUMC VARCHAR2(200),                     -- 医嘱名称（药物名称）
    YIZHUMS VARCHAR2(100),                     -- 医嘱规格（药物规格）
    SHULIANG NUMBER(10,2),                     -- 数量
    JIESUANJE NUMBER(1,0),                     -- 结算类别（NULL=自费, 0=外配, 1=医保）
    FYFS VARCHAR2(50),                         -- 费用方式（普通、高级等）
    FASHENGRQ DATE,                            -- 发生日期（用药日期）
    化学治疗 NUMBER(1,0) DEFAULT 0,             -- 是否为化学治疗（0=否, 1=是）
    分子靶向治疗 NUMBER(1,0) DEFAULT 0,         -- 是否为靶向治疗
    免疫治疗 NUMBER(1,0) DEFAULT 0,             -- 是否为免疫治疗
    内分泌治疗 NUMBER(1,0) DEFAULT 0,           -- 是否为内分泌治疗
    其他治疗 NUMBER(1,0) DEFAULT 0,             -- 是否为其他治疗
    PRIMARY KEY (ZHUYUANHAO)                    -- 主键约束
);

-- 为提高查询性能，创建索引
CREATE INDEX idx_zhuyuanhao ON zy_wpypmx(ZHUYUANHAO);
CREATE INDEX idx_bingrenxm ON zy_wpypmx(BINGRENXM);
CREATE INDEX idx_fashengrq ON zy_wpypmx(FASHENGRQ);

-- ============================================================================
-- 第二步：插入示例测试数据
-- ============================================================================

-- 患者001：张三 - 进行化疗和免疫治疗
INSERT INTO zy_wpypmx VALUES (
    '001',                             -- 住院号
    '张三',                            -- 患者名称
    '顺铂注射液',                      -- 医嘱名称
    '10ml*0.5mg',                      -- 规格
    2,                                 -- 数量
    0,                                 -- 结算类别（外配）
    '普通费用',                        -- 费用方式
    TO_DATE('2026-04-15','YYYY-MM-DD'),-- 发生日期
    1,                                 -- 化学治疗=是
    0,                                 -- 靶向治疗=否
    1,                                 -- 免疫治疗=是
    0,                                 -- 内分泌治疗=否
    0                                  -- 其他治疗=否
);

-- 患者001：用药2 - 免疫药
INSERT INTO zy_wpypmx VALUES (
    '001',
    '张三',
    '纳武利尤单抗',
    '100mg/10ml',
    1,
    0,
    '普通费用',
    TO_DATE('2026-04-18','YYYY-MM-DD'),
    0,                                 -- 化学治疗=否
    0,                                 -- 靶向治疗=否
    1,                                 -- 免疫治疗=是
    0,
    0
);

-- 患者002：李四 - 靶向治疗
INSERT INTO zy_wpypmx VALUES (
    '002',
    '李四',
    '吉非替尼',
    '250mg*14粒',
    1,
    NULL,                              -- 自费
    '自费费用',
    TO_DATE('2026-04-10','YYYY-MM-DD'),
    0,                                 -- 化学治疗=否
    1,                                 -- 靶向治疗=是
    0,
    0,
    0
);

-- 患者002：用药2 - 化疗
INSERT INTO zy_wpypmx VALUES (
    '002',
    '李四',
    '长春瑞滨注射液',
    '10ml*5mg',
    2,
    0,
    '普通费用',
    TO_DATE('2026-04-12','YYYY-MM-DD'),
    1,                                 -- 化学治疗=是
    0,
    0,
    0,
    0
);

-- 患者003：王女士 - 内分泌治疗
INSERT INTO zy_wpypmx VALUES (
    '003',
    '王女士',
    '他莫昔芬',
    '20mg*15粒',
    1,
    0,
    '普通费用',
    TO_DATE('2026-04-14','YYYY-MM-DD'),
    0,                                 -- 化学治疗=否
    0,                                 -- 靶向治疗=否
    0,                                 -- 免疫治疗=否
    1,                                 -- 内分泌治疗=是
    0                                  -- 其他治疗=否
);

-- 患者003：用药2 - 辅助用药
INSERT INTO zy_wpypmx VALUES (
    '003',
    '王女士',
    '双磷酸盐',
    '4mg/5ml',
    1,
    0,
    '普通费用',
    TO_DATE('2026-04-16','YYYY-MM-DD'),
    0,
    0,
    0,
    0,
    1                                  -- 其他治疗=是
);

-- 患者004：赵先生 - 多线治疗
INSERT INTO zy_wpypmx VALUES (
    '004',
    '赵先生',
    '多西他赛',
    '20ml*80mg',
    1,
    0,
    '普通费用',
    TO_DATE('2026-04-11','YYYY-MM-DD'),
    1,                                 -- 化学治疗=是
    0,
    0,
    0,
    0
);

-- 患者004：用药2 - 靶向治疗
INSERT INTO zy_wpypmx VALUES (
    '004',
    '赵先生',
    '厄洛替尼',
    '150mg*15粒',
    1,
    NULL,                              -- 自费
    '自费费用',
    TO_DATE('2026-04-13','YYYY-MM-DD'),
    0,
    1,                                 -- 靶向治疗=是
    0,
    0,
    0
);

-- 患者004：用药3 - 免疫治疗
INSERT INTO zy_wpypmx VALUES (
    '004',
    '赵先生',
    '帕博利珠单抗',
    '100mg/4ml',
    2,
    0,
    '普通费用',
    TO_DATE('2026-04-17','YYYY-MM-DD'),
    0,
    0,
    1,                                 -- 免疫治疗=是
    0,
    0
);

-- 提交事务
COMMIT;

-- ============================================================================
-- 第三步：验证数据
-- ============================================================================

-- 查看所有患者及其治疗类型
SELECT 
    ZHUYUANHAO AS 住院号,
    BINGRENXM AS 患者名称,
    化学治疗,
    分子靶向治疗,
    免疫治疗,
    内分泌治疗,
    其他治疗
FROM zy_wpypmx
GROUP BY ZHUYUANHAO, BINGRENXM, 化学治疗, 分子靶向治疗, 免疫治疗, 内分泌治疗, 其他治疗
ORDER BY ZHUYUANHAO;

-- 统计药物数量
SELECT COUNT(*) AS 总用药记录数 FROM zy_wpypmx;

-- 统计各患者的用药数
SELECT 
    ZHUYUANHAO AS 住院号,
    BINGRENXM AS 患者名称,
    COUNT(*) AS 用药数
FROM zy_wpypmx
GROUP BY ZHUYUANHAO, BINGRENXM
ORDER BY 住院号;

-- ============================================================================
-- 四步：系统测试查询（用于验证系统）
-- ============================================================================

-- 测试查询1：获取患者001的完整信息
SELECT BINGRENXM,
       SUM(化学治疗) AS 化学治疗,
       SUM(分子靶向治疗) AS 分子靶向治疗,
       SUM(免疫治疗) AS 免疫治疗,
       SUM(内分泌治疗) AS 内分泌治疗,
       SUM(其他治疗) AS 其他治疗
FROM zy_wpypmx
WHERE ZHUYUANHAO = '001'
GROUP BY ZHUYUANHAO, BINGRENXM;

-- 测试查询2：获取患者001的医嘱详情
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
        ELSE '医保'
    END AS ISWP
FROM zy_wpypmx
WHERE ZHUYUANHAO = '001'
ORDER BY FASHENGRQ DESC;

-- ============================================================================
-- 五步：权限配置（如果使用非Administrator用户）
-- ============================================================================

-- 为用户JCJK授予必要权限（如需要）
-- GRANT SELECT ON zy_wpypmx TO JCJK;
-- GRANT SELECT ON user_tables TO JCJK;

-- ============================================================================
-- 脚本结束
-- ============================================================================
-- 说明：
-- 该脚本创建了示例表和数据，用于测试肿瘤信息卡片系统
-- 生产环境中，应根据实际情况修改：
--   1. 表名和字段名
--   2. 数据类型和大小
--   3. 索引策略
--   4. 备份和恢复策略
