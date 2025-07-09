#!/bin/bash

# Flash-Attention 快速安装脚本
set -e

echo "🚀 Flash-Attention 快速安装脚本"
echo "======================================"

# 检查Python和PyTorch环境
echo "📋 检查环境..."
python --version
echo "PyTorch版本: $(python -c 'import torch; print(torch.__version__)')"
echo "CUDA可用: $(python -c 'import torch; print(torch.cuda.is_available())')"
echo ""

# 清理缓存
echo "🧹 清理pip缓存..."
pip cache purge
echo ""

# 配置清华源
echo "⚙️  配置清华源..."
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
pip config set global.trusted-host pypi.tuna.tsinghua.edu.cn
echo "清华源配置完成"
echo ""

# 尝试安装Flash-Attention (按优先级顺序)
echo "⚡ 开始安装 Flash-Attention..."

# 方法1: VLLM优化版 (最推荐)
echo "尝试方法1: VLLM优化版 (清华源)..."
if pip install --no-cache-dir vllm-flash-attn==2.6.2 -i https://pypi.tuna.tsinghua.edu.cn/simple; then
    echo "✅ 方法1成功: VLLM优化版安装完成"
    INSTALL_SUCCESS=true
else
    echo "❌ 方法1失败"
    INSTALL_SUCCESS=false
fi

# 方法2: 官方预编译版
if [ "$INSTALL_SUCCESS" = false ]; then
    echo ""
    echo "尝试方法2: 官方预编译版 (清华源)..."
    if pip install --no-cache-dir flash-attn==2.6.3 -i https://pypi.tuna.tsinghua.edu.cn/simple; then
        echo "✅ 方法2成功: 官方预编译版安装完成"
        INSTALL_SUCCESS=true
    else
        echo "❌ 方法2失败"
    fi
fi

# 方法3: 最新稳定版
if [ "$INSTALL_SUCCESS" = false ]; then
    echo ""
    echo "尝试方法3: 最新稳定版 (清华源)..."
    if pip install --no-cache-dir flash-attn==2.7.4.post1 -i https://pypi.tuna.tsinghua.edu.cn/simple; then
        echo "✅ 方法3成功: 最新稳定版安装完成"
        INSTALL_SUCCESS=true
    else
        echo "❌ 方法3失败"
    fi
fi

# 方法4: 备用官方源
if [ "$INSTALL_SUCCESS" = false ]; then
    echo ""
    echo "尝试方法4: 备用官方源..."
    pip config unset global.index-url
    pip config unset global.trusted-host
    if pip install --no-cache-dir flash-attn==2.6.3 --find-links https://download.pytorch.org/whl/torch_stable.html; then
        echo "✅ 方法4成功: 备用官方源安装完成"
        INSTALL_SUCCESS=true
    else
        echo "❌ 方法4失败"
    fi
fi

# 验证安装
echo ""
echo "🔍 验证安装..."
if [ "$INSTALL_SUCCESS" = true ]; then
    if python -c "import flash_attn; print(f'✅ Flash-Attention版本: {flash_attn.__version__}')"; then
        echo "🎉 Flash-Attention 安装成功并验证通过！"
        echo ""
        echo "📝 下一步："
        echo "启动XVerse应用: python run_gradio.py"
    else
        echo "⚠️  Flash-Attention安装完成但导入验证失败"
        echo "项目仍可正常运行，会使用PyTorch原生attention"
    fi
else
    echo "❌ 所有安装方法都失败了"
    echo ""
    echo "💡 不用担心！项目可以在没有Flash-Attention的情况下正常运行"
    echo "会自动回退到PyTorch原生attention，只是性能稍慢"
    echo ""
    echo "🔧 故障排除："
    echo "1. 检查CUDA版本兼容性: nvcc --version"
    echo "2. 检查GPU驱动: nvidia-smi"
    echo "3. 升级pip: pip install --upgrade pip"
fi

echo ""
echo "======================================"
echo "🚀 安装脚本执行完成" 