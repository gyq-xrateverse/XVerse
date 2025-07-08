#!/bin/bash

# Flash-Attention 快速安装脚本
# 只尝试最稳定的预编译版本

echo "🚀 Flash-Attention 快速安装"
echo "=========================="

# 检查是否已安装
echo "检查Flash-Attention安装状态..."
if python -c "import flash_attn; print(f'✅ 已安装 v{flash_attn.__version__}')" 2>/dev/null; then
    echo "Flash-Attention已安装，无需重复安装"
    exit 0
fi

echo "开始安装Flash-Attention..."

# 清理缓存
echo "清理pip缓存..."
pip cache purge

# 方法1: VLLM优化版本（推荐）
echo "尝试安装vllm-flash-attn (推荐版本)..."
if pip install --no-cache-dir vllm-flash-attn==2.6.2; then
    echo "✅ vllm-flash-attn安装成功"
    if python -c "import flash_attn; print('测试通过')" 2>/dev/null; then
        echo "🎉 Flash-Attention安装完成并测试通过!"
        exit 0
    fi
fi

# 方法2: 官方预编译版本
echo "尝试安装官方预编译版本..."
if pip install --no-cache-dir flash-attn==2.6.3 --find-links https://download.pytorch.org/whl/torch_stable.html; then
    echo "✅ 官方版本安装成功"
    if python -c "import flash_attn; print('测试通过')" 2>/dev/null; then
        echo "🎉 Flash-Attention安装完成并测试通过!"
        exit 0
    fi
fi

# 方法3: 最新稳定版本
echo "尝试安装最新稳定版本..."
if pip install --no-cache-dir flash-attn==2.7.4.post1; then
    echo "✅ 最新版本安装成功"
    if python -c "import flash_attn; print('测试通过')" 2>/dev/null; then
        echo "🎉 Flash-Attention安装完成并测试通过!"
        exit 0
    fi
fi

echo "❌ 所有预编译版本安装失败"
echo "建议:"
echo "1. 使用完整安装脚本: bash scripts/install_flash_attn.sh"
echo "2. 项目可以在没有flash-attn的情况下运行（使用PyTorch原生attention）"
exit 1 