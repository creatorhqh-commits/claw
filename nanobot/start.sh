#!/bin/bash

CONDA_ENV="C:/Users/Huangqh/.conda/envs/nanobot"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================"
echo "  nanobot 快速启动"
echo "========================================"
echo

# 启动 Gateway
echo "[1/2] 启动 Gateway (端口 18790)..."
cd "$PROJECT_DIR"
"$CONDA_ENV/python.exe" -m nanobot.cli.commands gateway &
GATEWAY_PID=$!
sleep 3

# 启动 WebUI
echo "[2/2] 启动 WebUI (端口 5173)..."
cd "$PROJECT_DIR/webui"
npm run dev &
WEBUI_PID=$!
sleep 3

echo
echo "========================================"
echo "  服务已启动！"
echo "  Gateway: ws://127.0.0.1:8765/"
echo "  WebUI:   http://127.0.0.1:5173/"
echo "  Gateway PID: $GATEWAY_PID"
echo "  WebUI PID:   $WEBUI_PID"
echo "========================================"
echo
echo "按 Ctrl+C 停止所有服务"

# 捕获退出信号，停止所有子进程
trap "kill $GATEWAY_PID $WEBUI_PID 2>/dev/null; exit" INT TERM

# 等待子进程
wait
