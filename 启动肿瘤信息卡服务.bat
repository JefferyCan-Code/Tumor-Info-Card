@echo off
title TumorWeb Server
cd /d "C:\Users\ruijie"
call medical_env\Scripts\activate
timeout /t 5 >nul
cd /d "D:\web_for_tumor"
timeout /t 5 >nul

:: 用 cmd /k 启动 Python，这样即使异常窗口也保留
cmd /k "python server.py || echo. && echo 服务器已退出/报错，窗口保留... && pause"