#!/bin/bash

# Flash-Attention 快速安装脚本
# 尝试最稳定的预编译版本

echo "🚀 Flash-Attention 快速安装"
echo "=========================="

# 检查是否已安装
if python -c "import flash_attn; print(f'✅ 已安装 v{flash_attn.__version__}')" 2>/dev/null; then
    echo "Flash-Attention已安装，无需重复安装"
    exit 0
fi

echo "开始安装Flash-Attention..."

# 清理缓存
echo "清理pip缓存..."
pip cache purge

# 安装方法按优先级排序
install_methods=(
    "vllm-flash-attn==2.6.2|VLLM优化版 (推荐)"
    "flash-attn==2.6.3 --find-links https://download.pytorch.org/whl/torch_stable.html|官方预编译版"
    "flash-attn==2.7.4.post1|最新稳定版"
)

for method in "${install_methods[@]}"; do
    package="${method%|*}"
    name="${method#*|}"
    
    echo "尝试安装: $name"
    if pip install --no-cache-dir $package; then
        echo "✅ $name 安装成功"
        if python -c "import flash_attn; print('🎉 Flash-Attention安装完成并测试通过!')" 2>/dev/null; then
            exit 0
        fi
    fi
    echo "❌ $name 安装失败，尝试下一个方法..."
done

echo "❌ 所有预编译版本安装失败"
echo ""
echo "💡 建议:"
echo "1. 检查CUDA版本: nvcc --version"
echo "2. 检查磁盘空间: df -h"
echo "3. 项目可以在没有flash-attn的情况下正常运行（使用PyTorch原生attention）"
exit 1 