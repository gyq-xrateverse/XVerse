#!/bin/bash

# XVerse 容器启动脚本
set -e

echo "=== XVerse 容器启动 ==="

# 检查GPU是否可用
if command -v nvidia-smi &> /dev/null; then
    echo "GPU 状态："
    nvidia-smi --query-gpu=name,memory.total,memory.used --format=csv,noheader,nounits
else
    echo "⚠️  警告：未检测到 NVIDIA GPU"
fi

# 检查模型文件是否存在
echo "检查模型文件..."
MODELS_MISSING=false

# 检查必需的模型文件
if [ ! -f "/app/checkpoints/sam2.1_hiera_large.pt" ]; then
    echo "❌ SAM 2.1 模型缺失"
    MODELS_MISSING=true
fi

if [ ! -d "/app/checkpoints/FLUX.1-dev" ]; then
    echo "❌ FLUX.1-dev 模型缺失"
    MODELS_MISSING=true
fi

if [ ! -d "/app/checkpoints/Florence-2-large" ]; then
    echo "❌ Florence-2-large 模型缺失"
    MODELS_MISSING=true
fi

if [ ! -d "/app/checkpoints/clip-vit-large-patch14" ]; then
    echo "❌ CLIP 模型缺失"
    MODELS_MISSING=true
fi

if [ ! -d "/app/checkpoints/dino-vits16" ]; then
    echo "❌ DINO 模型缺失"
    MODELS_MISSING=true
fi

if [ ! -d "/app/checkpoints/mplug_visual-question-answering_coco_large_en" ]; then
    echo "❌ DPG VQA 模型缺失"
    MODELS_MISSING=true
fi

if [ ! -d "/app/checkpoints/XVerse" ]; then
    echo "❌ XVerse 主模型缺失"
    MODELS_MISSING=true
fi

if [ ! -f "/app/checkpoints/model_ir_se50.pth" ]; then
    echo "⚠️  Face ID 模型缺失（可选）"
fi

# 如果模型缺失，提供下载选项
if [ "$MODELS_MISSING" = true ]; then
    echo ""
    echo "检测到模型文件缺失。"
    echo "选项 1: 运行模型下载脚本"
    echo "选项 2: 挂载已有模型目录到 /app/checkpoints"
    echo ""
    
    echo "运行模型检查脚本..."
    /app/download_models.sh
    echo ""
    echo "请确保所有必需的模型文件都已放置在 /app/checkpoints 目录中"
    echo "或者将本地模型目录挂载到容器的 /app/checkpoints"
    echo ""
    echo "继续启动应用..."
fi

# 设置环境变量
export FLORENCE2_MODEL_PATH="/app/checkpoints/Florence-2-large"
export SAM2_MODEL_PATH="/app/checkpoints/sam2.1_hiera_large.pt"
export FACE_ID_MODEL_PATH="/app/checkpoints/model_ir_se50.pth"
export CLIP_MODEL_PATH="/app/checkpoints/clip-vit-large-patch14"
export FLUX_MODEL_PATH="/app/checkpoints/FLUX.1-dev"
export DPG_VQA_MODEL_PATH="/app/checkpoints/mplug_visual-question-answering_coco_large_en"
export DINO_MODEL_PATH="/app/checkpoints/dino-vits16"

echo "环境变量已设置："
echo "FLORENCE2_MODEL_PATH=$FLORENCE2_MODEL_PATH"
echo "SAM2_MODEL_PATH=$SAM2_MODEL_PATH"
echo "FACE_ID_MODEL_PATH=$FACE_ID_MODEL_PATH"
echo "CLIP_MODEL_PATH=$CLIP_MODEL_PATH"
echo "FLUX_MODEL_PATH=$FLUX_MODEL_PATH"
echo "DPG_VQA_MODEL_PATH=$DPG_VQA_MODEL_PATH"
echo "DINO_MODEL_PATH=$DINO_MODEL_PATH"

# 切换到应用目录
cd /app

# 启动应用
echo "启动 XVerse Gradio 应用..."
echo "访问地址: http://localhost:7860"
echo ""

# 根据启动模式选择不同的启动方式
if [ "${START_MODE:-gradio}" = "gradio" ]; then
    echo "启动 Gradio 演示..."
    python run_gradio.py
elif [ "${START_MODE}" = "bash" ]; then
    echo "启动 bash shell..."
    exec /bin/bash
else
    echo "启动 Gradio 演示（默认）..."
    python run_gradio.py
fi