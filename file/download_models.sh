#!/bin/bash

# XVerse 模型检查脚本（不执行下载）
set -e

echo "=== XVerse 模型检查脚本 ==="

# 创建checkpoints目录
mkdir -p /app/checkpoints
cd /app/checkpoints

echo "检查模型文件状态..."

# 检查各个模型文件
echo ""
echo "📋 模型文件检查结果："
echo "================================"

# SAM 2.1模型
if [ -f "sam2.1_hiera_large.pt" ]; then
    echo "✓ SAM 2.1 模型: 已存在"
else
    echo "❌ SAM 2.1 模型: 缺失"
    echo "   下载地址: https://dl.fbaipublicfiles.com/segment_anything_2/092824/sam2.1_hiera_large.pt"
fi

# FLUX.1-dev
if [ -d "FLUX.1-dev" ]; then
    echo "✓ FLUX.1-dev 模型: 已存在"
else
    echo "❌ FLUX.1-dev 模型: 缺失"
    echo "   下载命令: huggingface-cli download black-forest-labs/FLUX.1-dev --local-dir ./FLUX.1-dev"
fi

# Florence-2-large
if [ -d "Florence-2-large" ]; then
    echo "✓ Florence-2-large 模型: 已存在"
else
    echo "❌ Florence-2-large 模型: 缺失"
    echo "   下载命令: huggingface-cli download microsoft/Florence-2-large --local-dir ./Florence-2-large"
fi

# CLIP模型
if [ -d "clip-vit-large-patch14" ]; then
    echo "✓ CLIP 模型: 已存在"
else
    echo "❌ CLIP 模型: 缺失"
    echo "   下载命令: huggingface-cli download openai/clip-vit-large-patch14 --local-dir ./clip-vit-large-patch14"
fi

# DINO模型
if [ -d "dino-vits16" ]; then
    echo "✓ DINO 模型: 已存在"
else
    echo "❌ DINO 模型: 缺失"
    echo "   下载命令: huggingface-cli download facebook/dino-vits16 --local-dir ./dino-vits16"
fi

# DPG VQA模型
if [ -d "mplug_visual-question-answering_coco_large_en" ]; then
    echo "✓ DPG VQA 模型: 已存在"
else
    echo "❌ DPG VQA 模型: 缺失"
    echo "   下载命令: huggingface-cli download xingjianleng/mplug_visual-question-answering_coco_large_en --local-dir ./mplug_visual-question-answering_coco_large_en"
fi

# XVerse主模型
if [ -d "XVerse" ]; then
    echo "✓ XVerse 主模型: 已存在"
else
    echo "❌ XVerse 主模型: 缺失"
    echo "   下载命令: huggingface-cli download ByteDance/XVerse --local-dir ./XVerse"
fi

# Face ID模型
if [ -f "model_ir_se50.pth" ]; then
    echo "✓ Face ID 模型: 已存在"
else
    echo "❌ Face ID 模型: 缺失"
    echo "   下载地址: https://github.com/TreB1eN/InsightFace_Pytorch/releases/download/v1.0/model_ir_se50.pth"
fi

echo "================================"
echo ""
echo "📝 说明："
echo "- 请手动下载缺失的模型文件到 /app/checkpoints 目录"
echo "- 或者将本地模型目录挂载到容器的 /app/checkpoints"
echo "- 模型文件总大小约 25GB"
echo ""
echo "🔗 原始下载脚本位置: XVerse/checkpoints/download_ckpts.sh"

echo "=== 模型检查完成 ===" 