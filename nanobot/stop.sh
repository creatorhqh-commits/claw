#!/bin/bash

echo "========================================"
echo "  停止 nanobot 服务"
echo "========================================"
echo

# 停止 Gateway 端口
echo "停止 Gateway (端口 8765, 18790)..."
for pid in $(lsof -ti :8765 2>/dev/null) $(lsof -ti :18790 2>/dev/null); do
    kill -9 "$pid" 2>/dev/null
done

# 停止 WebUI 端口
echo "停止 WebUI (端口 5173)..."
for pid in $(lsof -ti :5173 2>/dev/null); do
    kill -9 "$pid" 2>/dev/null
done

# Windows 专用：通过 netstat 查找并杀掉进程
if command -v netstat &>/dev/null; then
    for port in 8765 18790 5173; do
        netstat -ano 2>/dev/null | grep ":$port " | grep LISTENING | awk '{print $5}' | while read pid; do
            taskkill //F //PID "$pid" 2>/dev/null
        done
    done
fi

echo
echo "服务已停止。"
